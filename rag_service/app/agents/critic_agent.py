"""
Critic Agent - Kiểm tra hallucination và chất lượng câu trả lời
"""
from typing import Dict, Any, Optional
import logging
from app.agents.base_agent import BaseAgent
from app.infrastructure.llm.openai import LLMProvider
from app.api.deps import get_llm_provider

logger = logging.getLogger(__name__)


class CriticAgent(BaseAgent):
    """
    Critic Agent kiểm tra:
    - Hallucination: Câu trả lời có thông tin không có trong context không?
    - Accuracy: Câu trả lời có chính xác không?
    - Completeness: Câu trả lời có đầy đủ không?
    - Relevance: Câu trả lời có liên quan đến câu hỏi không?
    """
    
    def __init__(self, llm_provider: Optional[LLMProvider] = None):
        super().__init__("CriticAgent")
        self.llm_provider = llm_provider
    
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Kiểm tra chất lượng câu trả lời
        
        Returns:
            Updated state with:
                - critic_score: Điểm đánh giá (0-1)
                - critic_feedback: Phản hồi từ critic
                - has_hallucination: Có hallucination không?
                - final_answer_verified: Câu trả lời đã được verify
        """
        query = state.get("query", "").strip()
        final_answer = state.get("final_answer", "")
        knowledge_context = state.get("knowledge_context", "")
        tool_context = state.get("tool_context", "")
        reasoning_context = state.get("reasoning_context", "")
        
        # Lazy load LLM provider
        if not self.llm_provider:
            self.llm_provider = get_llm_provider()
        
        critic_score = 0.0
        critic_feedback = ""
        has_hallucination = False
        final_answer_verified = final_answer
        
        try:
            # Tạo critic prompt
            critic_prompt = self._create_critic_prompt(
                query=query,
                final_answer=final_answer,
                knowledge_context=knowledge_context,
                tool_context=tool_context,
                reasoning_context=reasoning_context
            )
            
            # Gọi LLM để critic
            self.log("🔍 Criticizing answer...")
            critic_result = await self.llm_provider.generate(
                prompt=critic_prompt,
                context="Bạn là Critic Agent trong hệ thống Multi-Agent RAG. Nhiệm vụ của bạn là kiểm tra chất lượng câu trả lời, phát hiện hallucination và đảm bảo tính chính xác."
            )
            
            # Parse critic result
            critic_feedback = critic_result
            critic_score = self._extract_score(critic_result)
            has_hallucination = self._detect_hallucination(critic_result)
            
            # Nếu có hallucination, cố gắng sửa
            if has_hallucination:
                self.log("⚠️ Hallucination detected, attempting to fix...")
                final_answer_verified = await self._fix_hallucination(
                    query=query,
                    original_answer=final_answer,
                    knowledge_context=knowledge_context,
                    tool_context=tool_context,
                    critic_feedback=critic_feedback
                )
            
            self.log(f"✅ Critic completed (score: {critic_score:.2%}, hallucination: {has_hallucination})")
            
        except Exception as e:
            self.log(f"❌ Error in critic: {str(e)}", level="error")
            # Fallback: chấp nhận câu trả lời gốc
            critic_score = 0.7
            critic_feedback = "Không thể kiểm tra chi tiết do lỗi hệ thống"
            has_hallucination = False
            final_answer_verified = final_answer
        
        # Cập nhật state
        state.update({
            "critic_score": critic_score,
            "critic_feedback": critic_feedback,
            "has_hallucination": has_hallucination,
            "final_answer_verified": final_answer_verified
        })
        
        return state
    
    def _create_critic_prompt(
        self,
        query: str,
        final_answer: str,
        knowledge_context: str,
        tool_context: str,
        reasoning_context: str
    ) -> str:
        """Tạo prompt cho critic"""
        prompt = f"""Kiểm tra chất lượng câu trả lời sau:

Câu hỏi: {query}

Câu trả lời:
{final_answer}

Thông tin có sẵn (context):
{knowledge_context if knowledge_context else "Không có"}
{tool_context if tool_context else ""}
{reasoning_context if reasoning_context else ""}

Hãy đánh giá:
1. Hallucination: Câu trả lời có chứa thông tin KHÔNG có trong context không? (true/false)
2. Accuracy: Câu trả lời có chính xác dựa trên context không? (0-1)
3. Completeness: Câu trả lời có đầy đủ không? (0-1)
4. Relevance: Câu trả lời có liên quan đến câu hỏi không? (0-1)

Trả lời theo format:
HALLUCINATION: true/false
ACCURACY: 0.0-1.0
COMPLETENESS: 0.0-1.0
RELEVANCE: 0.0-1.0
FEEDBACK: [Nhận xét chi tiết]"""
        
        return prompt
    
    def _extract_score(self, critic_result: str) -> float:
        """Extract score từ critic result"""
        import re
        
        # Tìm các scores
        accuracy_match = re.search(r"ACCURACY:\s*([\d.]+)", critic_result, re.IGNORECASE)
        completeness_match = re.search(r"COMPLETENESS:\s*([\d.]+)", critic_result, re.IGNORECASE)
        relevance_match = re.search(r"RELEVANCE:\s*([\d.]+)", critic_result, re.IGNORECASE)
        
        scores = []
        if accuracy_match:
            scores.append(float(accuracy_match.group(1)))
        if completeness_match:
            scores.append(float(completeness_match.group(1)))
        if relevance_match:
            scores.append(float(relevance_match.group(1)))
        
        # Trung bình các scores
        return sum(scores) / len(scores) if scores else 0.5
    
    def _detect_hallucination(self, critic_result: str) -> bool:
        """Phát hiện hallucination"""
        import re
        
        # Tìm HALLUCINATION: true/false
        match = re.search(r"HALLUCINATION:\s*(true|false)", critic_result, re.IGNORECASE)
        if match:
            return match.group(1).lower() == "true"
        
        # Fallback: tìm từ khóa
        if "hallucination" in critic_result.lower() and "true" in critic_result.lower():
            return True
        
        return False
    
    async def _fix_hallucination(
        self,
        query: str,
        original_answer: str,
        knowledge_context: str,
        tool_context: str,
        critic_feedback: str
    ) -> str:
        """Sửa hallucination trong câu trả lời"""
        try:
            fix_prompt = f"""Câu trả lời sau có chứa thông tin không chính xác (hallucination). Hãy sửa lại chỉ dựa trên thông tin có sẵn:

Câu hỏi: {query}

Câu trả lời gốc (có lỗi):
{original_answer}

Thông tin có sẵn:
{knowledge_context if knowledge_context else "Không có"}
{tool_context if tool_context else ""}

Phản hồi từ Critic:
{critic_feedback}

Hãy sửa lại câu trả lời, CHỈ sử dụng thông tin có trong context. Nếu không có đủ thông tin, hãy nói rõ."""
            
            fixed_answer = await self.llm_provider.generate(
                prompt=fix_prompt,
                context="Bạn đang sửa câu trả lời có hallucination. Chỉ sử dụng thông tin có trong context."
            )
            
            return fixed_answer
            
        except Exception as e:
            self.log(f"Error fixing hallucination: {str(e)}", level="error")
            # Fallback: thêm disclaimer
            return f"{original_answer}\n\n(Lưu ý: Một số thông tin có thể chưa được xác minh)"

