"""
Synthesis Agent - Tổng hợp kết quả từ các agents và tạo câu trả lời cuối cùng
"""
from typing import Dict, Any, Optional
import logging
from app.agents.base_agent import BaseAgent
from app.infrastructure.llm.openai import LLMProvider
from app.api.deps import get_llm_provider

logger = logging.getLogger(__name__)


class SynthesisAgent(BaseAgent):
    """
    Synthesis Agent tổng hợp:
    - Kết quả từ Knowledge Agent
    - Kết quả từ Tool Agent
    - Reasoning từ Reasoning Agent
    - Tạo câu trả lời cuối cùng
    """
    
    def __init__(self, llm_provider: Optional[LLMProvider] = None):
        super().__init__("SynthesisAgent")
        self.llm_provider = llm_provider
    
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Tổng hợp kết quả và tạo câu trả lời cuối cùng
        
        Returns:
            Updated state with:
                - final_answer: Câu trả lời cuối cùng
                - answer_confidence: Độ tin cậy của câu trả lời
        """
        query = state.get("query", "").strip()
        intent = state.get("intent", {})
        knowledge_context = state.get("knowledge_context", "")
        tool_context = state.get("tool_context", "")
        reasoning_context = state.get("reasoning_context", "")
        knowledge_results = state.get("knowledge_results", [])
        
        # Lazy load LLM provider
        if not self.llm_provider:
            self.llm_provider = get_llm_provider()
        
        final_answer = ""
        answer_confidence = 0.0
        
        try:
            # Tạo synthesis prompt
            synthesis_prompt = self._create_synthesis_prompt(
                query=query,
                intent=intent,
                knowledge_context=knowledge_context,
                tool_context=tool_context,
                reasoning_context=reasoning_context,
                knowledge_results=knowledge_results
            )
            
            # Gọi LLM để tổng hợp
            self.log("📝 Synthesizing final answer...")
            system_context = """Bạn là Synthesis Agent trong hệ thống Multi-Agent RAG của Fresher Food Delivery. 

Nhiệm vụ của bạn:
1. Tổng hợp thông tin từ Knowledge Agent (sản phẩm từ RAG search)
2. Tổng hợp thông tin từ Tool Agent (doanh số, thống kê từ database)
3. Tạo câu trả lời CUỐI CÙNG, ĐẦY ĐỦ cho khách hàng

Nguyên tắc:
- Sử dụng TẤT CẢ thông tin có sẵn, không bỏ sót
- Xử lý multi-part queries (ví dụ: hình ảnh + doanh số) một cách đầy đủ
- Format rõ ràng, dễ đọc
- Trả lời bằng tiếng Việt, thân thiện và chuyên nghiệp
- Nếu user yêu cầu nhiều thứ, trả lời đầy đủ tất cả"""
            
            final_answer = await self.llm_provider.generate(
                prompt=synthesis_prompt,
                context=system_context
            )
            
            # Tính độ tin cậy
            answer_confidence = self._calculate_confidence(
                knowledge_results=knowledge_results,
                tool_context=tool_context,
                reasoning_context=reasoning_context
            )
            
            self.log(f"✅ Final answer synthesized (confidence: {answer_confidence:.2%})")
            
        except Exception as e:
            self.log(f"❌ Error in synthesis: {str(e)}", level="error")
            # Fallback: tạo câu trả lời đơn giản
            final_answer = self._create_fallback_answer(
                query=query,
                knowledge_context=knowledge_context,
                tool_context=tool_context
            )
            answer_confidence = 0.5
        
        # Cập nhật state
        state.update({
            "final_answer": final_answer,
            "answer_confidence": answer_confidence
        })
        
        return state
    
    def _create_synthesis_prompt(
        self,
        query: str,
        intent: Dict[str, Any],
        knowledge_context: str,
        tool_context: str,
        reasoning_context: str,
        knowledge_results: list
    ) -> str:
        """Tạo prompt cho synthesis"""
        
        # Phát hiện multi-part query (ví dụ: hình ảnh + doanh số)
        has_product_query = bool(knowledge_results) or "sản phẩm" in query.lower() or "thịt" in query.lower() or "rau" in query.lower()
        has_sales_query = "doanh số" in query.lower() or "doanh thu" in query.lower() or "thống kê" in query.lower() or "theo tháng" in query.lower()
        has_image_query = "hình ảnh" in query.lower() or "ảnh" in query.lower() or "hình" in query.lower()
        
        # Kiểm tra xem có product revenue data trong tool_context không
        has_product_revenue = "DOANH SỐ THEO THÁNG CỦA SẢN PHẨM" in tool_context if tool_context else False
        
        # Format knowledge results chi tiết hơn
        products_info = ""
        if knowledge_results:
            products_info = "\n=== DANH SÁCH SẢN PHẨM TÌM ĐƯỢC ===\n"
            for i, result in enumerate(knowledge_results[:10], 1):
                product_name = result.get("product_name", "N/A")
                category_name = result.get("category_name", "")
                price = result.get("price")
                similarity = result.get("similarity", 0)
                product_id = result.get("product_id", "")
                
                product_line = f"{i}. {product_name}"
                if category_name:
                    product_line += f" (Danh mục: {category_name})"
                if price:
                    product_line += f" - Giá: {price:,.0f} VND"
                if similarity:
                    product_line += f" - Độ tương đồng: {similarity:.1%}"
                if product_id:
                    product_line += f" - Mã: {product_id}"
                products_info += product_line + "\n"
        
        prompt = f"""Bạn là Synthesis Agent trong hệ thống Multi-Agent RAG của Fresher Food Delivery. 
