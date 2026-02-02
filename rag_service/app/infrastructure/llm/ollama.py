import os
import logging
from typing import Optional
import httpx

from app.infrastructure.llm.openai import LLMProvider
from app.core.settings import Settings

logger = logging.getLogger(__name__)


class OllamaLLM(LLMProvider):
    """
    Ollama LLM implementation - Dùng làm fallback
    """
    
    def __init__(self):
        """Khởi tạo Ollama LLM"""
        self.base_url = Settings.OLLAMA_BASE_URL
        self.model = Settings.OLLAMA_MODEL
        self.client = httpx.AsyncClient(timeout=60.0)  # Timeout 60 giây
        logger.info(f"Ollama LLM đã khởi tạo: {self.model} tại {self.base_url}")
    
    async def generate(self, prompt: str, context: Optional[str] = None) -> str:
        """
        Tạo phản hồi sử dụng Ollama
        """
        try:
            # Kết hợp context và prompt nếu có
            full_prompt = prompt
            if context:
                full_prompt = f"Context: {context}\n\n{prompt}"
            
            # Gọi Ollama API
            response = await self.client.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": full_prompt,
                    "stream": False  # Không stream, lấy toàn bộ response
                }
            )
            response.raise_for_status()
            
            result = response.json()
            return result.get("response", "")
            
        except Exception as e:
            logger.error(f"Lỗi khi tạo phản hồi với Ollama: {str(e)}")
            raise
    
    async def __aenter__(self):
        """Context manager entry"""
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit - Đóng HTTP client"""
        await self.client.aclose()

