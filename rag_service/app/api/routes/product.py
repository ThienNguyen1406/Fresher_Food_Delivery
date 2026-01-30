from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Query, Body
from pydantic import BaseModel
from typing import List, Optional, Dict
from pathlib import Path
import logging
import json

from app.api.deps import (
    get_product_ingest_pipeline,
    get_image_vector_store,
    get_image_embedding_service,
    get_embedding_service,
    get_llm_provider,
    get_prompt_builder
)
from app.core.product_ingest_pipeline import ProductIngestPipeline
from app.core.prompt_builder import PromptBuilder
from app.core.settings import Settings
from app.infrastructure.vector_store.image_vector_store import ImageVectorStore
from app.infrastructure.llm.openai import LLMProvider
from app.services.image import ImageEmbeddingService
from app.services.embedding import EmbeddingService

router = APIRouter()
logger = logging.getLogger(__name__)

# Models
class ProductData(BaseModel):
    product_id: Optional[str] = None
    product_name: str
    description: Optional[str] = None
    category_id: str
    category_name: Optional[str] = None
    price: Optional[float] = None
    unit: Optional[str] = None
    origin: Optional[str] = None

class EmbedProductResponse(BaseModel):
    product_id: str
    message: str
    has_image: bool
    has_text: bool

class ProductSearchRequest(BaseModel):
    query: Optional[str] = None
    category_id: Optional[str] = None
    top_k: int = 10

class ProductSearchResult(BaseModel):
    product_id: str
    product_name: str
    category_id: str
    category_name: str
    similarity: float
    price: Optional[float] = None

class ProductSearchResponse(BaseModel):
    results: List[ProductSearchResult]
    query_type: str  # "image", "text", or "chat"
    description: Optional[str] = None  # Mô tả từ LLM (nếu có)
    
class ChatProductResponse(BaseModel):
    products: List[Dict]
    message: str
    has_images: bool

@router.post("/embed", response_model=EmbedProductResponse)
async def embed_product(
    product_id: Optional[str] = None,
    product_name: str = None,
    description: Optional[str] = None,
    category_id: str = None,
    category_name: Optional[str] = None,
    price: Optional[float] = None,
    unit: Optional[str] = None,
    origin: Optional[str] = None,
    image: Optional[UploadFile] = File(None),
    product_ingest_pipeline: ProductIngestPipeline = Depends(get_product_ingest_pipeline)
):
    """
    Embed product vào Vector Database
    Pipeline: Product (Text + Image) → Embeddings → Vector Database (theo category)
    """
    import time
    start_time = time.time()
    
    try:
        # Validate required fields
        if not product_name:
            raise HTTPException(status_code=400, detail="product_name is required")
        if not category_id:
            raise HTTPException(status_code=400, detail="category_id is required")
        
        logger.info(f"📦 Nhận request embed product: {product_name} (Category: {category_id})")
        
        # Đọc ảnh nếu có
        image_bytes = None
        if image:
            contents = await image.read()
            file_size_mb = len(contents) / (1024 * 1024)
            
            # Kiểm tra file size (10MB)
            if len(contents) > 10 * 1024 * 1024:
                raise HTTPException(status_code=400, detail="Image size exceeds 10MB limit")
            
            # Kiểm tra file type
            allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
            file_ext = Path(image.filename).suffix.lower()
            if file_ext not in allowed_extensions:
                raise HTTPException(
                    status_code=400,
                    detail=f"Image type {file_ext} not supported"
                )
            
            image_bytes = contents
            logger.info(f"📷 Ảnh sản phẩm: {file_size_mb:.2f} MB")
        
        # Build product dict
        product_dict = {
            'product_id': product_id,
            'product_name': product_name,
            'description': description,
            'category_id': category_id,
            'category_name': category_name,
            'price': price,
            'unit': unit,
            'origin': origin,
        }
        
        # Xử lý và lưu product
        logger.info(f"🔄 Bắt đầu embed product...")
        product_id = await product_ingest_pipeline.process_and_store(
            product_dict,
            image_bytes,
            product_id=product_dict.get('product_id')
        )
        
        elapsed_time = time.time() - start_time
        logger.info(f"✅ Hoàn thành embed product trong {elapsed_time:.2f} giây")
        
        return EmbedProductResponse(
            product_id=product_id,
            message=f"Product embedded successfully in {elapsed_time:.2f}s",
            has_image=image_bytes is not None,
            has_text=bool(product_name or description)
        )
    
    except HTTPException:
        raise
    except Exception as e:
        elapsed_time = time.time() - start_time
        logger.error(f"❌ Lỗi khi embed product sau {elapsed_time:.2f}s: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error embedding product: {str(e)}"
        )

