"""
Knowledge Agent - RAG search từ vector store
"""
from typing import Dict, Any, List, Optional
import asyncio
import logging
import hashlib
from app.agents.base_agent import BaseAgent
from app.api.deps import get_image_vector_store, get_image_embedding_service, get_embedding_service
from app.infrastructure.vector_store.image_vector_store import ImageVectorStore
from app.services.image import ImageEmbeddingService
from app.services.embedding import EmbeddingService
from app.core.settings import Settings

logger = logging.getLogger(__name__)


class KnowledgeAgent(BaseAgent):
    """
    Knowledge Agent thực hiện RAG search:
    """
    
    def __init__(
        self,
        vector_store: Optional[ImageVectorStore] = None,
        image_embedding_service: Optional[ImageEmbeddingService] = None,
        text_embedding_service: Optional[EmbeddingService] = None
    ):
        super().__init__("KnowledgeAgent")
        self.vector_store = vector_store
        self.image_embedding_service = image_embedding_service
        self.text_embedding_service = text_embedding_service
        
        # 🔥 PERFORMANCE: Simple in-memory cache for search results
        self._search_cache = {} if Settings.ENABLE_AGENT_CACHE else None
        self._cache_max_size = Settings.AGENT_CACHE_SIZE if Settings.ENABLE_AGENT_CACHE else 0
    
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Thực hiện RAG search dựa trên query type
        """
        query_type = state.get("query_type", "text")
        query = state.get("query", "").strip()
        user_description = state.get("user_description", "")
        image_data = state.get("image_data")
        category_id = state.get("category_id")
        top_k = state.get("top_k", 5)
        
        # Lazy load services if not provided
        if not self.vector_store:
            self.vector_store = get_image_vector_store()
        if not self.image_embedding_service:
            self.image_embedding_service = get_image_embedding_service()
        if not self.text_embedding_service:
            self.text_embedding_service = get_embedding_service()
        
        knowledge_results = []
        knowledge_context = ""
        
        try:
            if query_type == "image" or query_type == "hybrid":
                # Image search
                if image_data:
                    self.log("🔍 Performing image search...")
                    image_results = await self._search_by_image(
                        image_data=image_data,
                        category_id=category_id,
                        top_k=top_k
                    )
                    knowledge_results.extend(image_results)
            
            if query_type == "text" or query_type == "hybrid":
                # Text search
                search_text = query or user_description
                if search_text:
                    # Normalize query - loại bỏ từ khóa không liên quan đến product
                    normalized_query = self._normalize_product_query_for_search(search_text)
                    
                    #  PERFORMANCE: Check cache first
                    cache_key = self._get_cache_key(normalized_query, category_id, top_k)
                    if self._search_cache is not None and cache_key in self._search_cache:
                        self.log(f"⚡ Cache hit for query: '{normalized_query}'")
                        cached_results = self._search_cache[cache_key]
                        knowledge_results.extend(cached_results)
                    else:
                        self.log(f"🔍 Performing text search: '{normalized_query}' (original: '{search_text}')...")
                        
                        # Progressive fallback strategy
                        # Priority: SQL exact > SQL fuzzy > Vector search
                        sql_exact_results = await self._search_by_sql_exact_match(normalized_query, category_id, top_k)
                        text_results = []  # Initialize to avoid undefined error
                        
                        if sql_exact_results:
                            self.log(f"✅ SQL exact match found: {len(sql_exact_results)} products. Using SQL results.")
                            knowledge_results.extend(sql_exact_results)
                        else:
                            # Try fuzzy SQL search
                            self.log(f"⚠️ SQL exact match found 0 results. Trying fuzzy SQL search...")
                            sql_fuzzy_results = await self._search_by_sql_fuzzy_match(normalized_query, category_id, top_k)
                            
                            if sql_fuzzy_results:
                                self.log(f"✅ SQL fuzzy match found: {len(sql_fuzzy_results)} products. Using fuzzy SQL results.")
                                knowledge_results.extend(sql_fuzzy_results)
                            else:
                                # Last resort: vector search
                                self.log(f"⚠️ SQL fuzzy match found 0 results. Falling back to vector search...")
                                text_results = await self._search_by_text(
                                    query=normalized_query,
                                    category_id=category_id,
                                    top_k=top_k
                                )
                                knowledge_results.extend(text_results)
                        
                        # 🔥 PERFORMANCE: Cache results
                        if self._search_cache is not None:
                            if len(self._search_cache) >= self._cache_max_size:
                                # Remove oldest entry (simple FIFO)
                                oldest_key = next(iter(self._search_cache))
                                del self._search_cache[oldest_key]
                            self._search_cache[cache_key] = knowledge_results.copy()

                    
                    #  Fallback retry nếu không tìm được (chỉ khi không có SQL results)
                    if not sql_exact_results and not text_results and search_text:
                        extracted_product = self._extract_product_name_from_query(search_text)
                        if extracted_product and extracted_product != normalized_query:
                            self.log(f"🔍 Retrying search with extracted product name: '{extracted_product}'...")
                            retry_results = await self._search_by_text(
                                query=extracted_product,
                                category_id=category_id,
                                top_k=top_k
                            )
                            knowledge_results.extend(retry_results)
                            if retry_results:
                                self.log(f"✅ Found {len(retry_results)} results with extracted product name")
            
            # Merge và deduplicate results
            knowledge_results = self._merge_results(knowledge_results)
            
            # ⚡ FILTER: Chỉ giữ lại results có similarity >= 0.5 (50%)
            # Tránh trả về sản phẩm không liên quan (ví dụ: "cá hồi" → "thịt bò")
            # Threshold 50% đảm bảo chỉ trả về sản phẩm thực sự liên quan
            SIMILARITY_THRESHOLD = 0.5
            similarity_filtered = [
                r for r in knowledge_results 
                if r.get("similarity", 0) >= SIMILARITY_THRESHOLD
            ]
            
            if len(similarity_filtered) < len(knowledge_results):
                self.log(f"⚠️ Filtered {len(knowledge_results) - len(similarity_filtered)} results with similarity < {SIMILARITY_THRESHOLD:.0%}")
            
            #  Lexical filter chỉ để rerank, không phải gate
            # Lưu original vector results để fallback nếu lexical filter loại hết
            original_vector_results = similarity_filtered.copy()
            filtered_results = similarity_filtered
            
            # Kiểm tra keyword matching nếu có query text (dùng fuzzy match)
            # Nếu user hỏi "cá hồi" nhưng result là "thịt bò" → loại bỏ
            if query and filtered_results:
                query_lower = query.lower()
                # Extract keywords từ query (loại bỏ stopwords)
                import re
                from difflib import SequenceMatcher
                
                stopwords = {"hình", "ảnh", "hình ảnh", "lấy", "ra", "và", "của", "nó", "theo", "tháng", "doanh", "thu", "số"}
                query_keywords = [w for w in re.sub(r'[^a-zà-ỹ\s]', ' ', query_lower).split() 
                                 if w and w not in stopwords and len(w) > 2]
                
                if query_keywords:
                    # Whole-word matching + synonym + fuzzy match
                    truly_matched = []
                    for result in filtered_results:
                        product_name = result.get("product_name", "").lower()
                        
                        # Synonym map
                        synonym_map = {
                            "cá hồi": ["cá hồi", "salmon", "cá hồi na uy", "cá hồi tươi"],
                            "thịt bò": ["thịt bò", "beef", "thịt bò tươi"],
                            "thịt heo": ["thịt heo", "pork", "thịt lợn"],
                            "gà": ["gà", "chicken", "gà ta"],
                            "tôm": ["tôm", "shrimp", "tôm sú"],
                        }
                        
                        # Kiểm tra match với từng keyword
                        matched = False
                        for keyword in query_keywords:
                            keyword_lower = keyword.lower()
                            
                            # 1. Whole-word exact match (quan trọng nhất)
                            import re
                            # Match whole word, không match substring
                            word_pattern = r'\b' + re.escape(keyword_lower) + r'\b'
                            if re.search(word_pattern, product_name):
                                matched = True
                                break
                            
                            # 2. Synonym match
                            for main_term, synonyms in synonym_map.items():
                                if keyword_lower in main_term or main_term in keyword_lower:
                                    # Check nếu product_name chứa bất kỳ synonym nào
                                    if any(re.search(r'\b' + re.escape(syn) + r'\b', product_name) for syn in synonyms):
                                        matched = True
                                        break
                                if matched:
                                    break
                            
                            if matched:
                                break
                            
                            # 3. Fuzzy match (cho phép typo nhỏ) - chỉ khi không có exact/synonym match
                            if not matched and len(keyword_lower) >= 3:
                                product_words = product_name.split()
                                for word in product_words:
                                    if len(word) >= 3:
                                        similarity_ratio = SequenceMatcher(None, keyword_lower, word).ratio()
                                        if similarity_ratio > 0.7:  # 70% similarity
                                            matched = True
                                            break
                                if matched:
                                    break
                        
                        if matched:
                            truly_matched.append(result)
                        else:
                            self.log(f"⚠️ Filtered out product '{result.get('product_name')}' - không khớp keywords: {query_keywords}")
                    
                    if truly_matched:
                        filtered_results = truly_matched
                    else:
                        #  Nếu lexical filter loại hết → KHÔNG fallback về vector results
                        # Lý do: Nếu vector search trả về sai entity (ví dụ: "Thịt bò" khi hỏi "cá hồi")
                        # thì không nên fallback về đó, mà nên return empty để hard guard xử lý
                        self.log(f"⚠️ Lexical filter removed all results. NOT falling back to vector results to avoid wrong entity.")
                        self.log(f"⚠️ This will trigger hard guard in Orchestrator to ask user for clarification.")
                        filtered_results = []  # Return empty để hard guard xử lý
            
            knowledge_results = filtered_results
            
            # Format context
            knowledge_context = self._format_context(knowledge_results)
            
            self.log(f"✅ Found {len(knowledge_results)} knowledge results (after filtering)")
            
        except Exception as e:
            self.log(f"❌ Error in knowledge search: {str(e)}", level="error")
            knowledge_results = []
            knowledge_context = ""
        
        # Cập nhật state
        state.update({
            "knowledge_results": knowledge_results,
            "knowledge_context": knowledge_context
        })
        
        return state
    
    async def _search_by_image(
        self,
        image_data: bytes,
        category_id: Optional[str] = None,
        top_k: int = 5
    ) -> List[Dict[str, Any]]:
        """Search products by image"""
        try:
            # Tạo image embedding
            query_embedding = await self.image_embedding_service.create_embedding(image_data)
            
            if query_embedding is None:
                return []
            
            # Build where clause
            where_clause = {"content_type": "product"}
            if category_id:
                where_clause["category_id"] = category_id
            
            # Vector search
            results = await asyncio.to_thread(
                self.vector_store.collection.query,
                query_embeddings=[query_embedding.tolist()],
                n_results=top_k,
                where=where_clause
            )
            
            # Parse results
            products = []
            if results.get('ids') and len(results['ids'][0]) > 0:
                for i in range(len(results['ids'][0])):
                    metadata = results['metadatas'][0][i]
                    distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                    similarity = 1 - distance
                    
                    product = {
                        "product_id": metadata.get('file_id', '') or metadata.get('product_id', ''),
                        "product_name": metadata.get('product_name', ''),
                        "category_id": metadata.get('category_id', ''),
                        "category_name": metadata.get('category_name', ''),
                        "similarity": float(similarity),
                        "price": float(metadata.get('price', 0)) if metadata.get('price') else None,
                        "source": "image_search"
                    }
                    products.append(product)
            
            return products
            
        except Exception as e:
            self.log(f"Error in image search: {str(e)}", level="error")
            return []
    
    async def _search_by_text(
        self,
        query: str,
        category_id: Optional[str] = None,
        top_k: int = 5
    ) -> List[Dict[str, Any]]:
        """Search products by text"""
        try:
            # Tạo text embedding (dùng CLIP text encoder để tương thích với image embeddings)
            query_embedding = self.image_embedding_service.create_text_embedding(query)
            
            if query_embedding is None:
                return []
            
            # Build where clause
            where_clause = {"content_type": "product"}
            if category_id:
                where_clause["category_id"] = category_id
            
            # Vector search
            results = await asyncio.to_thread(
                self.vector_store.collection.query,
                query_embeddings=[query_embedding.tolist()],
                n_results=top_k,
                where=where_clause
            )
            
            # Parse results
            products = []
            if results.get('ids') and len(results['ids'][0]) > 0:
                for i in range(len(results['ids'][0])):
                    metadata = results['metadatas'][0][i]
                    distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                    similarity = 1 - distance
                    
                    product = {
                        "product_id": metadata.get('file_id', '') or metadata.get('product_id', ''),
                        "product_name": metadata.get('product_name', ''),
                        "category_id": metadata.get('category_id', ''),
                        "category_name": metadata.get('category_name', ''),
                        "similarity": float(similarity),
                        "price": float(metadata.get('price', 0)) if metadata.get('price') else None,
                        "source": "text_search"
                    }
                    products.append(product)
            
            return products
            
        except Exception as e:
            self.log(f"Error in text search: {str(e)}", level="error")
            return []
    
    def _merge_results(self, results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Merge và deduplicate results từ nhiều sources"""
        seen = {}
        merged = []
        
        for result in results:
            product_id = result.get("product_id")
            if not product_id:
                continue
            
            # Nếu đã có, chọn result có similarity cao hơn
            if product_id in seen:
                existing = seen[product_id]
                if result.get("similarity", 0) > existing.get("similarity", 0):
                    seen[product_id] = result
            else:
                seen[product_id] = result
        
        # Sort by similarity
        merged = sorted(seen.values(), key=lambda x: x.get("similarity", 0), reverse=True)
        
        return merged
    
    def _normalize_product_query_for_search(self, query: str) -> str:
        """
        Normalize query cho product search - loại bỏ từ khóa không liên quan
        Ví dụ: "hình ảnh cá hồi và doanh thu theo tháng" → "cá hồi"
        Mục tiêu: Chỉ giữ lại tên sản phẩm để vector embedding match tốt hơn
        """
        import re
        
        if not query:
            return query
        
        q = query.lower()
        
        # Loại bỏ từ khóa nhiễu (noise words) - ưu tiên loại bỏ cụm từ trước
        noise_phrases = [
            "hình ảnh", "ảnh", "image", "picture",
            "doanh thu", "doanh số", "thống kê", "theo tháng", 
            "bán chạy", "giá bao nhiêu", "revenue", "sales",
            "lấy ra", "lấy", "hiển thị", "show", "display"
        ]
        
        # Loại bỏ cụm từ trước (để tránh "hình ảnh" → "hình" + "ảnh" còn sót)
        for phrase in noise_phrases:
            q = q.replace(phrase, " ")
        
        # Loại bỏ từ đơn lẻ
        noise_words = [
            "và", "của", "nó", "cho", "từ", "đến", "trong", "ngoài",
            "ra", "về", "với", "năm", "tháng", "ngày"
        ]
        
        for word in noise_words:
            # Chỉ replace nếu là từ đơn lẻ (có space xung quanh hoặc đầu/cuối)
            q = re.sub(rf'\b{re.escape(word)}\b', ' ', q)
        
        # Clean up multiple spaces
        q = re.sub(r'\s+', ' ', q).strip()
        
        # Nếu normalized quá ngắn hoặc rỗng, dùng query gốc
        if len(q) < 2:
            q = query.strip()
        
        self.log(f"🔍 Normalized query: '{q}' (from '{query}')")
        return q
    
    def _extract_product_name_from_query(self, query: str) -> Optional[str]:
        """
        Extract product name từ query phức tạp.
        Ví dụ: "hình ảnh cá hồi và doanh thu theo tháng" → "cá hồi"
        """
        import re
        
        # Loại bỏ các từ không quan trọng (stopwords)
        stopwords = {
            "hình", "ảnh", "hình ảnh", "hinh", "anh",
            "lấy", "lay", "ra", "xem", "xem thử",
            "sản", "phẩm", "san", "pham", "sản phẩm",
            "của", "về", "với", "giúp", "mình", "tôi",
            "và", "cũng", "như", "là", "có", "không",
            "theo", "tháng", "doanh", "thu", "số", "thống", "kê",
            "nó", "cho", "từ", "đến", "trong", "ngoài", "năm"
        }
        
        # Normalize query
        query_lower = query.lower()
        query_clean = re.sub(r'[^\w\s]', ' ', query_lower)
        words = [w for w in query_clean.split() if w and w not in stopwords and len(w) > 2]
        
        # 🔥 CẢI THIỆN: Tìm cụm từ phổ biến cho tên sản phẩm thực phẩm
        # Ví dụ: "cá hồi", "thịt bò", "rau cải", "gà nướng"
        common_product_patterns = [
            r"cá\s+\w+",  # "cá hồi", "cá thu"
            r"thịt\s+\w+",  # "thịt bò", "thịt heo"
            r"rau\s+\w+",  # "rau cải", "rau muống"
            r"gà\s+\w+",  # "gà nướng", "gà rán"
            r"tôm\s+\w+",  # "tôm sú", "tôm hùm"
            r"khoai\s+\w+",  
            r"nước\s+\w+",  
            r"sữa\s+\w+",
        ]
        
        for pattern in common_product_patterns:
            match = re.search(pattern, query_lower)
            if match:
                extracted = match.group(0).strip()
                if len(extracted) >= 4:  # Đảm bảo đủ dài
                    self.log(f"✅ Extracted product name using pattern: '{extracted}'")
                    return extracted
        
        # Nếu không match pattern, thử cụm 2 từ liên tiếp
        if len(words) >= 2:
            # Thử cụm 2 từ trước (thường là tên sản phẩm)
            for i in range(len(words) - 1):
                phrase = f"{words[i]} {words[i+1]}"
                if len(phrase) >= 4:  # Đảm bảo đủ dài
                    self.log(f"✅ Extracted product name: '{phrase}'")
                    return phrase
        elif len(words) == 1:
            self.log(f"✅ Extracted product name (single word): '{words[0]}'")
            return words[0]
        
        # Nếu không extract được, trả về None
        self.log(f"⚠️ Could not extract product name from query: '{query[:50]}'")
        return None
    
    def _format_context(self, results: List[Dict[str, Any]]) -> str:
        """Format search results thành context string"""
        if not results:
            return ""
        
        context_parts = []
        for i, result in enumerate(results[:5], 1):  # Top 5 results
            product_name = result.get("product_name", "Unknown")
            category_name = result.get("category_name", "")
            price = result.get("price")
            similarity = result.get("similarity", 0)
            
            context = f"{i}. {product_name}"
            if category_name:
                context += f" (Danh mục: {category_name})"
            if price:
                context += f" - Giá: {price:,.0f} VND"
            context += f" (Độ tương đồng: {similarity:.2%})"
            
            context_parts.append(context)
        
        return "\n".join(context_parts)
    
    def _build_odbc_connection_with_fallback(self, connection_string: str) -> Optional[Any]:
        """
        Build ODBC connection với fallback driver logic (giống /api/products/search/chat)
        Thử nhiều driver khác nhau để tìm driver phù hợp
        """
        import pyodbc
        import re
        
        if not connection_string:
            return None
        
        # Build ODBC connection string nếu chưa có DRIVER
        conn_str = connection_string
        if "DRIVER=" not in conn_str.upper():
            params = {}
            parts = [p.strip() for p in conn_str.split(';') if p.strip()]
            for part in parts:
                if '=' in part:
                    key, value = part.split('=', 1)
                    params[key.strip().lower()] = value.strip()

            server = params.get('server', '')
            database = params.get('database', '')
            user_id = params.get('user id', params.get('uid', ''))
            password = params.get('password', params.get('pwd', ''))
            trust_cert = params.get('trustservercertificate', 'True').lower() == 'true'

            driver = "ODBC Driver 18 for SQL Server"
            odbc_conn_str = f"DRIVER={{{driver}}};SERVER={server};DATABASE={database};"
            if user_id:
                odbc_conn_str += f"UID={user_id};PWD={password};"
            if trust_cert:
                odbc_conn_str += "TrustServerCertificate=yes;"
            conn_str = odbc_conn_str

        # 🔥 FALLBACK: Thử nhiều driver khác nhau
        conn = None
        for driver_name in ["ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server Native Client 11.0"]:
            try:
                test_conn_str = conn_str
                if driver_name not in test_conn_str:
                    test_conn_str = re.sub(r'DRIVER=\{[^}]+\}', f'DRIVER={{{driver_name}}}', test_conn_str, count=1)
                conn = pyodbc.connect(test_conn_str, timeout=5)
                self.log(f"✅ Connected to DB using driver: {driver_name}")
                break
            except Exception as e:
                continue
        
        return conn
    
    async def _search_by_sql_exact_match(
        self,
        query: str,
        category_id: Optional[str] = None,
        top_k: int = 5
    ) -> List[Dict[str, Any]]:
        """
        SQL exact match TRƯỚC vector search
        Tìm sản phẩm bằng SQL LIKE để đảm bảo entity match chính xác
        """
        try:
            connection_string = Settings.DATABASE_CONNECTION_STRING
            if not connection_string:
                self.log("⚠️ DATABASE_CONNECTION_STRING not found. Skipping SQL exact match.")
                return []
            
            import asyncio
            
            # Sử dụng fallback driver logic
            # Test connection với fallback driver
            test_conn = self._build_odbc_connection_with_fallback(connection_string)
            if not test_conn:
                self.log("⚠️ Could not establish DB connection with any driver. Skipping SQL exact match.")
                return []
            test_conn.close()
            
            # Extract keywords từ query để search
            keywords = query.split()
            if not keywords:
                return []
            
            # Thử search với từng keyword, ưu tiên keyword dài nhất
            keywords_sorted = sorted(keywords, key=len, reverse=True)
            
            # 🔥 FIX: Chuyển thành sync function để dùng với asyncio.to_thread
            def search_in_db():
                """Sync function để chạy trong thread pool"""
                conn = None
                try:
                    # Sử dụng fallback driver logic
                    conn = self._build_odbc_connection_with_fallback(connection_string)
                    if not conn:
                        return []
                    cursor = conn.cursor()
                    
                    # Search với keyword đầu tiên (dài nhất)
                    keyword = keywords_sorted[0]
                    like_pattern = f"%{keyword}%"
                    
                    # 🔥 FIX: Thêm filter category_id nếu có
                    category_filter = ""
                    query_params = [like_pattern]
                    if category_id:
                        category_filter = " AND s.MaDanhMuc = ?"
                        query_params.append(category_id)
                    
                    db_query = f"""
                        SELECT TOP {top_k}
                            s.MaSanPham,
                            s.TenSanPham,
                            s.MoTa,
                            s.Anh,
                            s.GiaBan,
                            s.DonViTinh,
                            s.MaDanhMuc,
                            dm.TenDanhMuc
                        FROM SanPham s
                        LEFT JOIN DanhMuc dm ON s.MaDanhMuc = dm.MaDanhMuc
                        WHERE (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                          AND s.TenSanPham LIKE ?{category_filter}
                        ORDER BY
                            CASE WHEN s.TenSanPham LIKE ? THEN 0 ELSE 1 END,
                            s.TenSanPham
                    """
                    
                    query_params.append(like_pattern)  # For ORDER BY CASE
                    cursor.execute(db_query, *query_params)
                    rows = cursor.fetchall()
                    
                    products = []
                    for row in rows:
                        product_id, product_name, description, image_filename, price, don_vi_tinh, cat_id, cat_name = row
                        
                        # 🔥 BONUS: Guardrail chống nhầm sản phẩm với synonym + fuzzy match
                        product_name_lower = product_name.lower()
                        
                        # Synonym map cho các sản phẩm phổ biến
                        synonym_map = {
                            "cá hồi": ["cá hồi", "salmon", "cá hồi na uy", "cá hồi tươi"],
                            "thịt bò": ["thịt bò", "beef", "thịt bò tươi"],
                            "thịt heo": ["thịt heo", "pork", "thịt lợn"],
                            "gà": ["gà", "chicken", "gà ta", "gà công nghiệp"],
                            "tôm": ["tôm", "shrimp", "tôm sú", "tôm hùm"],
                        }
                        
                        # Kiểm tra match với synonym
                        matched = False
                        for keyword in keywords_sorted[:2]:
                            keyword_lower = keyword.lower()
                            
                            # Exact match
                            if keyword_lower in product_name_lower:
                                matched = True
                                break
                            
                            # Synonym match
                            for main_term, synonyms in synonym_map.items():
                                if keyword_lower in main_term or main_term in keyword_lower:
                                    if any(syn in product_name_lower for syn in synonyms):
                                        matched = True
                                        break
                                if matched:
                                    break
                            
                            if matched:
                                break
                            
                            # Fuzzy match (nếu không có exact/synonym match)
                            if not matched:
                                try:
                                    from difflib import SequenceMatcher
                                    product_words = product_name_lower.split()
                                    for word in product_words:
                                        if len(word) >= 3 and len(keyword_lower) >= 3:
                                            similarity = SequenceMatcher(None, keyword_lower, word).ratio()
                                            if similarity > 0.7:  # 70% similarity
                                                matched = True
                                                break
                                    if matched:
                                        break
                                except:
                                    pass
                        
                        if matched:
                            products.append({
                                "product_id": str(product_id),
                                "product_name": str(product_name),
                                "category_id": str(cat_id) if cat_id else "",
                                "category_name": str(cat_name) if cat_name else "",
                                "price": float(price) if price is not None else None,
                                "unit": str(don_vi_tinh) if don_vi_tinh else "",
                                "description": str(description) if description else "",
                                "similarity": 1.0,  # SQL exact match => max relevance
                                "source": "sql_exact_match"
                            })
                        else:
                            # Log warning nếu entity không match
                            self.log(f"⚠️ Entity mismatch: '{product_name}' does not match keywords {keywords_sorted[:2]}")
                    
                    cursor.close()
                    return products
                    
                except Exception as e:
                    self.log(f"Error in SQL exact match: {str(e)}", level="error")
                    return []
                finally:
                    if conn:
                        conn.close()
            
            # 🔥 FIX: Chạy sync function trong thread pool (pyodbc là blocking I/O)
            results = await asyncio.to_thread(search_in_db)
            return results
            
        except Exception as e:
            self.log(f"Error in SQL exact match: {str(e)}", level="error")
            return []
    
    async def _search_by_sql_fuzzy_match(
        self,
        query: str,
        category_id: Optional[str] = None,
        top_k: int = 5
    ) -> List[Dict[str, Any]]:
        """
        🔥 NEW: Fuzzy SQL search - fallback when exact match fails
        Uses partial matching, description search, and relevance scoring
        """
        try:
            connection_string = Settings.DATABASE_CONNECTION_STRING
            if not connection_string:
                self.log("⚠️ DATABASE_CONNECTION_STRING not found. Skipping fuzzy SQL search.")
                return []
            
            import asyncio
            
            # 🔥 FIX: Sử dụng fallback driver logic
            test_conn = self._build_odbc_connection_with_fallback(connection_string)
            if not test_conn:
                self.log("⚠️ Could not establish DB connection with any driver. Skipping fuzzy SQL search.")
                return []
            test_conn.close()
            
            # Extract keywords
            keywords = query.split()
            if not keywords:
                return []
            
            keywords_sorted = sorted(keywords, key=len, reverse=True)
            
            def search_in_db():
                """Fuzzy search with relevance scoring"""
                conn = None
                try:
                    # Sử dụng fallback driver logic
                    conn = self._build_odbc_connection_with_fallback(connection_string)
                    if not conn:
                        return []
                    cursor = conn.cursor()
                    
                    # Build search patterns
                    keyword = keywords_sorted[0]
                    exact_pattern = f"%{keyword}%"
                    
                    # Fuzzy patterns (remove last char for typo tolerance)
                    fuzzy_pattern = f"%{keyword[:-1]}%" if len(keyword) > 2 else exact_pattern
                    
                    # 🔥 FIX: Thêm filter category_id nếu có
                    category_filter = ""
                    query_params = []
                    if category_id:
                        category_filter = " AND s.MaDanhMuc = ?"
                        query_params.append(category_id)
                    
                    # Search in both name and description
                    db_query = f"""
                        SELECT TOP {top_k}
                            s.MaSanPham,
                            s.TenSanPham,
                            s.MoTa,
                            s.Anh,
                            s.GiaBan,
                            s.DonViTinh,
                            s.MaDanhMuc,
                            dm.TenDanhMuc,
                            -- Relevance score
                            CASE 
                                WHEN s.TenSanPham LIKE ? THEN 100
                                WHEN s.TenSanPham LIKE ? THEN 80
                                WHEN s.MoTa LIKE ? THEN 60
                                ELSE 40
                            END AS relevance_score
                        FROM SanPham s
                        LEFT JOIN DanhMuc dm ON s.MaDanhMuc = dm.MaDanhMuc
                        WHERE (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                          AND (
                              s.TenSanPham LIKE ?
                              OR s.TenSanPham LIKE ?
                              OR s.MoTa LIKE ?
                          ){category_filter}
                        ORDER BY relevance_score DESC, s.TenSanPham
                    """
                    
                    # Build query parameters: CASE scoring + WHERE clause + category filter
                    all_params = [
                        exact_pattern, fuzzy_pattern, exact_pattern,  # For CASE scoring
                        exact_pattern, fuzzy_pattern, exact_pattern   # For WHERE clause
                    ]
                    if category_id:
                        all_params.insert(-3, category_id)  # Insert before WHERE clause params
                    
                    cursor.execute(db_query, *all_params)
                    rows = cursor.fetchall()
                    
                    products = []
                    for row in rows:
                        product_id, product_name, description, image_filename, price, don_vi_tinh, cat_id, cat_name, relevance = row
                        
                        # Validate with synonym matching
                        product_name_lower = product_name.lower()
                        
                        synonym_map = {
                            "cá hồi": ["cá hồi", "salmon", "cá hồi na uy", "cá hồi tươi", "ca hoi"],
                            "thịt bò": ["thịt bò", "beef", "thịt bò tươi", "thit bo"],
                            "thịt heo": ["thịt heo", "pork", "thịt lợn", "thit heo"],
                            "gà": ["gà", "chicken", "gà ta", "ga"],
                            "tôm": ["tôm", "shrimp", "tôm sú", "tom"],
                        }
                        
                        # Check if product matches query intent
                        matched = False
                        for keyword in keywords_sorted[:2]:
                            keyword_lower = keyword.lower()
                            
                            # Exact match
                            if keyword_lower in product_name_lower:
                                matched = True
                                break
                            
                            # Synonym match
                            for main_term, synonyms in synonym_map.items():
                                if keyword_lower in main_term or main_term in keyword_lower:
                                    if any(syn in product_name_lower for syn in synonyms):
                                        matched = True
                                        break
                                if matched:
                                    break
                            
                            if matched:
                                break
                            
                            # Fuzzy match (Levenshtein-like)
                            if not matched and len(keyword_lower) >= 3:
                                try:
                                    from difflib import SequenceMatcher
                                    product_words = product_name_lower.split()
                                    for word in product_words:
                                        if len(word) >= 3:
                                            similarity = SequenceMatcher(None, keyword_lower, word).ratio()
                                            if similarity > 0.7:  # 70% similarity
                                                matched = True
                                                break
                                    if matched:
                                        break
                                except:
                                    pass
                        
                        if matched:
                            products.append({
                                "product_id": str(product_id),
                                "product_name": str(product_name),
                                "category_id": str(cat_id) if cat_id else "",
                                "category_name": str(cat_name) if cat_name else "",
                                "price": float(price) if price is not None else None,
                                "unit": str(don_vi_tinh) if don_vi_tinh else "",
                                "description": str(description) if description else "",
                                "similarity": relevance / 100.0,
                                "source": "sql_fuzzy_match"
                            })
                        else:
                            self.log(f"⚠️ Fuzzy match rejected: '{product_name}' - no keyword match with {keywords_sorted[:2]}")
                    
                    cursor.close()
                    return products
                    
                except Exception as e:
                    self.log(f"Error in fuzzy SQL search: {str(e)}", level="error")
                    return []
                finally:
                    if conn:
                        conn.close()
            
            results = await asyncio.to_thread(search_in_db)
            return results
            
        except Exception as e:
            self.log(f"Error in fuzzy SQL search: {str(e)}", level="error")
            return []
    
    def _get_cache_key(self, query: str, category_id: Optional[str], top_k: int) -> str:
        """Generate cache key for search results"""
        key_str = f"{query.lower().strip()}:{category_id or 'all'}:{top_k}"
        return hashlib.md5(key_str.encode()).hexdigest()
