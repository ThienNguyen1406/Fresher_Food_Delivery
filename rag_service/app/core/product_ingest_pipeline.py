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
            
            # Tạo embeddings cho product
            logger.info(f"🔢 Đang tạo embeddings cho product...")
            embeddings = await self.product_embedding_service.create_product_embeddings(
                product_data,
                image_bytes
            )
            
            # Sử dụng combined embedding (text CLIP + image) để hỗ trợ cả text và image search
            primary_embedding = None
            
            # Tạo text embedding bằng CLIP text encoder (512 dim) từ product name + description
            # QUAN TRỌNG: Enrich text với semantic keywords để embedding chính xác hơn
            from app.api.deps import get_image_embedding_service
            image_embedding_service = get_image_embedding_service()
            
            # Enrich product text với semantic information
            product_text = self._enrich_product_text(product_data, product_name)
            text_clip_embedding = None
            if product_text:
                text_clip_embedding = image_embedding_service.create_text_embedding(product_text)
            
            image_emb = embeddings.get('image_embedding')
            
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
            
            # Tạo DocumentChunk từ product
            chunk = DocumentChunk(
                chunk_id=f"{product_id}-chunk-0",
                file_id=product_id,
                file_name=product_name or f"Product_{product_id}",
                text=f"[Product: {product_name}] {product_data.get('description', '')}",
                chunk_index=0,
                start_index=0,
                end_index=0
            )
            
            # Lưu vào vector store với metadata đầy đủ
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
    
    def _enrich_product_text(self, product_data: Dict, product_name: str) -> str:
        """
        Enrich product text với semantic keywords để embedding chính xác
        Args:
            product_data: Dict chứa thông tin product
            product_name: Tên sản phẩm
            
        Returns:
            Text đã được enrich với semantic keywords
        """
        text_parts = []
        
        # Tên sản phẩm gốc
        if product_name:
            text_parts.append(product_name)
        
        #  Mô tả (nếu có)
        description = product_data.get('description', '')
        if description:
            text_parts.append(description)
        
        # Category name (quan trọng để phân biệt category)
        category_name = product_data.get('category_name', '')
        if category_name:
            text_parts.append(category_name)
        
        #  Thêm semantic keywords dựa trên category và product name
        # Điều này giúp phân biệt rõ các loại sản phẩm khác nhau
        semantic_keywords = self._extract_semantic_keywords(product_name, category_name, description)
        if semantic_keywords:
            text_parts.extend(semantic_keywords)
        
        #  Origin và Unit (nếu có)
        origin = product_data.get('origin', '')
        if origin:
            text_parts.append(f"from {origin}")
        
        unit = product_data.get('unit', '')
        if unit:
            text_parts.append(f"unit {unit}")
        
        return " ".join(text_parts)
    
    def _extract_semantic_keywords(self, product_name: str, category_name: str, description: str) -> List[str]:
        """
        Extract semantic keywords từ product name và category
        Để giúp embedding phân biệt rõ các loại sản phẩm
        """
        keywords = []
        product_lower = product_name.lower()
        category_lower = category_name.lower() if category_name else ""
        desc_lower = description.lower() if description else ""
        
        # Keywords dựa trên category
        if "đồ uống" in category_lower or "drink" in category_lower or "beverage" in category_lower:
            keywords.extend(["drink", "beverage", "liquid"])
            if "sữa" in product_lower or "milk" in product_lower:
                keywords.extend(["milk", "dairy", "carton", "bottle"])
            if "nước" in product_lower or "water" in product_lower:
                keywords.extend(["water", "mineral", "bottled"])
            if "milo" in product_lower or "ovaltine" in product_lower or "cacao" in product_lower:
                keywords.extend(["chocolate", "malt", "powder", "instant"])
        
        if "thịt" in category_lower or "meat" in category_lower:
            keywords.extend(["meat", "protein", "fresh", "raw", "food"])
            if "bò" in product_lower or "beef" in product_lower:
                keywords.extend(["beef", "cow", "red meat"])
            if "heo" in product_lower or "pork" in product_lower:
                keywords.extend(["pork", "pig"])
            if "gà" in product_lower or "chicken" in product_lower:
                keywords.extend(["chicken", "poultry"])
        
        if "rau" in category_lower or "vegetable" in category_lower:
            keywords.extend(["vegetable", "fresh", "green", "produce"])
        
        if "trái cây" in category_lower or "fruit" in category_lower:
            keywords.extend(["fruit", "fresh", "sweet", "produce"])
        
        if "cá" in category_lower or "fish" in category_lower:
            keywords.extend(["fish", "seafood", "protein", "fresh"])
        
        # Keywords dựa trên product name
        if "milo" in product_lower:
            keywords.extend(["nestlé", "chocolate", "malt", "milk", "drink", "carton"])
        if "nước suối" in product_lower or "mineral water" in product_lower:
            keywords.extend(["water", "mineral", "bottled", "pure"])
        if "thịt bò" in product_lower or "beef" in product_lower:
            keywords.extend(["beef", "cow", "red meat", "protein"])
        if "sữa" in product_lower and "milo" not in product_lower:
            keywords.extend(["milk", "dairy", "white", "liquid"])
        
        # Keywords từ description nếu có
        if "chocolate" in desc_lower:
            keywords.append("chocolate")
        if "malt" in desc_lower:
            keywords.append("malt")
        if "carton" in desc_lower or "hộp" in desc_lower:
            keywords.append("carton")
        if "bottle" in desc_lower or "chai" in desc_lower:
            keywords.append("bottle")
        
        # Loại bỏ duplicates và trả về
        return list(set(keywords))

