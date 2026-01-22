"""
OpenAI LLM implementation - Triển khai LLM từ OpenAI
Khuyến nghị: GPT-4.1 với fallback Ollama
"""
import os
import logging
from typing import Optional
from abc import ABC, abstractmethod

logger = logging.getLogger(__name__)


class LLMProvider(ABC):
    """
    Abstract base class cho các LLM providers
    
    Định nghĩa interface chung cho tất cả các LLM implementations
    """
    
    @abstractmethod
    async def generate(self, prompt: str, context: Optional[str] = None) -> str:
        """
        Tạo phản hồi từ prompt
        
        Args:
            prompt: Câu hỏi hoặc yêu cầu
            context: Ngữ cảnh bổ sung (tùy chọn)
            
        Returns:
            Phản hồi từ LLM
        """
        pass


class OpenAILLM(LLMProvider):
    """
    OpenAI LLM implementation - Khuyến nghị: GPT-4.1
    
    Sử dụng OpenAI API để tạo phản hồi, có fallback sang Ollama khi lỗi
    """
    
    def __init__(self):
        """Khởi tạo OpenAI LLM với fallback Ollama"""
        from app.core.settings import Settings
        self.api_key = Settings.OPENAI_API_KEY
        self.model = Settings.OPENAI_MODEL
        self.client = None
        self.use_fallback = Settings.USE_OLLAMA_FALLBACK
        self.fallback_llm = None
        
        # Khởi tạo OpenAI client nếu có API key
        if self.api_key:
            try:
                import openai
                self.client = openai.OpenAI(api_key=self.api_key)
                logger.info(f"OpenAI LLM đã khởi tạo với model: {self.model}")
            except ImportError:
                logger.warning("OpenAI library chưa được cài đặt")
        else:
            logger.warning("OpenAI API key chưa được cấu hình")
        
        # Khởi tạo Ollama fallback nếu được bật
        if self.use_fallback:
            try:
                from app.infrastructure.llm.ollama import OllamaLLM
                self.fallback_llm = OllamaLLM()
                logger.info("Ollama fallback LLM đã khởi tạo")
            except Exception as e:
                logger.warning(f"Không thể khởi tạo Ollama fallback: {str(e)}")
    
    async def generate(self, prompt: str, context: Optional[str] = None) -> str:
        """
        Tạo phản hồi sử dụng OpenAI, fallback sang Ollama nếu lỗi
        
        Args:
            prompt: Câu hỏi hoặc yêu cầu
            context: Ngữ cảnh bổ sung (tùy chọn)
            
        Returns:
            Phản hồi từ LLM
        """
        # Nếu không có OpenAI client, thử dùng fallback
        if not self.client:
            if self.fallback_llm:
                logger.info("OpenAI không khả dụng, sử dụng Ollama fallback")
                return await self.fallback_llm.generate(prompt, context)
            raise ValueError("OpenAI client chưa được khởi tạo và không có fallback")
        
        # Chuẩn bị messages cho OpenAI API
        messages = []
        if context:
            messages.append({
                "role": "system",
                "content": f"Context: {context}"
            })
        messages.append({
            "role": "user",
            "content": prompt
        })
        
        try:
            # Gọi OpenAI API
            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
                temperature=0.7,  # Độ sáng tạo (0-1)
                max_tokens=1000   # Số token tối đa
            )
            return response.choices[0].message.content
        except Exception as e:
            logger.error(f"Lỗi khi tạo phản hồi với OpenAI: {str(e)}")
            # Thử fallback khi có lỗi
            if self.fallback_llm:
                logger.info("OpenAI lỗi, chuyển sang Ollama fallback")
                return await self.fallback_llm.generate(prompt, context)
            raise

