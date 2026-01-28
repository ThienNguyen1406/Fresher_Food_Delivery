"""
Product Ingest Pipeline - Xử lý product và lưu vào vector store theo category
Pipeline: Product (Text + Image) → Embeddings → Vector Database (theo category)
"""
import logging
import uuid
from datetime import datetime
from typing import Optional, List, Dict
import numpy as np

from app.services.product import ProductEmbeddingService
from app.infrastructure.vector_store.image_vector_store import ImageVectorStore
from app.domain.document import DocumentChunk

logger = logging.getLogger(__name__)


class ProductIngestPipeline:
    """
    Pipeline xử lý product và lưu vào vector store theo category
    
    Quy trình:
    1. Nhận product data (text + image)
    2. Tạo embeddings: image, text, combined
    3. Lưu vào Vector Database với metadata: category_id, product_id
    """
    
    def __init__(
        self,
        product_embedding_service: ProductEmbeddingService,
        vector_store: ImageVectorStore
    ):
        """
        Khởi tạo Product Ingest Pipeline
        
        Args:
            product_embedding_service: Service tạo embeddings cho product
            vector_store: Vector store để lưu embeddings
        """
        self.product_embedding_service = product_embedding_service
        self.vector_store = vector_store
    
    async def process_and_store(
        self,
        product_data: Dict,
        image_bytes: Optional[bytes] = None,
        product_id: Optional[str] = None
    ) -> str:
        """
        Xử lý product và lưu vào vector store
        
        Args:
            product_data: Dict chứa thông tin product
                - product_name: Tên sản phẩm
                - description: Mô tả
                - category_id: ID category
                - category_name: Tên category
                - price: Giá
                - etc.
            image_bytes: Ảnh sản phẩm (tùy chọn)
            product_id: ID sản phẩm (tùy chọn, sẽ lấy từ product_data nếu có)
            
        Returns:
            product_id của sản phẩm đã xử lý
        """
        # Lấy product_id
        if not product_id:
            product_id = product_data.get('product_id') or f"PROD-{str(uuid.uuid4())[:8]}"
        
        category_id = product_data.get('category_id', '')
        category_name = product_data.get('category_name', '')
        product_name = product_data.get('product_name', '')
        
        try:
            logger.info(f"🛍️  Bắt đầu xử lý product: {product_name} (ID: {product_id}, Category: {category_id})")
            
            # Bước 1: Tạo embeddings cho product
            logger.info(f"🔢 Đang tạo embeddings cho product...")
            embeddings = await self.product_embedding_service.create_product_embeddings(
                product_data,
                image_bytes
            )
            
            # Sử dụng combined embedding (text CLIP + image) để hỗ trợ cả text và image search
            # Strategy: Tạo text embedding bằng CLIP text encoder (512 dim) + image embedding (512 dim)
            # Weighted average: 60% text, 40% image (có thể điều chỉnh)
            primary_embedding = None
            
            # Tạo text embedding bằng CLIP text encoder (512 dim) từ product name + description
            from app.api.deps import get_image_embedding_service
            image_embedding_service = get_image_embedding_service()
            
            product_text = f"{product_name} {product_data.get('description', '')}".strip()
            text_clip_embedding = None
            if product_text:
                text_clip_embedding = image_embedding_service.create_text_embedding(product_text)
            
            image_emb = embeddings.get('image_embedding')
            
            # Combine: 70% text CLIP, 30% image (nếu có cả 2)
            # Tăng weight của text để text search tốt hơn
            if text_clip_embedding is not None and image_emb is not None:
                # Normalize cả 2
                text_norm = text_clip_embedding / (np.linalg.norm(text_clip_embedding) + 1e-8)
                img_norm = image_emb / (np.linalg.norm(image_emb) + 1e-8)
                # Weighted average: 70% text, 30% image (tăng weight text để text search tốt hơn)
                primary_embedding = 0.7 * text_norm + 0.3 * img_norm
                logger.info(f"✅ Sử dụng combined embedding (70% text CLIP + 30% image, dimension: {len(primary_embedding)})")
            elif text_clip_embedding is not None:
                # Chỉ có text, dùng text CLIP embedding
                primary_embedding = text_clip_embedding
                logger.info(f"✅ Sử dụng text CLIP embedding (dimension: {len(primary_embedding)})")
            elif image_emb is not None:
                # Chỉ có image, dùng image embedding
                primary_embedding = image_emb
                logger.info(f"✅ Sử dụng image embedding (dimension: {len(primary_embedding)})")
            else:
                logger.warning("⚠️  Product không có text và image, không thể tạo embedding")
            
            if primary_embedding is None:
                raise ValueError("Không thể tạo embedding cho product")
            
            # Bước 2: Tạo DocumentChunk từ product
            chunk = DocumentChunk(
                chunk_id=f"{product_id}-chunk-0",
                file_id=product_id,
                file_name=product_name or f"Product_{product_id}",
                text=f"[Product: {product_name}] {product_data.get('description', '')}",
                chunk_index=0,
                start_index=0,
                end_index=0
            )
            
            # Bước 3: Lưu vào vector store với metadata đầy đủ
            logger.info(f"💾 Đang lưu product vào vector store...")
            upload_date = datetime.now().isoformat()
            
            # Lấy image filename từ product_data nếu có (từ database khi embed)
            image_filename = product_data.get('image_filename') or product_data.get('anh')
            
            # Metadata cho product
            # Convert price to float (ChromaDB doesn't accept Decimal)
            price_value = product_data.get('price', '')
            if price_value:
                try:
                    price_float = float(price_value)
                except (ValueError, TypeError):
                    price_float = 0.0
            else:
                price_float = 0.0
            
            extra_metadata = [{
                "product_id": product_id,
                "product_name": product_name,
                "category_id": category_id,
                "category_name": category_name,
                "content_type": "product",
                "price": price_float,  # Convert to float for ChromaDB
                "description": product_data.get('description', '')[:200] if product_data.get('description') else '',  # Limit length
                "image_filename": image_filename if image_filename else '',  # Lưu image filename để dùng sau
            }]
            
            await self.vector_store.save_chunks(
                [chunk],
                [primary_embedding],
                file_type="product",
                upload_date=upload_date,
                extra_metadata=extra_metadata
            )
            
            logger.info(f"✅ Đã xử lý và lưu thành công product {product_name} (Category: {category_id})")
            
            return product_id
            
        except Exception as e:
            logger.error(f"❌ Lỗi khi xử lý product {product_name}: {str(e)}", exc_info=True)
            raise
    
    async def process_and_store_batch(
        self,
        products: List[Dict],
        images: Optional[List[bytes]] = None
    ) -> List[str]:
        """
        Xử lý nhiều products cùng lúc (batch)
        
        Args:
            products: Danh sách product data
            images: Danh sách ảnh tương ứng (tùy chọn)
            
        Returns:
            Danh sách product_id đã xử lý
        """
        if not products:
            return []
        
        try:
            logger.info(f"🛍️  Bắt đầu xử lý batch {len(products)} products...")
            
            product_ids = []
            chunks = []
            embeddings_list = []
            upload_date = datetime.now().isoformat()
            
            for i, product_data in enumerate(products):
                product_id = product_data.get('product_id') or f"PROD-{str(uuid.uuid4())[:8]}"
                image_bytes = images[i] if images and i < len(images) else None
                
                # Tạo embeddings
                embeddings = await self.product_embedding_service.create_product_embeddings(
                    product_data,
                    image_bytes
                )
                
                # Sử dụng image embedding
                primary_embedding = embeddings.get('image_embedding')
                if primary_embedding is None:
                    primary_embedding = embeddings.get('combined_embedding')
                
                if primary_embedding is None:
                    logger.warning(f"Skipping product {product_id}: không có embedding")
                    continue
                
                # Tạo chunk
                product_name = product_data.get('product_name', '')
                chunk = DocumentChunk(
                    chunk_id=f"{product_id}-chunk-0",
                    file_id=product_id,
                    file_name=product_name or f"Product_{product_id}",
                    text=f"[Product: {product_name}] {product_data.get('description', '')}",
                    chunk_index=0,
                    start_index=0,
                    end_index=0
                )
                
                chunks.append(chunk)
                embeddings_list.append(primary_embedding)
                product_ids.append(product_id)
            
            # Lưu tất cả cùng lúc
            if chunks:
                # Tạo extra metadata cho từng product
                extra_metadata_list = []
                for i, product_data in enumerate(products):
                    if i < len(product_ids):
                        extra_metadata_list.append({
                            "product_id": product_ids[i],
                            "product_name": product_data.get('product_name', ''),
                            "category_id": product_data.get('category_id', ''),
                            "category_name": product_data.get('category_name', ''),
                            "content_type": "product",
                            "price": str(product_data.get('price', '')),
                            "description": product_data.get('description', '')[:200] if product_data.get('description') else '',
                        })
                
                await self.vector_store.save_chunks(
                    chunks,
                    embeddings_list,
                    file_type="product",
                    upload_date=upload_date,
                    extra_metadata=extra_metadata_list
                )
            
            logger.info(f"✅ Đã xử lý và lưu thành công {len(product_ids)} products")
            
            return product_ids
            
        except Exception as e:
            logger.error(f"❌ Lỗi khi xử lý batch products: {str(e)}", exc_info=True)
            raise

