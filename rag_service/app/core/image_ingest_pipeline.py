"""
Image Ingest Pipeline - Xử lý ảnh và lưu vào vector store
Pipeline: Image → Image Encoder → Embedding Vector → Vector Database
"""
import logging
import uuid
from datetime import datetime
from typing import Optional, List
import numpy as np

from app.services.image import ImageEmbeddingService
from app.infrastructure.vector_store.base import VectorStore
from app.domain.document import DocumentChunk

logger = logging.getLogger(__name__)


class ImageIngestPipeline:
    """
    Pipeline xử lý ảnh và lưu vào vector store
    """
    
    def __init__(
        self,
        image_embedding_service: ImageEmbeddingService,
        vector_store: VectorStore
    ):
        """
        Khởi tạo Image Ingest Pipeline
        """
        self.image_embedding_service = image_embedding_service
        self.vector_store = vector_store
    
    async def process_and_store(
        self, 
        image_bytes: bytes, 
        image_name: str,
        image_id: Optional[str] = None,
        metadata: Optional[dict] = None
    ) -> str:
        """
        Xử lý ảnh và lưu vào vector store
        
        Args:
            image_bytes: Ảnh dưới dạng bytes
            image_name: Tên file ảnh
            image_id: ID ảnh (tùy chọn, sẽ tự tạo nếu không có)
            metadata: Metadata bổ sung (tùy chọn)
            
        Returns:
            image_id của ảnh đã xử lý
        """
        # Tạo image_id nếu chưa có
        if not image_id:
            image_id = f"IMG-{str(uuid.uuid4())[:8]}"
        
        try:
            logger.info(f"🖼️  Bắt đầu xử lý ảnh: {image_name} (ID: {image_id})")
            
            # Bước 1: Tạo embedding vector từ ảnh
            logger.info(f"Đang tạo embedding vector từ ảnh...")
            embedding = await self.image_embedding_service.create_embedding(image_bytes)
            
            if embedding is None:
                raise ValueError("Không thể tạo embedding từ ảnh")
            
            logger.info(f"✅ Đã tạo embedding vector (dimension: {len(embedding)})")
            
            # Bước 2: Tạo DocumentChunk từ ảnh (để tương thích với vector store)
            # Ảnh không có text, nhưng vẫn cần chunk để lưu metadata
            chunk = DocumentChunk(
                chunk_id=f"{image_id}-chunk-0",
                file_id=image_id,
                file_name=image_name,
                text=f"[Image: {image_name}]",  # Placeholder text
                chunk_index=0,
                start_index=0,
                end_index=0
            )
            
            # Bước 3: Lưu vào vector store
            logger.info(f" Đang lưu embedding vào vector store...")
            file_type = image_name.split('.')[-1] if '.' in image_name else "image"
            upload_date = datetime.now().isoformat()
            
            # Merge metadata
            chunk_metadata = metadata or {}
            chunk_metadata.update({
                "image_id": image_id,
                "image_name": image_name,
                "file_type": file_type,
                "upload_date": upload_date,
                "content_type": "image"
            })
            
            await self.vector_store.save_chunks(
                [chunk], 
                [embedding], 
                file_type, 
                upload_date
            )
            
            logger.info(f"✅ Đã xử lý và lưu thành công ảnh {image_name} với embedding vector")
            
            return image_id
            
        except Exception as e:
            logger.error(f"❌ Lỗi khi xử lý ảnh {image_name}: {str(e)}", exc_info=True)
            raise
    
    async def process_and_store_batch(
        self,
        images: List[bytes],
        image_names: List[str],
        image_ids: Optional[List[str]] = None,
        metadata_list: Optional[List[dict]] = None
    ) -> List[str]:
        """
        Xử lý nhiều ảnh cùng lúc (batch)  
        Returns:
            Danh sách image_id đã xử lý
        """
        if not images or not image_names:
            return []
        
        if len(images) != len(image_names):
            raise ValueError("Số lượng ảnh và tên file phải bằng nhau")
        
        # Tạo image_ids nếu chưa có
        if not image_ids:
            image_ids = [f"IMG-{str(uuid.uuid4())[:8]}" for _ in images]
        
        try:
            logger.info(f"🖼️  Bắt đầu xử lý batch {len(images)} ảnh...")
            
            # Bước 1: Tạo embeddings cho tất cả ảnh
            logger.info(f"🔢  Đang tạo embeddings cho {len(images)} ảnh...")
            embeddings = await self.image_embedding_service.create_embeddings(images)
            
            # Filter valid embeddings
            valid_data = []
            for i, (img_bytes, img_name, img_id, emb) in enumerate(
                zip(images, image_names, image_ids, embeddings)
            ):
                if emb is not None:
                    metadata = (metadata_list[i] if metadata_list and i < len(metadata_list) else {}) or {}
                    valid_data.append((img_id, img_name, emb, metadata))
            
            if not valid_data:
                raise ValueError("Không thể tạo embeddings cho bất kỳ ảnh nào")
            
            logger.info(f"✅ Đã tạo {len(valid_data)}/{len(images)} embeddings thành công")
            
            # Bước 2: Tạo chunks và lưu vào vector store
            logger.info(f"💾 Đang lưu {len(valid_data)} embeddings vào vector store...")
            
            chunks = []
            embeddings_list = []
            upload_date = datetime.now().isoformat()
            
            for img_id, img_name, emb, metadata in valid_data:
                file_type = img_name.split('.')[-1] if '.' in img_name else "image"
                
                chunk = DocumentChunk(
                    chunk_id=f"{img_id}-chunk-0",
                    file_id=img_id,
                    file_name=img_name,
                    text=f"[Image: {img_name}]",
                    chunk_index=0,
                    start_index=0,
                    end_index=0
                )
                
                chunks.append(chunk)
                embeddings_list.append(emb)
            
            # Lưu tất cả cùng lúc
            if chunks:
                file_type = "image"
                await self.vector_store.save_chunks(
                    chunks,
                    embeddings_list,
                    file_type,
                    upload_date
                )
            
            logger.info(f"✅ Đã xử lý và lưu thành công {len(valid_data)} ảnh")
            
            return [img_id for img_id, _, _, _ in valid_data]
            
        except Exception as e:
            logger.error(f"❌ Lỗi khi xử lý batch ảnh: {str(e)}", exc_info=True)
            raise

