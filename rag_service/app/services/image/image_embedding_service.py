import os
import logging
from typing import Optional, List
import numpy as np
from PIL import Image
import io
import base64

from app.core.settings import Settings

logger = logging.getLogger(__name__)


class ImageEmbeddingService:
    """
    Service tạo embedding vectors từ ảnh
    """
    
    #  SINGLETON: CLIP model được load 1 lần duy nhất
    _clip_model = None
    _clip_preprocess = None
    _clip_device = None
    _clip_initialized = False
    
    def __init__(self):
        """Khởi tạo Image Embedding Service"""
        self.embedding_model = None
        self.use_openai = Settings.USE_OPENAI_EMBEDDINGS
        self.openai_api_key = Settings.OPENAI_API_KEY
        
        #  SINGLETON: Chỉ load CLIP model 1 lần duy nhất
        if not ImageEmbeddingService._clip_initialized:
            logger.info("🔄 Đang khởi tạo CLIP model cho image embeddings (lần đầu tiên)")
            self._init_clip()
            ImageEmbeddingService._clip_initialized = True
        else:
            logger.debug("✅ CLIP model đã được load trước đó, sử dụng lại")
            # Gán lại từ class variables
            self.clip_model = ImageEmbeddingService._clip_model
            self.clip_preprocess = ImageEmbeddingService._clip_preprocess
            self.clip_device = ImageEmbeddingService._clip_device
            self.embedding_model = "ViT-B/32"
        
        # Khởi tạo OpenAI client nếu có key (để dùng cho các tính năng khác trong tương lai)
        if self.use_openai and self.openai_api_key:
            logger.info("✅ OpenAI API key đã được cấu hình (dùng cho các tính năng khác)")
            self._init_openai()
        elif self.use_openai:
            logger.warning("⚠️  OpenAI embeddings được bật nhưng chưa có API Key!")
            logger.warning("   Để cấu hình: Thêm OPENAI_API_KEY vào file .env")
    
    def _init_openai(self):
        """Khởi tạo OpenAI vision embeddings"""
        try:
            import openai
            from openai import OpenAI
            
            self.openai_client = OpenAI(
                api_key=self.openai_api_key,
                timeout=60.0,
                max_retries=2
            )
            # Sử dụng OpenAI vision model cho ảnh
            self.embedding_model = "clip-vit-base-patch32"  # Hoặc có thể dùng OpenAI vision API
            logger.info("OpenAI image embedding client initialized")
        except ImportError:
            logger.warning("OpenAI library chưa được cài đặt, chuyển sang CLIP")
            self.use_openai = False
            self._init_clip()
    
    def _init_clip(self):
        """Khởi tạo CLIP model (SINGLETON - chỉ load 1 lần)"""
        try:
            import clip
            import torch
            
            # Load CLIP model
            device = "cuda" if torch.cuda.is_available() else "cpu"
            model_name = "ViT-B/32"  # CLIP ViT-B/32 model
            
            logger.info(f"Đang tải CLIP model: {model_name} (device: {device})")
            clip_model, clip_preprocess = clip.load(model_name, device=device)
            
            # 🔥 Lưu vào class variables (singleton)
            ImageEmbeddingService._clip_model = clip_model
            ImageEmbeddingService._clip_preprocess = clip_preprocess
            ImageEmbeddingService._clip_device = device
            
            # Gán vào instance variables
            self.clip_model = clip_model
            self.clip_preprocess = clip_preprocess
            self.clip_device = device
            self.embedding_model = model_name
            
            logger.info(f"✅ Đã tải CLIP model: {model_name} (SINGLETON - sẽ tái sử dụng)")
        except ImportError:
            logger.error("CLIP library chưa được cài đặt. Vui lòng cài: pip install git+https://github.com/openai/CLIP.git")
            raise
        except Exception as e:
            logger.error(f"Lỗi khi tải CLIP model: {str(e)}")
            raise
    
    def _preprocess_image(self, image_bytes: bytes) -> Image.Image:
        """Tiền xử lý ảnh: resize, normalize, etc."""
        try:
            image = Image.open(io.BytesIO(image_bytes))
            # Convert to RGB nếu cần
            if image.mode != 'RGB':
                image = image.convert('RGB')
            return image
        except Exception as e:
            logger.error(f"Lỗi khi xử lý ảnh: {str(e)}")
            raise
    
    async def create_embedding(self, image_bytes: bytes) -> Optional[np.ndarray]:
        """
        Tạo embedding vector từ ảnh
        
        Args:
            image_bytes: Ảnh dưới dạng bytes
            
        Returns:
            Embedding vector (numpy array) hoặc None nếu lỗi
        """
        if not image_bytes:
            return None
        
        try:
            # Hiện tại chỉ dùng CLIP (OpenAI không có direct image embedding API)
            # Nếu có OpenAI key, có thể dùng để mô tả ảnh rồi embed text, nhưng CLIP tốt hơn cho similarity
            return self._create_clip_embedding(image_bytes)
        except Exception as e:
            logger.error(f"Error creating image embedding: {str(e)}")
            return None
    
    async def _create_openai_embedding(self, image_bytes: bytes) -> np.ndarray:
        """
        Tạo embedding sử dụng OpenAI vision API
        """
        logger.warning("OpenAI không có direct image embedding API, dùng CLIP")
        return self._create_clip_embedding(image_bytes)
    
    def create_text_embedding(self, text: str) -> Optional[np.ndarray]:
        """
        Tạo text embedding sử dụng CLIP text encoder (512 dim)
        Tương thích với image embedding để search products
        """
        if not text or not text.strip():
            return None
        
        try:
            import torch
            
            if not self.clip_model:
                logger.error("CLIP model chưa được khởi tạo")
                return None
            
            # Tokenize text using CLIP's built-in tokenizer
            import clip
            text_tokens = clip.tokenize([text], truncate=True).to(self.clip_device)
            
            # Generate embedding
            with torch.no_grad():
                text_features = self.clip_model.encode_text(text_tokens)
                # Normalize features
                text_features = text_features / text_features.norm(dim=-1, keepdim=True)
                embedding = text_features.cpu().numpy()[0]
            
            return embedding.astype(np.float32)
        except Exception as e:
            logger.error(f"Error creating CLIP text embedding: {str(e)}")
            return None
    
    def create_query_embedding(
        self,
        image_bytes: Optional[bytes] = None,
        caption: Optional[str] = None
    ) -> Optional[np.ndarray]:
        """
          Tạo query embedding từ image + caption (nếu có)
        """
        image_emb = None
        text_emb = None
        
        # Tạo image embedding
        if image_bytes:
            image_emb = self._create_clip_embedding(image_bytes)
        
        # Tạo text embedding từ caption
        if caption:
            text_emb = self.create_text_embedding(caption)
        
        # Combine: 60% image + 40% text (nếu có cả 2)
        if image_emb is not None and text_emb is not None:
            # Normalize cả 2
            img_norm = image_emb / (np.linalg.norm(image_emb) + 1e-8)
            txt_norm = text_emb / (np.linalg.norm(text_emb) + 1e-8)
            # Weighted average: 60% image, 40% text
            combined = 0.6 * img_norm + 0.4 * txt_norm
            # Normalize lại sau khi combine
            combined = combined / (np.linalg.norm(combined) + 1e-8)
            return combined.astype(np.float32)
        elif image_emb is not None:
            # Chỉ có image (đã normalize trong CLIP)
            return image_emb
        elif text_emb is not None:
            # Chỉ có text (đã normalize trong CLIP)
            return text_emb
        
        return None
    
    def _create_clip_embedding(self, image_bytes: bytes) -> np.ndarray:
        """Tạo embedding sử dụng CLIP model"""
        try:
            import torch
            
            # Preprocess image
            image = self._preprocess_image(image_bytes)
            image_tensor = self.clip_preprocess(image).unsqueeze(0).to(self.clip_device)
            
            # Generate embedding
            with torch.no_grad():
                image_features = self.clip_model.encode_image(image_tensor)
                # Normalize features
                image_features = image_features / image_features.norm(dim=-1, keepdim=True)
                embedding = image_features.cpu().numpy()[0]
            
            return embedding.astype(np.float32)
        except Exception as e:
            logger.error(f"Lỗi khi tạo CLIP embedding: {str(e)}")
            raise
    
    async def create_embeddings(self, images: List[bytes]) -> List[Optional[np.ndarray]]:
        """
        Tạo embeddings cho nhiều ảnh (batch)
        """
        if not images:
            return []
        
        try:
            # Hiện tại chỉ dùng CLIP batch processing
            return self._create_clip_embeddings_batch(images)
        except Exception as e:
            logger.error(f"Lỗi khi tạo image embeddings: {str(e)}", exc_info=True)
            return [None] * len(images)
    
    def _create_clip_embeddings_batch(self, images: List[bytes]) -> List[Optional[np.ndarray]]:
        """Tạo embeddings cho nhiều ảnh cùng lúc bằng CLIP"""
        try:
            import torch
            
            # Preprocess tất cả ảnh
            image_tensors = []
            for img_bytes in images:
                try:
                    image = self._preprocess_image(img_bytes)
                    image_tensor = self.clip_preprocess(image)
                    image_tensors.append(image_tensor)
                except Exception as e:
                    logger.error(f"Lỗi khi preprocess ảnh: {str(e)}")
                    image_tensors.append(None)
            
            # Filter out None values
            valid_indices = [i for i, tensor in enumerate(image_tensors) if tensor is not None]
            valid_tensors = [image_tensors[i] for i in valid_indices]
            
            if not valid_tensors:
                return [None] * len(images)
            
            # Batch process
            batch_tensor = torch.stack(valid_tensors).to(self.clip_device)
            
            with torch.no_grad():
                image_features = self.clip_model.encode_image(batch_tensor)
                # Normalize features
                image_features = image_features / image_features.norm(dim=-1, keepdim=True)
                embeddings = image_features.cpu().numpy()
            
            # Map back to original list
            result = [None] * len(images)
            for idx, valid_idx in enumerate(valid_indices):
                result[valid_idx] = embeddings[idx].astype(np.float32)
            
            return result
        except Exception as e:
            logger.error(f"Lỗi khi tạo CLIP embeddings batch: {str(e)}")
            return [None] * len(images)

