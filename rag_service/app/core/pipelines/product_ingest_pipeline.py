"""
Product Ingest Pipeline - Xử lý product và lưu vào vector store theo category
Pipeline: Product (Text + Image) → Embeddings → Vector Database (theo category)
"""
import logging
import uuid
from datetime import datetime
from typing import Optional, List, Dict

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
            
            # 🔥 TỐI ƯU: Bước 1 - Tạo embeddings cho product
            # ProductEmbeddingService đã trả primary_embedding đã normalize + combine
            # Pipeline KHÔNG gọi model nữa, chỉ dùng kết quả
            logger.info(f"🔢 Đang tạo embeddings cho product...")
            embeddings = await self.product_embedding_service.create_product_embeddings(
                product_data,
                image_bytes
            )
            
            # 🔥 Lấy primary_embedding đã được normalize + combine (70% text CLIP + 30% image)
            primary_embedding = embeddings.get('primary_embedding')
            
            if primary_embedding is None:
                raise ValueError("Không thể tạo embedding cho product")
            
            logger.info(f"✅ Đã tạo primary embedding (dimension: {len(primary_embedding)})")
            
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
            
            # 🔥 TỐI ƯU: Metadata chỉ chứa filter keys, không chứa content
            # product_name, description → lấy từ SQL khi trả kết quả
            # Giảm RAM vector store, thời gian serialize/deserialize, query latency
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
                "category_id": category_id,
                "content_type": "product",
                "price": price_float,
                "has_image": bool(image_filename),  # Chỉ lưu boolean, không lưu filename
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
            
            # 🔥 TỐI ƯU: Batch embedding thật - không loop từng product
            # Tạo embeddings cho tất cả products cùng lúc
            image_list = []
            for i in range(len(products)):
                if images and i < len(images):
                    image_list.append(images[i])
                else:
                    image_list.append(None)
            
            # Batch embed tất cả products
            embeddings_batch = await self.product_embedding_service.create_embeddings_batch(
                products,
                image_list
            )
            
            # Tạo chunks và lấy primary_embeddings
            for i, product_data in enumerate(products):
                product_id = product_data.get('product_id') or f"PROD-{str(uuid.uuid4())[:8]}"
                embeddings = embeddings_batch[i] if i < len(embeddings_batch) else {}
                
                primary_embedding = embeddings.get('primary_embedding')
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
                # 🔥 TỐI ƯU: Metadata chỉ chứa filter keys
                extra_metadata_list = []
                for i, product_data in enumerate(products):
                    if i < len(product_ids):
                        price_value = product_data.get('price', '')
                        try:
                            price_float = float(price_value) if price_value else 0.0
                        except (ValueError, TypeError):
                            price_float = 0.0
                        
                        image_filename = product_data.get('image_filename') or product_data.get('anh')
                        extra_metadata_list.append({
                            "product_id": product_ids[i],
                            "category_id": product_data.get('category_id', ''),
                            "content_type": "product",
                            "price": price_float,
                            "has_image": bool(image_filename),
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
    

