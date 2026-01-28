"""
Product Embedding Service - Service tạo embedding vectors từ product (text + image)
Hỗ trợ: Image to Image search, Text to Image search
"""
import logging
from typing import Optional, List, Dict
import numpy as np

from app.services.image import ImageEmbeddingService
from app.services.embedding import EmbeddingService

logger = logging.getLogger(__name__)


class ProductEmbeddingService:
    """
    Service tạo embedding vectors cho products
    
    Hỗ trợ:
    - Image embeddings: Từ ảnh sản phẩm (CLIP)
    - Text embeddings: Từ tên, mô tả sản phẩm (OpenAI/Sentence Transformer)
    - Combined embeddings: Kết hợp text + image
    """
    
    def __init__(
        self,
        image_embedding_service: ImageEmbeddingService,
        text_embedding_service: EmbeddingService
    ):
        """
        Khởi tạo Product Embedding Service
        
        Args:
            image_embedding_service: Service tạo embedding từ ảnh
            text_embedding_service: Service tạo embedding từ text
        """
        self.image_embedding_service = image_embedding_service
        self.text_embedding_service = text_embedding_service
    
    async def create_image_embedding(self, image_bytes: bytes) -> Optional[np.ndarray]:
        """
        Tạo image embedding từ ảnh sản phẩm
        
        Args:
            image_bytes: Ảnh sản phẩm dưới dạng bytes
            
        Returns:
            Image embedding vector (512 dimensions - CLIP)
        """
        return await self.image_embedding_service.create_embedding(image_bytes)
    
    async def create_text_embedding(self, text: str) -> Optional[np.ndarray]:
        """
        Tạo text embedding từ text sản phẩm (tên, mô tả)
        
        Args:
            text: Text sản phẩm (tên + mô tả)
            
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
        
        Strategy: Normalize và concatenate hoặc weighted average
        
        Args:
            text: Text sản phẩm
            image_bytes: Ảnh sản phẩm (tùy chọn)
            
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
    
    async def create_product_embeddings(
        self,
        product_data: Dict,
        image_bytes: Optional[bytes] = None
    ) -> Dict[str, Optional[np.ndarray]]:
        """
        Tạo tất cả embeddings cho một product
        
        Args:
            product_data: Dict chứa thông tin product
                - product_id: ID sản phẩm
                - product_name: Tên sản phẩm
                - description: Mô tả
                - category_id: ID category
                - category_name: Tên category
            image_bytes: Ảnh sản phẩm (tùy chọn)
            
        Returns:
            Dict chứa các embeddings:
                - image_embedding: Image embedding (512 dim)
                - text_embedding: Text embedding (3072/384 dim)
                - combined_embedding: Combined embedding
        """
        # Tạo text từ product data
        product_name = product_data.get('product_name', '')
        description = product_data.get('description', '')
        category_name = product_data.get('category_name', '')
        
        # Combine text: tên + mô tả + category
        text_parts = [product_name]
        if description:
            text_parts.append(description)
        if category_name:
            text_parts.append(f"Category: {category_name}")
        
        text = " ".join(text_parts)
        
        # Tạo các embeddings
        results = {}
        
        # Image embedding
        if image_bytes:
            results['image_embedding'] = await self.create_image_embedding(image_bytes)
        else:
            results['image_embedding'] = None
        
        # Text embedding
        if text:
            results['text_embedding'] = await self.create_text_embedding(text)
        else:
            results['text_embedding'] = None
        
        # Combined embedding
        results['combined_embedding'] = await self.create_combined_embedding(
            text,
            image_bytes
        )
        
        return results