@router.post("/search/image", response_model=ProductSearchResponse)
async def search_products_by_image(
    image: UploadFile = File(...),
    category_id: Optional[str] = Query(None, description="Filter by category ID"),
    top_k: int = Query(10, ge=1, le=50),
    user_description: Optional[str] = Query(None, description="Mô tả của người dùng về ảnh"),
    image_embedding_service: ImageEmbeddingService = Depends(get_image_embedding_service),
    vector_store: ImageVectorStore = Depends(get_image_vector_store),
    llm_provider: LLMProvider = Depends(get_llm_provider),
    prompt_builder: PromptBuilder = Depends(get_prompt_builder)
):
    """
    Image to Image Search - Tìm kiếm sản phẩm bằng ảnh
    
    """
    import time
    import numpy as np
    start_time = time.time()
    
    try:
        logger.info(f"🔍 Image to Image search (category: {category_id}, top_k: {top_k})")
        
        # Đọc ảnh query
        contents = await image.read()
        
        # Search CHỈ BẰNG IMAGE EMBEDDING trước
        # Vision KHÔNG nằm trong critical path search
        logger.info(f"🔢 Đang tạo image embedding từ ảnh query...")
        query_embedding = await image_embedding_service.create_embedding(contents)
        
        if query_embedding is None:
            raise HTTPException(status_code=500, detail="Không thể tạo embedding từ ảnh query")
        
        # Vector search CHỈ BẰNG IMAGE EMBEDDING
        logger.info(f"🔍 Đang tìm kiếm trong vector database (image embedding only)...")
        
        # Build where clause
        where_clause = {"content_type": "product"}
        if category_id:
            where_clause["category_id"] = category_id
        
        # Search (Chroma query is synchronous, need to run in thread)
        import asyncio
        search_top_k = top_k + 2  # 🔥 TỐI ƯU: Chỉ lấy thêm 2
        results = await asyncio.to_thread(
            vector_store.collection.query,
            query_embeddings=[query_embedding.tolist()],
            n_results=search_top_k,
            where=where_clause
        )
        
        # Parse results và lấy best similarity
        products = []
        best_similarity = 0.0
        
        if results.get('ids') and len(results['ids'][0]) > 0:
            for i in range(len(results['ids'][0])):
                metadata = results['metadatas'][0][i]
                distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                similarity = 1 - distance
                
                # Track best similarity
                if similarity > best_similarity:
                    best_similarity = similarity
                
                # Lấy product_id từ metadata
                product_id = metadata.get('file_id', '') or metadata.get('product_id', '')
                
                product = ProductSearchResult(
                    product_id=product_id,
                    product_name="",  # 🔥 Metadata không lưu product_name, lấy từ SQL sau
                    category_id=metadata.get('category_id', ''),
                    category_name="",  # 🔥 Metadata không lưu category_name, lấy từ SQL sau
                    similarity=float(similarity),
                    price=float(metadata.get('price', 0)) if metadata.get('price') else None
                )
                products.append(product)
                
                if len(products) >= top_k:
                    break
        
        # Nếu best_similarity < 0.6 → MỚI GỌI Vision
        vision_caption = None
        if best_similarity < 0.6 and Settings.USE_VISION_CAPTION and llm_provider and hasattr(llm_provider, 'client') and llm_provider.client:
            logger.info(f"👁️  Similarity thấp ({best_similarity:.2f} < 0.6), gọi Vision để cải thiện...")
            try:
                import base64
                image_base64 = base64.b64encode(contents).decode('utf-8')
                
                # Prompt này tạo mô tả chính xác hơn cho e-commerce search
                system_message = """You are a visual attribute extraction assistant for an e-commerce search system.
                                    You must describe ONLY what is directly visible in the image.
                                    Do NOT guess brand names, product names, ingredients, or usage."""

                vision_prompt = """Observe the product image carefully and extract visible attributes.

                                    Follow these rules strictly:
                                    - Describe only what you can see in the image.
                                    - If a detail is unclear, write "unknown".
                                    - Do not infer brand or product identity.

                                    Describe the product using the following structure:

                                    Packaging:
                                    - Type: (box / bottle / bag / pouch / can / carton / unknown)
                                    - Material appearance: (plastic / paper / glass / metal / unknown)

                                    Appearance:
                                    - Main colors:
                                    - Shape:
                                    - Size impression: (small / medium / large / unknown)

                                    Text & Graphics:
                                    - Presence of text: (yes / no)
                                    - Text appearance: (color, orientation, font style if visible)
                                    - Graphic elements: (icons, images, patterns, none)

                                    Category (generic, based only on appearance):
                                    - (drink / food / household item / personal care / unknown)

                                    Output:
                                    Return two short descriptions with the same information:
                                    1. English
                                    2. Vietnamese"""
                
                vision_response = llm_provider.client.chat.completions.create(
                    model="gpt-4o",
                    messages=[
                        {"role": "system", "content": system_message},
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": vision_prompt},
                                {
                                    "type": "image_url",
                                    "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}
                                }
                            ]
                        }
                    ],
                    max_tokens=300,  # 🔥 Tăng vì prompt mới cần output cấu trúc hơn (English + Vietnamese)
                    temperature=0.1  # 🔥 Giảm temperature để output nhất quán hơn
                )
                vision_caption = vision_response.choices[0].message.content.strip()
                
                # Check rejection
                caption_lower = vision_caption.lower()
                rejection_keywords = [
                    "i'm sorry", "i can't help", "i cannot", "i can't assist",
                    "i'm not able", "i'm unable", "cannot identify", "can't identify"
                ]
                if any(kw in caption_lower for kw in rejection_keywords):
                    logger.warning("⚠️  Vision model đã từ chối mô tả ảnh")
                    vision_caption = user_description if user_description else None
                else:
                    logger.info(f"✅ Đã tạo Vision caption: {vision_caption[:100]}...")
                    
                    # 🔥 TỐI ƯU: Re-search với combined embedding (60% image + 40% caption)
                    # Sử dụng EmbeddingService method (không normalize trong API)
                    query_embedding = image_embedding_service.create_query_embedding(
                        image_bytes=contents,
                        caption=vision_caption
                    )
                    
                    if query_embedding is not None:
                        # Re-search với combined embedding
                        logger.info("🔍 Re-search với combined embedding (image + caption)...")
                        results = await asyncio.to_thread(
                            vector_store.collection.query,
                            query_embeddings=[query_embedding.tolist()],
                            n_results=search_top_k,
                            where=where_clause
                        )
                        
                        # Re-parse results
                        products = []
                        for i in range(len(results['ids'][0]) if results.get('ids') and results['ids'][0] else 0):
                            metadata = results['metadatas'][0][i]
                            distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                            similarity = 1 - distance
                            
                            product_id = metadata.get('file_id', '') or metadata.get('product_id', '')
                            product = ProductSearchResult(
                                product_id=product_id,
                                product_name="",
                                category_id=metadata.get('category_id', ''),
                                category_name="",
                                similarity=float(similarity),
                                price=float(metadata.get('price', 0)) if metadata.get('price') else None
                            )
                            products.append(product)
                            
                            if len(products) >= top_k:
                                break
            except Exception as e:
                logger.warning(f"⚠️  Lỗi khi gọi Vision: {str(e)}")
                vision_caption = user_description if user_description else None
        
        elapsed_time = time.time() - start_time
        logger.info(f"✅ Tìm thấy {len(products)} products trong {elapsed_time:.2f} giây")
        
        # 🔥 BOTTLENECK #1 FIX: LLM description chỉ gọi khi similarity < 0.85
        description = None
        if products:
            best_similarity = products[0].similarity if products else 0.0
            if best_similarity < 0.85:
                try:
                    logger.info(f"🤖 Similarity thấp ({best_similarity:.2f} < 0.85), tạo mô tả từ LLM...")
                    products_data = []
                    for p in products:
                        products_data.append({
                            'product_name': p.product_name or "Unknown",
                            'category_name': p.category_name or "Unknown",
                            'price': p.price,
                            'similarity': p.similarity
                        })
                    
                    prompt = prompt_builder.build_image_search_description_prompt(
                        products=products_data,
                        user_description=user_description
                    )
                    
                    description = await llm_provider.generate(prompt)
                    logger.info(f"✅ Đã tạo mô tả từ LLM: {len(description)} ký tự")
                except Exception as e:
                    logger.warning(f"⚠️  Không thể tạo mô tả từ LLM: {str(e)}")
                    description = None
            else:
                logger.info(f"⏭️  Bỏ qua LLM description (similarity: {best_similarity:.2f} >= 0.85, đã đủ tốt)")
        
        return ProductSearchResponse(
            results=products,
            query_type="image",
            description=description
        )
    
    except HTTPException:
        raise
    except Exception as e:
        elapsed_time = time.time() - start_time
        logger.error(f"❌ Lỗi khi search products by image sau {elapsed_time:.2f}s: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error searching products: {str(e)}"
        )

