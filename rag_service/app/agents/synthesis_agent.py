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
    """
    
    def __init__(self, llm_provider: Optional[LLMProvider] = None):
        super().__init__("SynthesisAgent")
        self.llm_provider = llm_provider
    
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Tổng hợp kết quả và tạo câu trả lời cuối cùng
        """
        query = state.get("query", "").strip()
        intent = state.get("intent", {})
        knowledge_context = state.get("knowledge_context", "")
        tool_context = state.get("tool_context", "")
        reasoning_context = state.get("reasoning_context", "")
        knowledge_results = state.get("knowledge_results", [])
        knowledge_error = state.get("knowledge_error")  # 🔥 BONUS FIX: Lấy error nếu có
        
        # Lazy load LLM provider
        if not self.llm_provider:
            self.llm_provider = get_llm_provider()
        
        final_answer = ""
        answer_confidence = 0.0
        
        try:
            # 🔥 LOG STATE TRƯỚC KHI SYNTHESIS (debug)
            import json
            state_summary = {
                "knowledge_results_count": len(knowledge_results),
                "knowledge_results": [{"product_id": r.get("product_id"), "product_name": r.get("product_name"), "similarity": r.get("similarity")} for r in knowledge_results[:3]],
                "has_knowledge_context": bool(knowledge_context),
                "has_tool_context": bool(tool_context),
                "has_reasoning_context": bool(reasoning_context)
            }
            self.log(f"📊 STATE BEFORE SYNTHESIS: {json.dumps(state_summary, ensure_ascii=False, indent=2)}")
            
            # 🔥 XÁC ĐỊNH FACT TỪ STATE (không để LLM đoán)
            has_products = len(knowledge_results) > 0
            has_sales_data = bool(tool_context) and ("doanh" in tool_context.lower() or "thống kê" in tool_context.lower() or "revenue" in tool_context.lower())
            product_names = [r.get("product_name", "") for r in knowledge_results[:3] if r.get("product_name")]
            
            # 🔥 FIX: Phát hiện nếu user hỏi về sản phẩm cụ thể nhưng không tìm thấy
            query_lower = query.lower()
            product_keywords = ["cá", "thịt", "rau", "gà", "tôm", "sản phẩm", "món"]
            asked_about_specific_product = any(kw in query_lower for kw in product_keywords)
            needs_clarification = asked_about_specific_product and not has_products and not has_sales_data
            
            # Tạo synthesis prompt
            synthesis_prompt = self._create_synthesis_prompt(
                query=query,
                intent=intent,
                knowledge_context=knowledge_context,
                tool_context=tool_context,
                reasoning_context=reasoning_context,
                knowledge_results=knowledge_results,
                knowledge_error=knowledge_error  # 🔥 BONUS FIX: Truyền error vào prompt
            )
            
            # Gọi LLM để tổng hợp
            self.log("📝 Synthesizing final answer...")
            system_context = f"""Bạn là Synthesis Agent trong hệ thống Multi-Agent RAG của Fresher Food Delivery. 

Nhiệm vụ của bạn là tổng hợp thông tin từ các agents và tạo câu trả lời cuối cùng cho khách hàng.

🔥 DỮ LIỆU THẬT TỪ HỆ THỐNG (BẠN PHẢI DỰA VÀO ĐÂY, KHÔNG ĐOÁN):
- Có sản phẩm tìm được: {'CÓ' if has_products else 'KHÔNG'}
- Số lượng sản phẩm: {len(knowledge_results)}
- Tên sản phẩm tìm được: {', '.join(product_names) if product_names else 'KHÔNG CÓ'}
- Có dữ liệu doanh số: {'CÓ' if has_sales_data else 'KHÔNG'}

🔥 QUY TẮC NGHIÊM NGẶT:
1. NẾU có sản phẩm trong knowledge_results → BẠN PHẢI nói về sản phẩm đó
2. NẾU có dữ liệu doanh số trong tool_context → BẠN PHẢI nói về doanh số đó
3. KHÔNG được nói "chưa có hình ảnh" nếu knowledge_results có sản phẩm (hình ảnh sẽ được hệ thống tự động hiển thị)
4. KHÔNG được nói "chưa có thông tin" nếu có dữ liệu trong knowledge_results hoặc tool_context
5. CHỈ nói "chưa có" khi THỰC SỰ không có dữ liệu (knowledge_results rỗng VÀ tool_context rỗng)

Hãy trả lời một cách thân thiện, chính xác và hữu ích."""
            
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
        
        # Cập nhật state (KHÔNG overwrite knowledge_results)
        state.update({
            "final_answer": final_answer,
            "answer_confidence": answer_confidence
        })
        
        # 🔥 VALIDATION: Đảm bảo knowledge_results không bị mất
        if "knowledge_results" not in state or len(state.get("knowledge_results", [])) == 0:
            # Nếu knowledge_results bị mất, log warning nhưng không restore (vì có thể thực sự không có)
            if len(knowledge_results) > 0:
                self.log(f"⚠️ Warning: knowledge_results may have been lost. Original count: {len(knowledge_results)}")
        
        return state
    
    def _create_synthesis_prompt(
        self,
        query: str,
        intent: Dict[str, Any],
        knowledge_context: str,
        tool_context: str,
        reasoning_context: str,
        knowledge_results: list,
        knowledge_error: Optional[str] = None
    ) -> str:
        """Tạo prompt cho synthesis"""
        
        # Format knowledge results
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
        
        prompt = f"""Dựa trên thông tin từ các agents, hãy tạo câu trả lời cho khách hàng:

                    === CÂU HỎI CỦA KHÁCH HÀNG ===
                    {query}
                    
                    === PHÂN LOẠI YÊU CẦU ===
                    Intent: {intent.get('type', 'unknown')}

                    {reasoning_context if reasoning_context else ""}

                    === THÔNG TIN TỪ RAG SEARCH (SẢN PHẨM) ===
                    {products_info if products_info else "❌ KHÔNG TÌM THẤY SẢN PHẨM PHÙ HỢP"}
                    
                    {knowledge_context if knowledge_context and not products_info else ""}

                    === THÔNG TIN TỪ DATABASE (DOANH SỐ, THỐNG KÊ, CHI TIẾT) ===
                    {tool_context if tool_context else "Không có thông tin từ database"}
                    
                    {f'⚠️ LƯU Ý: Knowledge Agent gặp lỗi kỹ thuật: {knowledge_error}. Hệ thống tạm thời không thể tìm kiếm hình ảnh sản phẩm. Vui lòng thử lại sau.' if knowledge_error else ''}

                    🔥 FACT CHECK - DỮ LIỆU THẬT TỪ HỆ THỐNG:
                    - Số lượng sản phẩm tìm được: {len(knowledge_results)}
                    - {'✅ CÓ SẢN PHẨM - BẠN PHẢI GIỚI THIỆU SẢN PHẨM ĐÓ' if knowledge_results else '❌ KHÔNG CÓ SẢN PHẨM - MỚI NÓI "CHƯA CÓ THÔNG TIN"'}
                    
                    🔥 QUY TẮC NGHIÊM NGẶT DỰA TRÊN DỮ LIỆU THẬT:
                    
                    NẾU CÓ SẢN PHẨM (danh sách trên có {len(knowledge_results)} sản phẩm):
                    → BẠN PHẢI giới thiệu sản phẩm đó: "Tôi tìm thấy sản phẩm: [tên sản phẩm]"
                    → BẠN PHẢI nói về giá, mô tả nếu có
                    → KHÔNG được nói "chưa có hình ảnh" - hình ảnh sẽ được hệ thống tự động hiển thị
                    → KHÔNG được nói "chưa có mô tả chi tiết" - dùng thông tin có sẵn
                    
                    NẾU KHÔNG CÓ SẢN PHẨM (danh sách rỗng):
                    → Nếu user hỏi về sản phẩm cụ thể: 
                       "Xin lỗi, hiện tại chúng tôi chưa có thông tin về [tên sản phẩm user hỏi] trong hệ thống.
                       
                       Bạn có muốn:
                       1️⃣ Xem danh sách sản phẩm tương tự?
                       2️⃣ Xem doanh thu tổng theo tháng của toàn cửa hàng?"
                    → Nếu user không hỏi sản phẩm cụ thể: "Xin lỗi, hiện tại chúng tôi chưa có thông tin về [tên sản phẩm user hỏi]"
                    → KHÔNG được suggest sản phẩm khác
                    → KHÔNG được tự động đổi sang doanh thu toàn hệ thống nếu user hỏi về sản phẩm cụ thể
                    → Hỏi lại user với 2 lựa chọn rõ ràng
                    
                    ⚠️ TUYỆT ĐỐI KHÔNG ĐƯỢC "BỊA" CHUYỆN:
                    - Nếu có sản phẩm trong danh sách → PHẢI nói về sản phẩm đó
                    - Nếu không có sản phẩm → MỚI nói "chưa có"
                    - KHÔNG được tự đoán hoặc suy diễn - chỉ dựa vào FACT ở trên

                    Yêu cầu:
                    1. Trả lời câu hỏi một cách chính xác và đầy đủ dựa trên thông tin có sẵn
                    2. Nếu có sản phẩm phù hợp, hãy liệt kê và mô tả ngắn gọn
                    3. Nếu không có thông tin, hãy nói rõ và đề nghị khách hàng cung cấp thêm thông tin
                    4. Giữ giọng điệu thân thiện và chuyên nghiệp
                    5. Trả lời bằng tiếng Việt

                    Câu trả lời:"""
        
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

