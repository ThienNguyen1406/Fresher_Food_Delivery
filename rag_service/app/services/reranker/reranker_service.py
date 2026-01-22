"""
Reranker Service - Service sắp xếp lại các chunks đã tìm được để cải thiện độ liên quan
Khuyến nghị: bge-reranker
"""
import logging
from typing import List, Dict
import numpy as np

from app.core.settings import Settings

logger = logging.getLogger(__name__)


class RerankerService:
    """
    Service sắp xếp lại kết quả tìm kiếm
    
    Reranker giúp cải thiện độ chính xác của kết quả bằng cách:
    - Đánh giá lại độ liên quan giữa query và từng chunk
    - Sắp xếp lại theo điểm số relevance
    - Trả về các chunks có độ liên quan cao nhất
    """
    
    def __init__(self):
        """Khởi tạo Reranker Service - Lazy loading để tránh tải model khi không cần"""
        self.use_reranker = Settings.USE_RERANKER
        self.model = None
        self._model_loaded = False
        # KHÔNG load model ngay trong __init__ để tránh chậm khi khởi động service
    
    def _ensure_model_loaded(self):
        """Lazy load model reranker chỉ khi thực sự cần sử dụng"""
        if self._model_loaded:
            return
        
        if not self.use_reranker:
            return
        
        try:
            from sentence_transformers import CrossEncoder
            model_name = Settings.RERANKER_MODEL
            logger.info(f"Đang tải reranker model: {model_name} (lần đầu tiên, có thể mất vài phút)...")
            self.model = CrossEncoder(model_name)
            self._model_loaded = True
            logger.info(f"✅ Reranker đã tải xong: {model_name}")
        except ImportError:
            logger.warning("sentence-transformers chưa được cài đặt. Reranker bị tắt.")
            self.use_reranker = False
            self._model_loaded = True  # Đánh dấu đã thử load để không thử lại
        except Exception as e:
            logger.error(f"Lỗi khi tải reranker: {str(e)}")
            self.use_reranker = False
            self._model_loaded = True
    
    async def rerank(
        self, 
        query: str, 
        chunks: List[Dict],
        top_k: int = None
    ) -> List[Dict]:
        """
        Sắp xếp lại các chunks dựa trên độ liên quan với query
        
        Args:
            query: Câu hỏi của người dùng
            chunks: Danh sách các chunk dictionaries (phải có key 'text')
            top_k: Số lượng chunks top để trả về (None = trả về tất cả)
            
        Returns:
            Danh sách chunks đã được sắp xếp lại theo độ liên quan
        """
        # Nếu reranker không được bật hoặc không có chunks, trả về nguyên bản
        if not self.use_reranker or not chunks:
            return chunks
        
        # Lazy load model chỉ khi thực sự cần
        self._ensure_model_loaded()
        
        if not self.model:
            return chunks
        
        try:
            # Chuẩn bị các cặp [query, chunk_text] để đánh giá
            pairs = [[query, chunk.get('text', '')] for chunk in chunks]
            
            # Tính điểm relevance cho từng cặp
            scores = self.model.predict(pairs)
            
            # Thêm điểm rerank vào mỗi chunk
            for i, chunk in enumerate(chunks):
                chunk['rerank_score'] = float(scores[i])
            
            # Sắp xếp theo điểm rerank giảm dần (chunks liên quan nhất ở đầu)
            reranked = sorted(chunks, key=lambda x: x.get('rerank_score', 0), reverse=True)
            
            # Trả về top_k chunks nếu được chỉ định
            if top_k is not None and top_k > 0:
                return reranked[:top_k]
            
            return reranked
            
        except Exception as e:
            logger.error(f"Lỗi khi sắp xếp lại: {str(e)}")
            return chunks  # Trả về chunks gốc nếu có lỗi

