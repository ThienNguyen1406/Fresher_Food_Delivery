"""
Embedding Service - Tạo embeddings từ text sử dụng Sentence Transformer hoặc OpenAI
"""
import os
import logging
from typing import List, Optional
import numpy as np

logger = logging.getLogger(__name__)

class EmbeddingService:
    def __init__(self):
        self.embedding_model = None
        self.use_openai = os.getenv("USE_OPENAI_EMBEDDINGS", "false").lower() == "true"
        self.openai_api_key = os.getenv("OPENAI_API_KEY")
        
        if self.use_openai and self.openai_api_key:
            logger.info("Using OpenAI embeddings")
            self._init_openai()
        else:
            logger.info("Using Sentence Transformer embeddings")
            self._init_sentence_transformer()
    
    def _init_openai(self):
        """Khởi tạo OpenAI embeddings"""
        try:
            import openai
            self.openai_client = openai.OpenAI(api_key=self.openai_api_key)
            self.embedding_model = "text-embedding-3-small"
        except ImportError:
            logger.warning("OpenAI library not installed, falling back to Sentence Transformer")
            self.use_openai = False
            self._init_sentence_transformer()
    
    def _init_sentence_transformer(self):
        """Khởi tạo Sentence Transformer"""
        try:
            from sentence_transformers import SentenceTransformer
            # Sử dụng model đa ngôn ngữ hỗ trợ tiếng Việt
            model_name = os.getenv("EMBEDDING_MODEL", "paraphrase-multilingual-MiniLM-L12-v2")
            self.embedding_model = SentenceTransformer(model_name)
            logger.info(f"Loaded Sentence Transformer model: {model_name}")
        except ImportError:
            logger.error("Sentence Transformer not installed. Please install: pip install sentence-transformers")
            raise
        except Exception as e:
            logger.error(f"Error loading Sentence Transformer: {str(e)}")
            raise
    
    async def create_embedding(self, text: str) -> Optional[np.ndarray]:
        """
        Tạo embedding vector từ text
        """
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
        """Tạo embedding bằng OpenAI API"""
        response = self.openai_client.embeddings.create(
            model=self.embedding_model,
            input=text
        )
        embedding = response.data[0].embedding
        return np.array(embedding, dtype=np.float32)
    
    def _create_sentence_transformer_embedding(self, text: str) -> np.ndarray:
        """Tạo embedding bằng Sentence Transformer"""
        embedding = self.embedding_model.encode(text, convert_to_numpy=True)
        return embedding.astype(np.float32)
    
    async def create_embeddings(self, texts: List[str]) -> List[Optional[np.ndarray]]:
        """
        Tạo embeddings cho nhiều texts cùng lúc (batch)
        """
        if not texts:
            return []
        
        try:
            if self.use_openai:
                # OpenAI hỗ trợ batch
                embeddings = []
                for text in texts:
                    emb = await self._create_openai_embedding(text)
                    embeddings.append(emb)
                return embeddings
            else:
                # Sentence Transformer hỗ trợ batch tốt hơn
                embeddings = self.embedding_model.encode(
                    texts, 
                    convert_to_numpy=True,
                    show_progress_bar=False
                )
                return [emb.astype(np.float32) for emb in embeddings]
        except Exception as e:
            logger.error(f"Error creating embeddings: {str(e)}")
            return [None] * len(texts)