@router.post("/search/text", response_model=ProductSearchResponse)
async def search_products_by_text(
    request: ProductSearchRequest = Body(...),
    text_embedding_service: EmbeddingService = Depends(get_embedding_service),
    vector_store: ImageVectorStore = Depends(get_image_vector_store)
):
    """
    Text to Image Search - Tìm kiếm sản phẩm bằng text
    """
    import time
    import numpy as np
    start_time = time.time()
    
    try:
        query = request.query
        if not query or not query.strip():
            raise HTTPException(status_code=400, detail="Query text is required")
        
        logger.info(f"🔍 Text to Image search: '{query}' (category: {request.category_id}, top_k: {request.top_k})")
        
        # 🔥 BOTTLENECK #5 FIX: Dùng CLIP text encoder (512 dim) - tương thích với image embeddings
        # KHÔNG resize embedding thủ công
        from app.api.deps import get_image_embedding_service
        image_embedding_service = get_image_embedding_service()
        
        logger.info(f"🔢 Đang tạo text embedding từ query (CLIP text encoder)...")
        query_embedding = image_embedding_service.create_text_embedding(query)
        
        if query_embedding is None:
            raise HTTPException(status_code=500, detail="Không thể tạo embedding từ text query")
        
        logger.info(f"  📊 Query embedding dimension: {len(query_embedding)} (CLIP text encoder - 512 dim)")
        
        # Build where clause
        where_clause = {"content_type": "product"}
        if request.category_id:
            where_clause["category_id"] = request.category_id
        
        # 🔥 Search với CLIP text embedding (512 dim) - không cần resize
        import asyncio
        results = await asyncio.to_thread(
            vector_store.collection.query,
            query_embeddings=[query_embedding.tolist()],
            n_results=request.top_k,
            where=where_clause
        )
        
        # Parse results
        products = []
        if results.get('ids') and len(results['ids'][0]) > 0:
            for i in range(len(results['ids'][0])):
                metadata = results['metadatas'][0][i]
                distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                similarity = 1 - distance
                
                # 🔥 Metadata không lưu product_name, category_name - lấy từ SQL sau
                product = ProductSearchResult(
                    product_id=metadata.get('file_id', '') or metadata.get('product_id', ''),
                    product_name="",  # Lấy từ SQL sau
                    category_id=metadata.get('category_id', ''),
                    category_name="",  # Lấy từ SQL sau
                    similarity=float(similarity),
                    price=float(metadata.get('price', 0)) if metadata.get('price') else None
                )
                products.append(product)
        
        elapsed_time = time.time() - start_time
        logger.info(f"✅ Tìm thấy {len(products)} products trong {elapsed_time:.2f} giây")
        
        return ProductSearchResponse(
            results=products,
            query_type="text"
        )
    
    except HTTPException:
        raise
    except Exception as e:
        elapsed_time = time.time() - start_time
        logger.error(f"❌ Lỗi khi search products by text sau {elapsed_time:.2f}s: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error searching products: {str(e)}"
        )

