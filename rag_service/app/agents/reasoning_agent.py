"""
Reasoning Agent - Lập kế hoạch xử lý và suy luận
"""
from typing import Dict, Any, Optional
import logging
from app.agents.base_agent import BaseAgent
from app.infrastructure.llm.openai import LLMProvider
from app.api.deps import get_llm_provider

logger = logging.getLogger(__name__)


class ReasoningAgent(BaseAgent):
    """
    Reasoning Agent thực hiện:
    - Phân tích query và kết quả từ các agents khác
    - Lập kế hoạch xử lý
    - Suy luận để trả lời câu hỏi
    """
    
    def __init__(self, llm_provider: Optional[LLMProvider] = None):
        super().__init__("ReasoningAgent")
        self.llm_provider = llm_provider
    
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Thực hiện reasoning và lập kế hoạch
        """
        query = state.get("query", "").strip()
        intent = state.get("intent", {})
        knowledge_context = state.get("knowledge_context", "")
        tool_context = state.get("tool_context", "")
        
        # Lazy load LLM provider
        if not self.llm_provider:
            self.llm_provider = get_llm_provider()
        
        reasoning_plan = ""
        reasoning_steps = []
        reasoning_context = ""
        
        try:
            # Tạo reasoning prompt
            reasoning_prompt = self._create_reasoning_prompt(
                query=query,
                intent=intent,
                knowledge_context=knowledge_context,
                tool_context=tool_context
            )
            
            # Gọi LLM để reasoning
            self.log("🧠 Performing reasoning...")
            reasoning_result = await self.llm_provider.generate(
                prompt=reasoning_prompt,
                context="Bạn là Reasoning Agent trong hệ thống Multi-Agent RAG. Nhiệm vụ của bạn là phân tích query và kết quả từ các agents khác, sau đó lập kế hoạch và suy luận để trả lời câu hỏi."
            )
            
            # Parse reasoning result
            reasoning_plan = reasoning_result
            reasoning_steps = self._extract_reasoning_steps(reasoning_result)
            reasoning_context = self._build_reasoning_context(
                query=query,
                knowledge_context=knowledge_context,
                tool_context=tool_context,
                reasoning_result=reasoning_result
            )
            
            self.log(f"✅ Reasoning completed: {len(reasoning_steps)} steps")
            
        except Exception as e:
            self.log(f"❌ Error in reasoning: {str(e)}", level="error")
            # Fallback: tạo reasoning đơn giản
            reasoning_context = self._build_simple_reasoning_context(
                query=query,
                knowledge_context=knowledge_context,
                tool_context=tool_context
            )
        
        # Cập nhật state
        state.update({
            "reasoning_plan": reasoning_plan,
            "reasoning_steps": reasoning_steps,
            "reasoning_context": reasoning_context
        })
        
        return state
    
    def _create_reasoning_prompt(
        self,
        query: str,
        intent: Dict[str, Any],
        knowledge_context: str,
        tool_context: str
    ) -> str:
        """Tạo prompt cho reasoning"""
        
        # Phát hiện multi-part query
        has_product = bool(knowledge_context)
        has_statistics = bool(tool_context) and ("doanh" in tool_context.lower() or "thống kê" in tool_context.lower())
        has_image_request = "hình ảnh" in query.lower() or "ảnh" in query.lower() or "hình" in query.lower()
        
        prompt = f"""Phân tích câu hỏi và kết quả từ các agents, sau đó lập kế hoạch trả lời:

=== CÂU HỎI CỦA KHÁCH HÀNG ===
{query}

=== PHÂN LOẠI INTENT ===
Intent: {intent.get('type', 'unknown')}
- Có thông tin sản phẩm: {'CÓ' if has_product else 'KHÔNG'}
- Có thông tin doanh số/thống kê: {'CÓ' if has_statistics else 'KHÔNG'}
- Yêu cầu hình ảnh: {'CÓ' if has_image_request else 'KHÔNG'}

=== THÔNG TIN TỪ KNOWLEDGE AGENT (RAG SEARCH) ===
{knowledge_context if knowledge_context else "Không có thông tin từ RAG search"}

=== THÔNG TIN TỪ TOOL AGENT (DATABASE QUERIES) ===
{tool_context if tool_context else "Không có thông tin từ database"}

=== NHIỆM VỤ ===
Hãy phân tích và lập kế hoạch:

1. PHÂN TÍCH CÂU HỎI:
   - Xác định user muốn gì? (sản phẩm, doanh số, cả hai?)
   - Có phải multi-part query không? (ví dụ: hình ảnh + doanh số)

2. ĐÁNH GIÁ THÔNG TIN:
   - Thông tin từ Knowledge Agent có đủ không?
   - Thông tin từ Tool Agent có đủ không?
   - Cần thêm thông tin gì không?

3. LẬP KẾ HOẠCH TRẢ LỜI:
   - Nếu có CẢ sản phẩm VÀ doanh số: Kết hợp cả hai phần
   - Nếu chỉ có sản phẩm: Tập trung vào sản phẩm
   - Nếu chỉ có doanh số: Tập trung vào doanh số/thống kê
   - Format: Rõ ràng, có cấu trúc, dễ đọc

4. CÁC BƯỚC SUY LUẬN:
   - Bước 1: [Xác định phần nào cần trả lời]
   - Bước 2: [Format thông tin]
   - Bước 3: [Kết hợp các phần nếu cần]

Trả lời ngắn gọn, rõ ràng, có cấu trúc."""
        
        return prompt
    
    def _extract_reasoning_steps(self, reasoning_result: str) -> list:
        """Extract các bước reasoning từ kết quả"""
        # Simple extraction - có thể cải thiện
        steps = []
        lines = reasoning_result.split('\n')
        
        for line in lines:
            line = line.strip()
            if line and (line.startswith('-') or line.startswith('•') or line[0].isdigit()):
                steps.append(line)
        
        return steps if steps else [reasoning_result]
    
    def _build_reasoning_context(
        self,
        query: str,
        knowledge_context: str,
        tool_context: str,
        reasoning_result: str
    ) -> str:
        """Xây dựng reasoning context cho synthesis agent"""
        context_parts = []
        
        context_parts.append(f"Câu hỏi: {query}")
        context_parts.append("")
        
        if knowledge_context:
            context_parts.append("Thông tin từ RAG search:")
            context_parts.append(knowledge_context)
            context_parts.append("")
        
        if tool_context:
            context_parts.append("Thông tin từ database:")
            context_parts.append(tool_context)
            context_parts.append("")
        
        context_parts.append("Phân tích và kế hoạch:")
        context_parts.append(reasoning_result)
        
        return "\n".join(context_parts)
    
    def _build_simple_reasoning_context(
        self,
        query: str,
        knowledge_context: str,
        tool_context: str
    ) -> str:
        """Xây dựng reasoning context đơn giản (fallback)"""
        context_parts = []
        
        context_parts.append(f"Câu hỏi: {query}")
        
        if knowledge_context:
            context_parts.append("Thông tin tìm được:")
            context_parts.append(knowledge_context)
        
        if tool_context:
            context_parts.append("Thông tin từ database:")
            context_parts.append(tool_context)
        
        return "\n".join(context_parts)

