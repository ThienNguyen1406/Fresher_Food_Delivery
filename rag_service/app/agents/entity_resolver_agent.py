"""
Entity Resolver Agent - Xác định entity (sản phẩm) từ query
"""
from typing import Dict, Any, Optional, List
import logging
import re
from functools import lru_cache
from app.agents.base_agent import BaseAgent
from app.core.settings import Settings

logger = logging.getLogger(__name__)


class EntityResolverAgent(BaseAgent):
    """
    Entity Resolver Agents
    """
    
    def __init__(self):
        super().__init__("EntityResolverAgent")
        
        # 🔥 Synonym map cho các sản phẩm phổ biến
        self.synonym_map = {
            "cá hồi": ["cá hồi", "salmon", "cá hồi na uy", "cá hồi tươi", "cá hồi nauy"],
            "thịt bò": ["thịt bò", "beef", "thịt bò tươi", "bò"],
            "thịt heo": ["thịt heo", "pork", "thịt lợn", "heo"],
            "gà": ["gà", "chicken", "gà ta", "gà công nghiệp"],
            "tôm": ["tôm", "shrimp", "tôm sú", "tôm hùm"],
            "rau cải": ["rau cải", "cải", "rau"],
            "khoai tây": ["khoai tây", "potato", "khoai"],
        }
        
        # 🔥 PERFORMANCE: Cache for entity extraction and normalization
        if Settings.ENABLE_AGENT_CACHE:
            self._extract_entity_cached = lru_cache(maxsize=Settings.AGENT_CACHE_SIZE)(self._extract_entity_impl)
            self._normalize_entity_cached = lru_cache(maxsize=Settings.AGENT_CACHE_SIZE)(self._normalize_entity_impl)
        else:
            self._extract_entity_cached = self._extract_entity_impl
            self._normalize_entity_cached = self._normalize_entity_impl
    
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Resolve entity từ query
        """
        query = state.get("query", "").strip()
        sub_queries = state.get("sub_queries", {})
        product_query = sub_queries.get("product_search") or sub_queries.get("product_info") or query
        
        if not product_query:
            state["resolved_entity"] = None
            state["entity_normalized"] = None
            return state
        
        # 🔥 PERFORMANCE: Use cached extraction and normalization
        entity = self._extract_entity_cached(product_query)
        
        # Normalize entity (synonym mapping)
        normalized_entity = self._normalize_entity_cached(entity)
        
        # Validate entity có tồn tại trong DB không (optional - có thể skip nếu SQL fail)
        entity_validated = await self._validate_entity_in_db(normalized_entity)
        
        state.update({
            "resolved_entity": entity,
            "entity_normalized": normalized_entity,
            "entity_validated": entity_validated,
            "entity_query": normalized_entity  # Query đã được normalize để search
        })
        
        self.log(f"✅ Resolved entity: '{entity}' → normalized: '{normalized_entity}' (validated: {entity_validated})")
        
        return state
    
    def _extract_entity_impl(self, query: str) -> str:
        """
        Extract entity (tên sản phẩm) từ query
        """
        if not query:
            return ""
        
        query_lower = query.lower()
        
        # Loại bỏ stopwords
        stopwords = {
            "hình", "ảnh", "hình ảnh", "lấy", "ra", "và", "của", "nó", "theo", "tháng",
            "doanh", "thu", "số", "thống", "kê", "về", "với", "cho", "từ", "đến",
            "sản", "phẩm", "món", "bán", "mua", "tìm", "kiếm"
        }
        
        query_clean = re.sub(r'[^\w\s]', ' ', query_lower)
        words = [w for w in query_clean.split() if w and w not in stopwords and len(w) > 2]
        
        # Tìm cụm từ phổ biến (2-3 từ)
        if len(words) >= 2:
            # Thử cụm 2 từ trước
            for i in range(len(words) - 1):
                phrase = f"{words[i]} {words[i+1]}"
                # Check nếu phrase match với synonym map
                for main_term, synonyms in self.synonym_map.items():
                    if phrase in main_term or main_term in phrase:
                        return main_term
                    if any(phrase in syn or syn in phrase for syn in synonyms):
                        return main_term
                # Nếu không match synonym, trả về phrase
                if len(phrase) >= 4:
                    return phrase
        elif len(words) == 1:
            # Check synonym cho từ đơn
            word = words[0]
            for main_term, synonyms in self.synonym_map.items():
                if word in main_term or main_term in word:
                    return main_term
                if word in synonyms:
                    return main_term
            return word
        
        # Fallback: trả về từ đầu tiên
        return words[0] if words else query.strip()
    
    def _normalize_entity_impl(self, entity: str) -> str:
        """
        Normalize entity bằng synonym map
        """
        if not entity:
            return entity
        
        entity_lower = entity.lower()
        
        # Check synonym map
        for main_term, synonyms in self.synonym_map.items():
            if entity_lower in main_term or main_term in entity_lower:
                return main_term
            if any(entity_lower in syn or syn in entity_lower for syn in synonyms):
                return main_term
        
        return entity
    
    async def _validate_entity_in_db(self, entity: str) -> bool:
        """
        Validate entity có tồn tại trong DB không (optional check)
        Nếu SQL connection fail → return True (assume valid để tiếp tục)
        """
        if not entity:
            return False
        
        try:
            connection_string = Settings.DATABASE_CONNECTION_STRING
            if not connection_string:
                # Không có connection string → assume valid
                return True
            
            import pyodbc
            import asyncio
            
            def check_in_db():
                conn = None
                try:
                    conn = pyodbc.connect(connection_string)
                    cursor = conn.cursor()
                    
                    # Quick check: có sản phẩm nào match không
                    like_pattern = f"%{entity}%"
                    query = """
                        SELECT TOP 1 MaSanPham
                        FROM SanPham
                        WHERE (IsDeleted = 0 OR IsDeleted IS NULL)
                          AND TenSanPham LIKE ?
                    """
                    cursor.execute(query, like_pattern)
                    row = cursor.fetchone()
                    cursor.close()
                    return row is not None
                except Exception as e:
                    logger.warning(f"Error validating entity in DB: {str(e)}")
                    return True  # Assume valid nếu SQL fail
                finally:
                    if conn:
                        conn.close()
            
            result = await asyncio.to_thread(check_in_db)
            return result
            
        except Exception as e:
            logger.warning(f"Error in entity validation: {str(e)}")
            return True  # Assume valid để tiếp tục

