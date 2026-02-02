import logging
from typing import Optional, List, Dict
import numpy as np

from app.services.image import ImageEmbeddingService
from app.services.embedding import EmbeddingService

logger = logging.getLogger(__name__)


class ProductEmbeddingService:
    """
        Tạo embedding vectors cho products
    """
    
    def __init__(
        self,
        image_embedding_service: ImageEmbeddingService,
        text_embedding_service: EmbeddingService
    ):
        """
        Khởi tạo Product Embedding Service
        """
        self.image_embedding_service = image_embedding_service
        self.text_embedding_service = text_embedding_service
    
    async def create_image_embedding(self, image_bytes: bytes) -> Optional[np.ndarray]:
        """
        Tạo image embedding từ ảnh sản phẩm
        Image embedding vector (512 dimensions - CLIP)
        """
        return await self.image_embedding_service.create_embedding(image_bytes)
    
    async def create_text_embedding(self, text: str) -> Optional[np.ndarray]:
        """
        Tạo text embedding từ text sản phẩm (tên, mô tả)    
        Returns:
            Text embedding vector (3072 dimensions - OpenAI hoặc 384 - Sentence Transformer)
        """
        if not text or not text.strip():
            return None
        return await self.text_embedding_service.create_embedding(text)
    
    async def create_combined_embedding(
        self,
        text: str,
        image_bytes: Optional[bytes] = None
    ) -> Optional[np.ndarray]:
        """
        Tạo combined embedding từ text + image      
        Returns:
            Combined embedding vector
        """
        embeddings = []
        
        # Text embedding
        if text and text.strip():
            text_emb = await self.create_text_embedding(text)
            if text_emb is not None:
                # Normalize text embedding
                text_emb_norm = text_emb / (np.linalg.norm(text_emb) + 1e-8)
                embeddings.append(('text', text_emb_norm))
        
        # Image embedding
        if image_bytes:
            img_emb = await self.create_image_embedding(image_bytes)
            if img_emb is not None:
                # Normalize image embedding
                img_emb_norm = img_emb / (np.linalg.norm(img_emb) + 1e-8)
                embeddings.append(('image', img_emb_norm))
        
        if not embeddings:
            return None
        
        # Strategy: Weighted average (có thể điều chỉnh weights)
        # Text: 0.6, Image: 0.4 (có thể điều chỉnh)
        if len(embeddings) == 2:
            # Có cả text và image
            text_emb = embeddings[0][1]
            img_emb = embeddings[1][1]
            
            # Resize để cùng dimension (lấy min dimension)
            min_dim = min(len(text_emb), len(img_emb))
            text_emb_resized = text_emb[:min_dim]
            img_emb_resized = img_emb[:min_dim]
            
            # Weighted average
            combined = 0.6 * text_emb_resized + 0.4 * img_emb_resized
            return combined.astype(np.float32)
        else:
            # Chỉ có một loại embedding
            return embeddings[0][1].astype(np.float32)
    
    def _normalize(self, v: np.ndarray) -> np.ndarray:
        """
        Normalize vector (helper function)  
        Returns:
            Normalized vector
        """
        norm = np.linalg.norm(v)
        if norm < 1e-8:
            return v
        return v / norm
    
    async def create_product_embeddings(
        self,
        product_data: Dict,
        image_bytes: Optional[bytes] = None
    ) -> Dict[str, Optional[np.ndarray]]:
        """
         Tạo embeddings cho một product 
        """
        # Tạo text từ product data - ENRICH với thông tin chi tiết
        product_name = product_data.get('product_name', '')
        description = product_data.get('description', '')
        category_name = product_data.get('category_name', '')
        origin = product_data.get('origin', '')
        unit = product_data.get('unit', '')
        
        # ENRICH: Tạo text mô tả chi tiết hơn
        text_parts = []
        if product_name:
            text_parts.append(product_name)
        if description:
            text_parts.append(description)
        if origin:
            text_parts.append(f"Origin: {origin}")
        if unit:
            text_parts.append(f"Unit: {unit}")
        if category_name:
            text_parts.append(f"Category: {category_name}")
        
        text = " ".join(text_parts)
        
        # Tạo embeddings song song (nếu có cả text và image)
        results = {}
        
        # Image embedding (CLIP - 512 dim)
        image_emb = None
        if image_bytes:
            image_emb = await self.create_image_embedding(image_bytes)
            results['image_embedding'] = image_emb
        
        text_clip_emb = None
        if text:
            # 🔥 Dùng CLIP text encoder (từ image_embedding_service) để tương thích với image embedding
            text_clip_emb = self.image_embedding_service.create_text_embedding(text)
            results['text_embedding'] = text_clip_emb
        
        primary_embedding = None
        
        if text_clip_emb is not None and image_emb is not None:
            # Có cả text và image → combine với weight
            text_norm = self._normalize(text_clip_emb)
            img_norm = self._normalize(image_emb)
            primary_embedding = 0.7 * text_norm + 0.3 * img_norm
            # Normalize lại sau khi combine
            primary_embedding = self._normalize(primary_embedding)
            logger.debug(f"✅ Combined embedding (70% text CLIP + 30% image, dim: {len(primary_embedding)})")
        elif text_clip_emb is not None:
            # Chỉ có text → dùng text CLIP (đã normalize trong CLIP model)
            primary_embedding = self._normalize(text_clip_emb)
            logger.debug(f"✅ Text CLIP embedding (dim: {len(primary_embedding)})")
        elif image_emb is not None:
            # Chỉ có image → dùng image (đã normalize trong CLIP model)
            primary_embedding = self._normalize(image_emb)
            logger.debug(f"✅ Image embedding (dim: {len(primary_embedding)})")
        
        results['primary_embedding'] = primary_embedding
        
        return results
    
    async def create_embeddings_batch(
        self,
        products: List[Dict],
        images: Optional[List[bytes]] = None
    ) -> List[Dict[str, Optional[np.ndarray]]]:
        """
         Tạo embeddings cho nhiều products cùng lúc 
        """
        if not products:
            return []
        
        # Chuẩn bị texts và images cho batch
        texts = []
        image_list = []
        
        for i, product_data in enumerate(products):
            # Tạo text từ product data
            product_name = product_data.get('product_name', '')
            description = product_data.get('description', '')
            category_name = product_data.get('category_name', '')
            origin = product_data.get('origin', '')
            unit = product_data.get('unit', '')
            
            text_parts = []
            if product_name:
                text_parts.append(product_name)
            if description:
                text_parts.append(description)
            if origin:
                text_parts.append(f"Origin: {origin}")
            if unit:
                text_parts.append(f"Unit: {unit}")
            if category_name:
                text_parts.append(f"Category: {category_name}")
            
            text = " ".join(text_parts)
            texts.append(text if text else "")
            
            # Lấy image tương ứng
            if images and i < len(images) and images[i]:
                image_list.append(images[i])
            else:
                image_list.append(None)
        
        # Batch embed texts (CLIP text encoder)
        text_embeddings = []
        valid_texts = [(i, t) for i, t in enumerate(texts) if t]
        if valid_texts:
            # Batch process texts với CLIP text encoder
            # CLIP text encoder có thể batch, nhưng hiện tại chỉ có single text method
            # TODO: Optimize để batch thật nếu CLIP hỗ trợ
            for idx, text in valid_texts:
                text_emb = self.image_embedding_service.create_text_embedding(text)
                text_embeddings.append((idx, text_emb))
        
        # Batch embed images (CLIP)
        image_embeddings = []
        valid_images = [(i, img) for i, img in enumerate(image_list) if img]
        if valid_images:
            image_bytes_list = [img for _, img in valid_images]
            # Batch process images với CLIP
            batch_image_embs = await self.image_embedding_service.create_embeddings(image_bytes_list)
            for idx, (orig_idx, _) in enumerate(valid_images):
                if idx < len(batch_image_embs) and batch_image_embs[idx] is not None:
                    image_embeddings.append((orig_idx, batch_image_embs[idx]))
        
        # Combine embeddings cho từng product
        results = []
        text_emb_dict = {idx: emb for idx, emb in text_embeddings}
        image_emb_dict = {idx: emb for idx, emb in image_embeddings}
        
        for i in range(len(products)):
            text_clip_emb = text_emb_dict.get(i)
            image_emb = image_emb_dict.get(i)
            
            result = {
                'text_embedding': text_clip_emb,
                'image_embedding': image_emb,
                'primary_embedding': None
            }
            
            # Tạo primary_embedding (70% text CLIP + 30% image)
            if text_clip_emb is not None and image_emb is not None:
                text_norm = self._normalize(text_clip_emb)
                img_norm = self._normalize(image_emb)
                primary_emb = 0.7 * text_norm + 0.3 * img_norm
                result['primary_embedding'] = self._normalize(primary_emb)
            elif text_clip_emb is not None:
                result['primary_embedding'] = self._normalize(text_clip_emb)
            elif image_emb is not None:
                result['primary_embedding'] = self._normalize(image_emb)
            
            results.append(result)
        
        logger.info(f"✅ Đã tạo batch embeddings cho {len(products)} products")
        return results

