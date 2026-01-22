"""
Ingest Pipeline - Logic nghiệp vụ chính cho quy trình: File → chunks → vector
Pipeline xử lý tài liệu: Đọc file → Chia nhỏ thành chunks → Tạo embedding → Lưu vào vector store
"""
import logging
import uuid
from typing import List, Optional
from datetime import datetime

from app.domain.document import DocumentChunk
from app.services.document import DocumentProcessor
from app.services.embedding import EmbeddingService
from app.infrastructure.vector_store.base import VectorStore

logger = logging.getLogger(__name__)


class IngestPipeline:
    """
    Pipeline xử lý tài liệu chính - File → Chunks → Vector
    
    Quy trình:
    1. Đọc và trích xuất text từ file
    2. Chia nhỏ text thành các chunks
    3. Tạo embedding vectors cho các chunks
    4. Lưu chunks và embeddings vào vector store
    """
    
    def __init__(
        self,
        document_processor: DocumentProcessor,
        embedding_service: EmbeddingService,
        vector_store: VectorStore
    ):
        """
        Khởi tạo Ingest Pipeline
        
        Args:
            document_processor: Service xử lý và trích xuất text từ file
            embedding_service: Service tạo embedding vectors
            vector_store: Vector store để lưu trữ
        """
        self.document_processor = document_processor
        self.embedding_service = embedding_service
        self.vector_store = vector_store
    
    async def process_and_store(
        self, 
        file_content: bytes, 
        file_name: str,
        file_id: Optional[str] = None
    ) -> str:
        """
        Xử lý file và lưu vào vector store
        
        Args:
            file_content: Nội dung file dưới dạng bytes
            file_name: Tên file
            file_id: ID file (tùy chọn, sẽ tự tạo nếu không có)
            
        Returns:
            file_id của file đã xử lý
        """
        # Tạo file_id nếu chưa có
        if not file_id:
            file_id = f"DOC-{str(uuid.uuid4())[:8]}"
        
        try:
            logger.info(f"🚀 Bắt đầu xử lý tài liệu: {file_name} (ID: {file_id})")
            
            # Bước 1: Trích xuất text và chia nhỏ thành chunks
            logger.info(f"📄 Bước 1/3: Đang trích xuất text và chia nhỏ thành chunks...")
            chunks = await self.document_processor.process_document(
                file_content, 
                file_name, 
                file_id
            )
            
            if not chunks:
                raise ValueError("Không thể trích xuất text từ tài liệu")
            
            logger.info(f"✅ Đã tạo {len(chunks)} chunks từ tài liệu")
            
            # Bước 2: Tạo embedding vectors cho các chunks
            logger.info(f"🔢 Bước 2/3: Đang tạo embeddings cho {len(chunks)} chunks...")
            texts = [chunk.text for chunk in chunks]
            embeddings = await self.embedding_service.create_embeddings(texts)
            
            # Lọc bỏ các embeddings None (lỗi khi tạo)
            valid_chunks = []
            valid_embeddings = []
            for chunk, emb in zip(chunks, embeddings):
                if emb is not None:
                    valid_chunks.append(chunk)
                    valid_embeddings.append(emb)
            
            if not valid_chunks:
                raise ValueError("Không thể tạo embeddings cho tài liệu")
            
            logger.info(f"✅ Đã tạo {len(valid_embeddings)} embeddings thành công ({len(chunks) - len(valid_chunks)} lỗi)")
            
            # Bước 3: Lưu chunks và embeddings vào vector store
            logger.info(f"💾 Bước 3/3: Đang lưu {len(valid_chunks)} chunks vào vector store...")
            file_type = file_name.split('.')[-1] if '.' in file_name else ""
            upload_date = datetime.now().isoformat()
            
            await self.vector_store.save_chunks(
                valid_chunks, 
                valid_embeddings, 
                file_type, 
                upload_date
            )
            
            logger.info(f"✅ Đã xử lý và lưu thành công tài liệu {file_name} với {len(valid_chunks)} chunks")
            
            return file_id
            
        except Exception as e:
            logger.error(f"❌ Lỗi khi xử lý tài liệu {file_name}: {str(e)}", exc_info=True)
            raise