@router.post("/search/chat", response_model=ChatProductResponse)
async def search_products_for_chat(
    query: str = Body(..., embed=True),
    category_id: Optional[str] = None,
    top_k: int = Query(5, ge=1, le=10, description="Số lượng sản phẩm trả về (mặc định: 5)"),
    min_similarity: Optional[float] = Query(
        0.3,
        ge=0.0,
        le=1.0,
        description="(Optional) Ngưỡng similarity tối thiểu. Nếu thấp hơn sẽ không trả về. Mặc định: 0.3"
    ),
    text_embedding_service: EmbeddingService = Depends(get_embedding_service),
    vector_store: ImageVectorStore = Depends(get_image_vector_store)
):
    """
    Search products - Trả về products với image URLs
    
    """
    import time
    import numpy as np
    import httpx
    from app.core.settings import Settings
    start_time = time.time()
    
    try:
        if not query or not query.strip():
            raise HTTPException(status_code=400, detail="Query text is required")
        
        logger.info(f"💬 Chat search: '{query}' (category: {category_id}, top_k: {top_k})")

        # Base URL dùng để download ảnh (dùng chung cho SQL + vector)
        base_url = Settings.APP_BASE_URL.replace('/api', '') if Settings.APP_BASE_URL else 'https://localhost:7240'
        has_images = False

        # ============================================================
        # ƯU TIÊN KHỚP CHÍNH XÁC THEO TÊN/MÔ TẢ TRONG DATABASE (SQL)
        # Nếu có kết quả, trả về luôn (kèm ảnh base64) để đảm bảo đúng loại.
        # ============================================================
        sql_products: List[Dict] = []
        try:
            import pyodbc
            import urllib.parse
            import base64
            from app.core.settings import Settings

            # Build ODBC connection string (reuse logic)
            conn_str = Settings.DATABASE_CONNECTION_STRING
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

            conn = None
            for driver_name in ["ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server Native Client 11.0"]:
                try:
                    test_conn_str = conn_str
                    if driver_name not in test_conn_str:
                        import re
                        test_conn_str = re.sub(r'DRIVER=\{[^}]+\}', f'DRIVER={{{driver_name}}}', test_conn_str, count=1)
                    conn = pyodbc.connect(test_conn_str)
                    break
                except Exception:
                    continue

            if conn:
                cursor = conn.cursor()

                # Nếu user gõ "lấy ra hình ảnh ..." thì query đã được C# extract còn lại keyword.
                keyword = query.strip()
                like = f"%{keyword}%"

                # Ưu tiên TenSanPham match trước, sau đó MoTa
                db_query = f"""
                    SELECT TOP {top_k}
                        s.MaSanPham,
                        s.TenSanPham,
                        s.MoTa,
                        s.Anh,
                        s.GiaBan,
                        s.MaDanhMuc,
                        dm.TenDanhMuc
                    FROM SanPham s
                    LEFT JOIN DanhMuc dm ON s.MaDanhMuc = dm.MaDanhMuc
                    WHERE (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                      AND (
                        s.TenSanPham LIKE ?
                        OR s.MoTa LIKE ?
                      )
                    ORDER BY
                        CASE WHEN s.TenSanPham LIKE ? THEN 0 ELSE 1 END,
                        s.TenSanPham
                """
                cursor.execute(db_query, like, like, like)
                rows = cursor.fetchall()
                cursor.close()
                conn.close()

                if rows:
                    logger.info(f"  🎯 SQL exact-ish match found: {len(rows)} products for '{keyword}'")
                    async with httpx.AsyncClient(verify=False, timeout=5.0) as client:
                        for row in rows:
                            product_id, product_name, description, image_filename, price, cat_id, cat_name = row
                            image_data = None
                            image_mime_type = None

                            if image_filename:
                                encoded_filename = urllib.parse.quote(str(image_filename), safe='')
                                image_url = f"{base_url}/images/products/{encoded_filename}"
                                try:
                                    img_resp = await client.get(image_url, timeout=5.0)
                                    if img_resp.status_code == 200:
                                        image_data = base64.b64encode(img_resp.content).decode('utf-8')
                                        image_mime_type = img_resp.headers.get('content-type', 'image/jpeg')
                                except Exception:
                                    image_data = None
                                    image_mime_type = None

                            if image_data:
                                has_images = True

                            sql_products.append({
                                "product_id": str(product_id),
                                "product_name": str(product_name),
                                "category_id": str(cat_id) if cat_id else "",
                                "category_name": str(cat_name) if cat_name else "",
                                "price": float(price) if price is not None else None,
                                "description": str(description) if description else "",
                                "image_data": image_data,
                                "image_mime_type": image_mime_type,
                                "similarity": 1.0,  # SQL match => treat as max relevance
                            })

                    if sql_products:
                        if len(sql_products) == 1:
                            product = sql_products[0]
                            description = product.get('description', '')
                            if description:
                                description_short = description[:150] + ('...' if len(description) > 150 else '')
                                message = f"Tôi tìm thấy 1 sản phẩm: {product['product_name']}.\n\n{description_short}"
                            else:
                                message = f"Tôi tìm thấy 1 sản phẩm: {product['product_name']}."
                        else:
                            message = f"Tôi tìm thấy {len(sql_products)} sản phẩm phù hợp với '{query}'."
                            # Thêm description cho sản phẩm đầu tiên
                            if sql_products[0].get('description'):
                                desc = sql_products[0]['description'][:100] + ('...' if len(sql_products[0]['description']) > 100 else '')
                                message += f"\n\n{sql_products[0]['product_name']}: {desc}"
                        return ChatProductResponse(products=sql_products, message=message, has_images=has_images)

        except Exception as e:
            # Không fail toàn request nếu SQL search lỗi → fallback sang vector
            logger.warning(f"  ⚠️  SQL keyword search failed, fallback to vector search: {str(e)}")
        
        # Tạo text embedding từ query bằng CLIP text encoder (512 dim)
        # CLIP text encoder tương thích với image embedding (cùng 512 dim)
        image_embedding_service = get_image_embedding_service()
        
        query_embedding = image_embedding_service.create_text_embedding(query)
        
        if query_embedding is None:
            raise HTTPException(status_code=500, detail="Không thể tạo embedding từ text query")
        
        logger.info(f"  📊 Query embedding dimension: {len(query_embedding)} (CLIP text encoder)")
        
        # CLIP text embedding đã có dimension 512, không cần resize
        query_embedding_resized = query_embedding
        
        # Build where clause
        where_clause = {"content_type": "product"}
        if category_id:
            where_clause["category_id"] = category_id
        
        # 2) Vector search fallback
        import asyncio
        search_top_k = max(top_k * 3, 10)
        results = await asyncio.to_thread(
            vector_store.collection.query,
            query_embeddings=[query_embedding_resized.tolist()],
            n_results=search_top_k,
            where=where_clause
        )
        
        # ✅ TOP K theo similarity (fallback), có threshold (min_similarity)
        if results.get('ids') and len(results['ids'][0]) > 0:
            similarities = []
            for i in range(len(results['ids'][0])):
                distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                similarity = 1 - distance
                similarities.append((i, similarity))

            similarities_sorted = sorted(similarities, key=lambda x: x[1], reverse=True)
            logger.info(f"  📊 Similarities: {[f'{s[1]:.3f}' for s in similarities_sorted[:5]]}")

            # Apply threshold + take TOP K
            kept = []
            for idx, sim in similarities_sorted:
                if min_similarity is None or sim >= min_similarity:
                    kept.append(idx)
                if len(kept) >= top_k:
                    break

            if not kept:
                logger.info(f"  🚫 No vector results above min_similarity={min_similarity}")
                results['ids'] = [[]]
                results['metadatas'] = [[]]
                results['distances'] = [[]] if 'distances' in results else []
            else:
                results['ids'] = [[results['ids'][0][i] for i in kept]]
                results['metadatas'] = [[results['metadatas'][0][i] for i in kept]]
                if 'distances' in results and results['distances']:
                    results['distances'] = [[results['distances'][0][i] for i in kept]]
        
        # Parse results và lấy image URLs từ backend
        products = []
        
        if results.get('ids') and len(results['ids'][0]) > 0:
            # Lấy image URLs từ backend cho từng product
            async with httpx.AsyncClient(verify=False, timeout=5.0) as client:
                for i in range(len(results['ids'][0])):
                    metadata = results['metadatas'][0][i]
                    distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                    similarity = 1 - distance
                    
                    # Lấy product_id từ metadata (ưu tiên product_id, sau đó file_id, cuối cùng extract từ chunk_id)
                    product_id = metadata.get('product_id') or metadata.get('file_id', '')
                    
                    # Nếu vẫn rỗng hoặc có format chunk_id, extract từ chunk_id
                    if not product_id or '-chunk-' in product_id:
                        chunk_id = results['ids'][0][i] if results.get('ids') and i < len(results['ids'][0]) else ''
                        if chunk_id and '-chunk-' in chunk_id:
                            product_id = chunk_id.split('-chunk-')[0]
                    
                    product_name = metadata.get('product_name') or metadata.get('file_name', '')
                    
                    logger.info(f"  📦 Product {i+1}: ID={product_id}, Name={product_name}")
                    
                    # Lấy image data (base64) - ưu tiên từ metadata, sau đó query database và download
                    image_data = None
                    image_mime_type = None
                    image_url_for_download = None
                    
                    # Bước 1: Thử lấy image filename từ metadata (nhanh hơn, không cần query database)
                    # Ưu tiên: image_filename > anh > file_name (chỉ nếu có extension như .jpg, .png)
                    image_filename = metadata.get('image_filename') or metadata.get('anh')
                    
                    # Nếu không có, thử file_name nhưng chỉ nếu trông giống filename (có extension)
                    if not image_filename:
                        file_name = metadata.get('file_name', '')
                        # Kiểm tra xem file_name có extension không (trông giống filename)
                        if file_name and any(file_name.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']):
                            image_filename = file_name
                    
                    if image_filename and not image_filename.startswith('http'):
                        # URL encode filename để xử lý ký tự đặc biệt
                        import urllib.parse
                        encoded_filename = urllib.parse.quote(image_filename, safe='')
                        image_url_for_download = f"{base_url}/images/products/{encoded_filename}"
                        logger.info(f"  📷 Image URL từ metadata: {image_url_for_download}")
                    
                    # Bước 2: Nếu không có trong metadata, query database trực tiếp từ Python
                    if not image_url_for_download and product_id:
                        try:
                            # Query database trực tiếp (nhanh hơn và không cần HTTP)
                            import pyodbc
                            from app.core.settings import Settings
                            
                            conn_str = Settings.DATABASE_CONNECTION_STRING
                            # Convert to ODBC format
                            if "DRIVER=" not in conn_str.upper():
                                params = {}
                                parts = [p.strip() for p in conn_str.split(';') if p.strip()]
                                for part in parts:
                                    if '=' in part:
                                        key, value = part.split('=', 1)
                                        key = key.strip().lower()
                                        value = value.strip()
                                        params[key] = value
                                
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
                            
                            # Try to connect
                            conn = None
                            for driver_name in ["ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server Native Client 11.0"]:
                                try:
                                    test_conn_str = conn_str.replace("{ODBC Driver 18 for SQL Server}", f"{{{driver_name}}}")
                                    test_conn_str = test_conn_str.replace("{ODBC Driver 17 for SQL Server}", f"{{{driver_name}}}")
                                    if driver_name not in test_conn_str:
                                        import re
                                        test_conn_str = re.sub(r'DRIVER=\{[^}]+\}', f'DRIVER={{{driver_name}}}', test_conn_str, count=1)
                                    conn = pyodbc.connect(test_conn_str)
                                    break
                                except:
                                    continue
                            
                            if conn:
                                cursor = conn.cursor()
                                sql_query = "SELECT Anh FROM SanPham WHERE MaSanPham = ? AND (IsDeleted = 0 OR IsDeleted IS NULL)"
                                cursor.execute(sql_query, product_id)
                                row = cursor.fetchone()
                                cursor.close()
                                conn.close()
                                
                                if row and row[0]:
                                    image_filename = row[0]
                                    import urllib.parse
                                    encoded_filename = urllib.parse.quote(image_filename, safe='')
                                    image_url_for_download = f"{base_url}/images/products/{encoded_filename}"
                                    logger.info(f"  📷 Image URL từ database: {image_url_for_download}")
                                else:
                                    logger.warning(f"  ⚠️  Product {product_id} không có ảnh trong database")
                            else:
                                logger.warning(f"  ⚠️  Không thể kết nối database để lấy image filename")
                        except Exception as e:
                            logger.warning(f"  ⚠️  Lỗi khi query database cho product {product_id}: {str(e)}")
                    elif not product_id:
                        logger.warning(f"  ⚠️  Product {i+1} không có product_id, không thể lấy ảnh")
                    
                    # Bước 3: Download ảnh từ URL và convert sang base64
                    if image_url_for_download:
                        try:
                            logger.info(f"  ⬇️  Đang download ảnh từ: {image_url_for_download}")
                            image_response = await client.get(image_url_for_download, timeout=5.0)
                            if image_response.status_code == 200:
                                image_bytes = image_response.content
                                import base64
                                image_data = base64.b64encode(image_bytes).decode('utf-8')
                                image_mime_type = image_response.headers.get('content-type', 'image/jpeg')
                                has_images = True  # Set has_images = True nếu có ít nhất 1 ảnh
                                logger.info(f"  ✅ Đã download và convert ảnh: {len(image_bytes)} bytes, MIME: {image_mime_type}")
                            else:
                                logger.warning(f"  ⚠️  Không thể download ảnh từ: {image_url_for_download} (status: {image_response.status_code})")
                                image_data = None
                                image_mime_type = None
                        except Exception as download_error:
                            logger.warning(f"  ⚠️  Lỗi khi download ảnh: {str(download_error)}")
                            image_data = None
                            image_mime_type = None
                    else:
                        image_data = None
                        image_mime_type = None
                    
                    product = {
                        'product_id': product_id,
                        'product_name': product_name,
                        'category_id': metadata.get('category_id', ''),
                        'category_name': metadata.get('category_name', ''),
                        'price': float(metadata.get('price', 0)) if metadata.get('price') else None,
                        'description': metadata.get('description', ''),
                        'image_data': image_data,  # Base64 encoded image
                        'image_mime_type': image_mime_type,  # MIME type
                        'similarity': float(similarity)
                    }
                    products.append(product)
        
        # 🔍 Bộ lọc từ khóa đơn giản để tránh sản phẩm "khác loại" quá xa
        if products:
            try:
                import re
                # Các từ ít thông tin (bỏ qua khi so khớp)
                stopwords = {
                    "hình", "ảnh", "hình ảnh", "hinh", "anh",
                    "lấy", "lay", "cho", "ra", "xem", "xem thử",
                    "sản", "phẩm", "san", "pham", "sản phẩm",
                    "của", "về", "với", "giúp", "mình", "tôi"
                }

                def _normalize(text: str) -> str:
                    text = text.lower()
                    text = re.sub(r"[^0-9a-zA-ZÀ-ỹ\s]", " ", text)
                    text = re.sub(r"\s+", " ", text).strip()
                    return text

                norm_query = _normalize(query)
                query_tokens = [
                    tok for tok in norm_query.split()
                    if tok and tok not in stopwords
                ]

                if query_tokens:
                    filtered_products = []
                    for p in products:
                        name = _normalize((p.get("product_name") or ""))
                        desc = _normalize((p.get("description") or ""))
                        combined = f"{name} {desc}".strip()
                        if any(tok in combined for tok in query_tokens):
                            filtered_products.append(p)

                    if filtered_products:
                        logger.info(f"  🔍 Lexical filter giữ lại {len(filtered_products)}/{len(products)} products")
                        products = filtered_products
                    else:
                        logger.info("  🚫 Lexical filter loại bỏ toàn bộ vector results (không còn sản phẩm thực sự khớp từ khóa)")
            except Exception as lexical_err:
                logger.warning(f"  ⚠️ Lexical filter failed, dùng nguyên vector results: {lexical_err}")
        
        elapsed_time = time.time() - start_time
        logger.info(f"✅ Chat search tìm thấy {len(products)} products trong {elapsed_time:.2f} giây")
        
        # Tạo message cho chatbot (tự nhiên, đúng ngữ cảnh Việt Nam) - thêm description
        if products:
            if len(products) == 1:
                product = products[0]
                description = product.get('description', '')
                # Giới hạn description tối đa 150 ký tự
                if description:
                    description_short = description[:150] + ('...' if len(description) > 150 else '')
                    message = f"Tôi tìm thấy 1 sản phẩm: {product['product_name']}.\n\n{description_short}"
                else:
                    message = f"Tôi tìm thấy 1 sản phẩm: {product['product_name']}."
            elif len(products) == 2:
                product1 = products[0]
                product2 = products[1]
                desc1 = product1.get('description', '')[:100] + ('...' if len(product1.get('description', '')) > 100 else '') if product1.get('description') else ''
                desc2 = product2.get('description', '')[:100] + ('...' if len(product2.get('description', '')) > 100 else '') if product2.get('description') else ''
                
                message = f"Tôi tìm thấy 2 sản phẩm:\n\n1. {product1['product_name']}"
                if desc1:
                    message += f"\n   {desc1}"
                message += f"\n\n2. {product2['product_name']}"
                if desc2:
                    message += f"\n   {desc2}"
            else:
                product_names = [p['product_name'] for p in products[:3]]
                message = f"Tôi tìm thấy {len(products)} sản phẩm: {', '.join(product_names)}"
                if len(products) > 3:
                    message += f" và {len(products) - 3} sản phẩm khác."
                
                # Thêm description cho sản phẩm đầu tiên
                if products[0].get('description'):
                    desc = products[0]['description'][:100] + ('...' if len(products[0]['description']) > 100 else '')
                    message += f"\n\n{products[0]['product_name']}: {desc}"
        else:
            message = f"Xin lỗi, tôi không tìm thấy sản phẩm nào liên quan đến '{query}'. Bạn có thể thử tìm kiếm với từ khóa khác."
        
        return ChatProductResponse(
            products=products,
            message=message,
            has_images=has_images
        )
    
    except HTTPException:
        raise
    except Exception as e:
        elapsed_time = time.time() - start_time
        logger.error(f"❌ Lỗi khi search products for chat sau {elapsed_time:.2f}s: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error searching products: {str(e)}"
        )

@router.get("/category/{category_id}")
async def get_products_by_category(
    category_id: str,
    vector_store: ImageVectorStore = Depends(get_image_vector_store)
):
    """
    Lấy danh sách products trong một category từ Vector Database
    """
    try:
        # Lấy tất cả products trong category (Chroma get is synchronous)
        import asyncio
        results = await asyncio.to_thread(
            vector_store.collection.get,
            where={
                "content_type": "product",
                "category_id": category_id
            }
        )
        
        products = []
        if results.get('ids') and len(results['ids']) > 0:
            metadatas = results.get('metadatas', [])
            for i in range(len(results['ids'])):
                metadata = metadatas[i] if i < len(metadatas) else {}
                products.append({
                    'product_id': metadata.get('file_id', ''),
                    'product_name': metadata.get('file_name', ''),
                    'category_id': metadata.get('category_id', ''),
                    'category_name': metadata.get('category_name', ''),
                    'price': metadata.get('price', ''),
                    'description': metadata.get('description', '')
                })
        
        return {"category_id": category_id, "products": products, "total": len(products)}
    
    except Exception as e:
        logger.error(f"Error getting products by category: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{product_id}/image-url")
async def get_product_image_url(
    product_id: str
):
    """
    Lấy image URL của product từ backend
    
    Returns:
        image_url: URL đầy đủ của ảnh sản phẩm
    """
    from app.core.settings import Settings
    import httpx
    
    try:
        # Gọi backend API để lấy thông tin product
        base_url = Settings.APP_BASE_URL.replace('/api', '') if Settings.APP_BASE_URL else 'https://localhost:7240'
        
        async with httpx.AsyncClient(verify=False, timeout=10.0) as client:
            response = await client.get(f"{base_url}/api/Product/{product_id}")
            
            if response.status_code == 200:
                product_data = response.json()
                image_url = product_data.get('anh')  # Backend trả về field 'anh'
                return {"product_id": product_id, "image_url": image_url}
            else:
                # Fallback: tạo URL từ product_id
                image_url = f"{base_url}/images/products/{product_id}.jpg"
                return {"product_id": product_id, "image_url": image_url}
    
    except Exception as e:
        logger.error(f"Error getting product image URL: {str(e)}")
        # Fallback
        base_url = Settings.APP_BASE_URL.replace('/api', '') if Settings.APP_BASE_URL else 'https://localhost:7240'
        image_url = f"{base_url}/images/products/{product_id}.jpg"
        return {"product_id": product_id, "image_url": image_url}

