import os
import logging
from typing import List, Optional
import numpy as np
import asyncio

from app.core.settings import Settings

logger = logging.getLogger(__name__)


class EmbeddingService:
    """
    Service tạo embedding vectors từ text
    """
    
    def __init__(self):
        """Khởi tạo Embedding Service"""
        self.embedding_model = None
        self.use_openai = Settings.USE_OPENAI_EMBEDDINGS
        self.openai_api_key = Settings.OPENAI_API_KEY
        
        # Khuyến nghị: Sử dụng OpenAI embeddings (text-embedding-3-large)
        if self.use_openai and self.openai_api_key:
            logger.info("✅ Đang sử dụng OpenAI embeddings (khuyến nghị: text-embedding-3-large)")
            self._init_openai()
        else:
            if self.use_openai:
                logger.warning("⚠️  OpenAI embeddings được bật nhưng chưa có API Key!")
                logger.warning("   Để cấu hình: Thêm OPENAI_API_KEY vào file .env hoặc environment variable")
                logger.warning("   Xem SETUP.md để biết chi tiết")
            logger.info("🔄 Chuyển sang Sentence Transformer (chậm hơn nhưng miễn phí)")
            self._init_sentence_transformer()
    
    def _init_openai(self):
        """Khởi tạo OpenAI embeddings - Khuyến nghị: text-embedding-3-large"""
        try:
            import openai
            from openai import OpenAI
            
            # Tạo client với timeout
            self.openai_client = OpenAI(
                api_key=self.openai_api_key,
                timeout=60.0,  # Timeout 60 giây cho mỗi request
                max_retries=2  # Retry tối đa 2 lần
            )
            # Sử dụng model từ settings (mặc định: text-embedding-3-large)
            self.embedding_model = Settings.EMBEDDING_MODEL
            logger.info(f"OpenAI embedding model: {self.embedding_model}")
        except ImportError:
            logger.warning("OpenAI library chưa được cài đặt, chuyển sang Sentence Transformer")
            self.use_openai = False
            self._init_sentence_transformer()
    
    def _init_sentence_transformer(self):
        """Khởi tạo Sentence Transformer (fallback khi không có OpenAI)"""
        try:
            from sentence_transformers import SentenceTransformer
            model_name = Settings.EMBEDDING_MODEL
            self.embedding_model = SentenceTransformer(model_name)
            logger.info(f"Đã tải Sentence Transformer model: {model_name}")
        except ImportError:
            logger.error("Sentence Transformer chưa được cài đặt. Vui lòng cài: pip install sentence-transformers")
            raise
        except Exception as e:
            logger.error(f"Lỗi khi tải Sentence Transformer: {str(e)}")
            raise
    
    async def create_embedding(self, text: str) -> Optional[np.ndarray]:
        """Create embedding vector from text"""
        if not text or not text.strip():
            return None
        
        try:
            if self.use_openai:
                return await self._create_openai_embedding(text)
            else:
                return self._create_sentence_transformer_embedding(text)
        except Exception as e:
            logger.error(f"Error creating embedding: {str(e)}")
            return None
    
    async def _create_openai_embedding(self, text: str) -> np.ndarray:
        """
        Tạo embedding sử dụng OpenAI API (single text)
        TỐI ƯU: Sử dụng async client trực tiếp thay vì to_thread để nhanh hơn
        """
        try:
            import asyncio
            response = await asyncio.to_thread(
                self.openai_client.embeddings.create,
                model=self.embedding_model,
                input=text,
                timeout=5.0  # TỐI ƯU: Giảm timeout từ 10s xuống 5s
            )
            embedding = response.data[0].embedding
            return np.array(embedding, dtype=np.float32)
        except Exception as e:
            logger.error(f"Lỗi khi tạo OpenAI embedding: {str(e)}")
            raise
    
    def _create_sentence_transformer_embedding(self, text: str) -> np.ndarray:
        """Create embedding using Sentence Transformer"""
        embedding = self.embedding_model.encode(text, convert_to_numpy=True)
        return embedding.astype(np.float32)
    
    async def create_embeddings(self, texts: List[str]) -> List[Optional[np.ndarray]]:
        """
        Tạo embeddings cho nhiều texts
        """
        if not texts:
            return []
        
        try:
            if self.use_openai:
                # OpenAI hỗ trợ batch, tạo embeddings cho nhiều texts cùng lúc
                # Giới hạn batch size để tránh quá tải
                batch_size = 100  # OpenAI cho phép tối đa 2048 texts
                embeddings = []
                
                logger.info(f"Đang tạo embeddings cho {len(texts)} chunks (batch size: {batch_size})")
                
                # Xử lý theo batch
                for i in range(0, len(texts), batch_size):
                    batch = texts[i:i + batch_size]
                    logger.info(f"Processing batch {i//batch_size + 1}/{(len(texts) + batch_size - 1)//batch_size} ({len(batch)} texts)")
                    
                    try:
                        # Gọi OpenAI API với batch (sử dụng asyncio.to_thread)
                        import asyncio
                        response = await asyncio.to_thread(
                            self.openai_client.embeddings.create,
                            model=self.embedding_model,
                            input=batch,
                            timeout=30.0  # Timeout 30 giây cho batch
                        )
                        
                        # Lấy embeddings từ response
                        batch_embeddings = [
                            np.array(item.embedding, dtype=np.float32) 
                            for item in response.data
                        ]
                        embeddings.extend(batch_embeddings)
                        
                        logger.info(f"✅ Đã tạo embeddings cho batch {i//batch_size + 1} ({len(batch_embeddings)} embeddings)")
                        
                    except Exception as e:
                        logger.error(f"❌ Lỗi khi tạo embeddings cho batch {i//batch_size + 1}: {str(e)}", exc_info=True)
                        # Thêm None cho batch này để không làm gián đoạn quá trình
                        embeddings.extend([None] * len(batch))
                
                logger.info(f"Hoàn thành tạo embeddings: {len([e for e in embeddings if e is not None])}/{len(texts)} thành công")
                return embeddings
            else:
                # Sentence Transformer: Encode tất cả cùng lúc (nhanh hơn)
                logger.info(f"Đang tạo embeddings cho {len(texts)} chunks bằng Sentence Transformer")
                embeddings = self.embedding_model.encode(
                    texts, 
                    convert_to_numpy=True,
                    show_progress_bar=True,  # Hiển thị progress bar
                    batch_size=32  # Batch size cho Sentence Transformer
                )
                logger.info(f"Đã tạo embeddings cho {len(embeddings)} chunks")
                return [emb.astype(np.float32) for emb in embeddings]
        except Exception as e:
            logger.error(f"Lỗi khi tạo embeddings: {str(e)}", exc_info=True)
            return [None] * len(texts)

