"""
RAG Pipeline - Logic nghiệp vụ chính cho quy trình: query → retrieve → rerank → answer
Pipeline RAG: Xử lý câu hỏi → Tìm kiếm ngữ cảnh → Sắp xếp lại → Trả về kết quả
"""
import logging
from typing import Tuple, List, Dict, Optional

from app.domain.query import Query
from app.domain.answer import Answer, RetrievedChunk
from app.services.embedding import EmbeddingService
from app.services.reranker import RerankerService
from app.infrastructure.vector_store.base import VectorStore

logger = logging.getLogger(__name__)


class RAGPipeline:
    """
    Pipeline RAG chính - Xử lý câu hỏi → Tìm kiếm → Sắp xếp lại → Trả lời
    
    Quy trình:
    1. Tạo embedding cho câu hỏi
    2. Tìm kiếm các chunks liên quan trong vector store
    3. Sắp xếp lại kết quả bằng reranker (nếu có)
    4. Chuyển đổi thành domain objects và xây dựng context
    """
    
    def __init__(
        self,
        embedding_service: EmbeddingService,
        vector_store: VectorStore,
        reranker_service: Optional[RerankerService] = None
    ):
        """
        Khởi tạo RAG Pipeline
        
        Args:
            embedding_service: Service tạo embedding cho text
            vector_store: Vector store để lưu trữ và tìm kiếm
            reranker_service: Service sắp xếp lại kết quả (tùy chọn)
        """
        self.embedding_service = embedding_service
        self.vector_store = vector_store
        self.reranker_service = reranker_service
    
    async def retrieve(self, query: Query) -> Answer:
        """
        Tìm kiếm và trả về ngữ cảnh liên quan từ vector store dựa trên câu hỏi
        
        Args:
            query: Đối tượng Query chứa câu hỏi và tham số
            
        Returns:
            Đối tượng Answer chứa context và danh sách chunks
        """
        try:
            logger.info(f"Đang tìm kiếm ngữ cảnh cho câu hỏi: '{query.question[:100]}...' (top_k={query.top_k}, file_id={query.file_id})")
            
            # Bước 1: Tạo embedding vector cho câu hỏi
            query_embedding = await self.embedding_service.create_embedding(query.question)
            
            if query_embedding is None:
                logger.warning("Không thể tạo embedding cho câu hỏi")
                return Answer(context="", chunks=[], has_context=False)
            
            # Bước 2: Tìm kiếm các chunks tương tự trong vector store
            # Tối ưu: Chỉ lấy nhiều hơn nếu reranker được bật VÀ đã load xong
            use_reranker = (self.reranker_service and 
                          self.reranker_service.use_reranker and
                          hasattr(self.reranker_service, '_model_loaded') and
                          self.reranker_service._model_loaded)
            
            initial_top_k = query.top_k * 2 if use_reranker else query.top_k
            chunk_dicts = await self.vector_store.search_similar(
                query_embedding, 
                top_k=initial_top_k, 
                file_id=query.file_id
            )
            
            if not chunk_dicts:
                logger.warning(f"Không tìm thấy chunks liên quan cho câu hỏi: '{query.question[:100]}...'")
                return Answer(context="", chunks=[], has_context=False)
            
            # Bước 3: Sắp xếp lại kết quả bằng reranker (chỉ khi model đã load)
            if use_reranker and self.reranker_service.model:
                logger.info(f"Đang sắp xếp lại {len(chunk_dicts)} chunks bằng reranker")
                chunk_dicts = await self.reranker_service.rerank(
                    query.question,
                    chunk_dicts,
                    top_k=query.top_k
                )
                logger.info(f"Sau khi sắp xếp lại: {len(chunk_dicts)} chunks")
            
            # Bước 4: Chuyển đổi từ dictionary sang domain objects
            # Tối ưu: Sử dụng rerank_score nếu có, không cần sort lại
            chunks = [
                RetrievedChunk(
                    chunk_id=chunk_dict['chunk_id'],
                    file_id=chunk_dict['file_id'],
                    file_name=chunk_dict['file_name'],
                    chunk_index=chunk_dict['chunk_index'],
                    text=chunk_dict['text'],
                    similarity=chunk_dict.get('rerank_score', chunk_dict.get('similarity', 0))
                )
                for chunk_dict in chunk_dicts
            ]
            
            # Bước 5: Xây dựng chuỗi context từ các chunks (đã được sắp xếp)
            context_parts = ["Thông tin liên quan từ tài liệu:"]
            # Chunks đã được sắp xếp bởi reranker hoặc similarity, không cần sort lại
            for chunk in chunks:
                context_parts.append(f"\n[File: {chunk.file_name}, Chunk {chunk.chunk_index}]")
                context_parts.append(chunk.text)
                context_parts.append("")
            
            context = "\n".join(context_parts)
            
            logger.info(f"Đã tìm thấy {len(chunks)} chunks liên quan, độ dài context: {len(context)} ký tự")
            
            return Answer(context=context, chunks=chunks, has_context=True)
            
        except Exception as e:
            logger.error(f"Lỗi trong RAG pipeline retrieve: {str(e)}", exc_info=True)
            return Answer(context="", chunks=[], has_context=False)