Nhiệm vụ của bạn là tổng hợp thông tin từ các agents và tạo câu trả lời CUỐI CÙNG, ĐẦY ĐỦ cho khách hàng.

=== CÂU HỎI CỦA KHÁCH HÀNG ===
{query}

=== PHÂN LOẠI YÊU CẦU ===
Intent: {intent.get('type', 'unknown')}
- Yêu cầu về sản phẩm: {'CÓ' if has_product_query else 'KHÔNG'}
- Yêu cầu về hình ảnh: {'CÓ' if has_image_query else 'KHÔNG'}
- Yêu cầu về doanh số/thống kê: {'CÓ' if has_sales_query else 'KHÔNG'}

{reasoning_context}

=== THÔNG TIN TỪ RAG SEARCH (SẢN PHẨM) ===
{products_info if products_info else "Không tìm thấy sản phẩm phù hợp"}

{knowledge_context if knowledge_context and not products_info else ""}

=== THÔNG TIN TỪ DATABASE (DOANH SỐ, THỐNG KÊ, CHI TIẾT) ===
{tool_context if tool_context else "Không có thông tin từ database"}

=== HƯỚNG DẪN TRẢ LỜI ===

🔥 QUAN TRỌNG - XỬ LÝ MULTI-PART QUERIES:
1. Nếu khách hàng yêu cầu CẢ hình ảnh sản phẩm VÀ doanh số/thống kê:
   → Bạn PHẢI trả lời ĐẦY ĐỦ cả hai phần:
   - Phần 1: Giới thiệu sản phẩm tìm được (tên, giá, mô tả ngắn)
   - Phần 2: Thông tin doanh số/thống kê (nếu có trong tool_context)
   - Ví dụ: "Tôi tìm thấy [số] sản phẩm: [tên sản phẩm]. [Thông tin doanh số theo tháng]"

2. Nếu chỉ có thông tin sản phẩm:
   → Trả lời về sản phẩm, liệt kê tên, giá, danh mục
   → Nếu user yêu cầu hình ảnh, nhắc rằng hình ảnh sẽ được hiển thị kèm theo

3. Nếu chỉ có thông tin doanh số/thống kê:
   → Trả lời về doanh số/thống kê một cách rõ ràng, có format số liệu

4. Nếu có CẢ sản phẩm VÀ doanh số:
   → Kết hợp cả hai, trả lời đầy đủ và có cấu trúc

YÊU CẦU CHUNG:
- Trả lời bằng tiếng Việt, thân thiện và chuyên nghiệp
- Sử dụng TẤT CẢ thông tin có sẵn từ RAG search và database
- Nếu có sản phẩm, liệt kê rõ ràng: tên, giá, danh mục
- Nếu có doanh số/thống kê, format rõ ràng với số liệu cụ thể
- KHÔNG được bỏ sót thông tin quan trọng
- Nếu thiếu thông tin, nói rõ và đề nghị khách hàng cung cấp thêm

FORMAT KHUYẾN NGHỊ (UX xịn):
- Nếu có CẢ sản phẩm VÀ doanh số:
  → Format như sau:
  
  🥩 Sản phẩm: [Tên sản phẩm]
  [Mô tả ngắn về sản phẩm]
  
  📸 Hình ảnh sản phẩm:
  (Hình ảnh sẽ được hiển thị kèm theo)
  
  📊 Doanh thu theo tháng ([Năm]):
  Tháng 1: [số tiền]đ
  Tháng 2: [số tiền]đ
  ...
  👉 [Nhận xét về tháng bán chạy nhất nếu có]

- Nếu chỉ có sản phẩm:
  → "Tôi tìm thấy [số] sản phẩm: [danh sách với tên, giá]"
  
- Nếu chỉ có doanh số:
  → "📊 Doanh số theo tháng: [số liệu chi tiết]"
  
- Kết thúc với câu hỏi hỗ trợ thêm (nếu cần)

=== CÂU TRẢ LỜI CỦA BẠN ===
"""
        
        return prompt
    
    def _calculate_confidence(
        self,
        knowledge_results: list,
        tool_context: str,
        reasoning_context: str
    ) -> float:
        """Tính độ tin cậy của câu trả lời"""
        confidence = 0.0
        
        # Có kết quả từ RAG search
        if knowledge_results:
            # Tính confidence dựa trên similarity
            max_similarity = max([r.get("similarity", 0) for r in knowledge_results], default=0)
            confidence += max_similarity * 0.5  # 50% từ RAG
        
        # Có thông tin từ database
        if tool_context:
            confidence += 0.3  # 30% từ database
        
        # Có reasoning
        if reasoning_context:
            confidence += 0.2  # 20% từ reasoning
        
        return min(confidence, 1.0)
    
    def _create_fallback_answer(
        self,
        query: str,
        knowledge_context: str,
        tool_context: str
    ) -> str:
        """Tạo câu trả lời fallback khi LLM lỗi"""
        if knowledge_context:
            return f"Dựa trên thông tin tìm được:\n{knowledge_context}\n\nBạn có muốn biết thêm chi tiết về sản phẩm nào không?"
        elif tool_context:
            return f"Thông tin từ hệ thống:\n{tool_context}\n\nBạn có cần hỗ trợ gì thêm không?"
        else:
            return "Xin lỗi, tôi chưa tìm thấy thông tin phù hợp với câu hỏi của bạn. Bạn có thể mô tả chi tiết hơn hoặc thử tìm kiếm bằng từ khóa khác không?"

