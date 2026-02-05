from typing import Dict, Any, Optional
import logging
from app.agents.base_agent import BaseAgent
from app.infrastructure.llm.openai import LLMProvider
from app.api.deps import get_llm_provider

logger = logging.getLogger(__name__)


class ReasoningSynthesisAgent(BaseAgent):
    """
    Reasoning + Synthesis Agent gộp:
    - Phân tích query và kết quả từ các agents khác
    - Lập kế hoạch xử lý
    - Tổng hợp và tạo câu trả lời cuối cùng
    Tất cả trong 1 lần gọi LLM thay vì 2 lần
    """
    
    def __init__(self, llm_provider: Optional[LLMProvider] = None):
        super().__init__("ReasoningSynthesisAgent")
        self.llm_provider = llm_provider
    
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Thực hiện reasoning + synthesis 
        """
        query = state.get("query", "").strip()
        intent = state.get("intent", {})
        knowledge_context = state.get("knowledge_context", "")
        tool_context = state.get("tool_context", "")
        knowledge_results = state.get("knowledge_results", [])
        
        # Lazy load LLM provider
        if not self.llm_provider:
            self.llm_provider = get_llm_provider()
        
        reasoning_plan = ""
        reasoning_context = ""
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
                "tool_results_count": len(state.get("tool_results", []))
            }
            self.log(f"📊 STATE BEFORE SYNTHESIS: {json.dumps(state_summary, ensure_ascii=False, indent=2)}")
            
            # Tạo combined prompt (reasoning + synthesis)
            combined_prompt = self._create_combined_prompt(
                query=query,
                intent=intent,
                knowledge_context=knowledge_context,
                tool_context=tool_context,
                knowledge_results=knowledge_results
            )
            
            # Gọi LLM 1 lần duy nhất cho cả reasoning + synthesis
            self.log("🧠📝 Performing reasoning + synthesis in one LLM call...")
            # 🔥 XÁC ĐỊNH FACT TỪ STATE (không để LLM đoán)
            has_products = len(knowledge_results) > 0
            
            # 🔥 QUAN TRỌNG: Nếu có doanh thu (tool_results có product_id) → chắc chắn có sản phẩm
            # Ngay cả khi knowledge_results rỗng (có thể bị mất), nhưng có doanh thu → có sản phẩm
            tool_results = state.get("tool_results", [])
            has_product_id_in_tool = False
            product_id_from_tool = None
            for tool_result in tool_results:
                func_args = tool_result.get("arguments", {})
                product_id_from_tool = func_args.get("productId") or func_args.get("product_id")
                if product_id_from_tool:
                    has_product_id_in_tool = True
                    # Nếu có product_id trong tool_results nhưng không có knowledge_results → có sản phẩm
                    if not has_products:
                        self.log(f"⚠️ No knowledge_results but product_id {product_id_from_tool} found in tool_results. Product exists!")
                        has_products = True  # Force has_products = True
                    break
            
            has_sales_data = bool(tool_context) and ("doanh" in tool_context.lower() or "thống kê" in tool_context.lower() or "revenue" in tool_context.lower())
            product_names = [r.get("product_name", "") for r in knowledge_results[:3] if r.get("product_name")]
            
            # Nếu có product_id từ tool nhưng không có product_name → thêm vào
            if has_product_id_in_tool and product_id_from_tool and not product_names:
                product_names = [f"Sản phẩm (Mã: {product_id_from_tool})"]
            
            system_context = f"""Bạn là Reasoning + Synthesis Agent trong hệ thống Multi-Agent RAG của Fresher Food Delivery. 

Nhiệm vụ của bạn:
1. PHÂN TÍCH (Reasoning): Phân tích query và kết quả từ các agents, lập kế hoạch trả lời
2. TỔNG HỢP (Synthesis): Tổng hợp thông tin và tạo câu trả lời CUỐI CÙNG, ĐẦY ĐỦ cho khách hàng

🔥 DỮ LIỆU THẬT TỪ HỆ THỐNG (BẠN PHẢI DỰA VÀO ĐÂY, KHÔNG ĐOÁN):
- Có sản phẩm tìm được: {'CÓ' if has_products else 'KHÔNG'}
- Số lượng sản phẩm: {len(knowledge_results)}
- Tên sản phẩm tìm được: {', '.join(product_names) if product_names else 'KHÔNG CÓ'}
- Có dữ liệu doanh số: {'CÓ' if has_sales_data else 'KHÔNG'}
{f'- ⚠️ QUAN TRỌNG: Có product_id {product_id_from_tool} trong tool_results (doanh thu) → CHẮC CHẮN CÓ SẢN PHẨM, KHÔNG được nói "chưa có thông tin"' if has_product_id_in_tool else ''}

🔥 QUY TẮC NGHIÊM NGẶT:
1. NẾU có sản phẩm trong knowledge_results → BẠN PHẢI nói về sản phẩm đó
2. NẾU có product_id trong tool_results (doanh thu) → CHẮC CHẮN CÓ SẢN PHẨM, BẠN PHẢI nói về sản phẩm đó
3. NẾU có dữ liệu doanh số trong tool_context → BẠN PHẢI nói về doanh số đó
4. KHÔNG được nói "chưa có hình ảnh" nếu có sản phẩm (hình ảnh sẽ được hệ thống tự động hiển thị)
5. KHÔNG được nói "chưa có thông tin về sản phẩm" nếu có dữ liệu trong knowledge_results HOẶC có product_id trong tool_results
6. CHỈ nói "chưa có" khi THỰC SỰ không có dữ liệu (knowledge_results rỗng VÀ không có product_id trong tool_results)

Nguyên tắc:
- Sử dụng TẤT CẢ thông tin có sẵn, không bỏ sót
- Xử lý multi-part queries (ví dụ: hình ảnh + doanh số) một cách đầy đủ
- Format rõ ràng, dễ đọc
- Trả lời bằng tiếng Việt, thân thiện và chuyên nghiệp

CẤM TUYỆT ĐỐI:
- KHÔNG được nói "xin lỗi, không thể cung cấp hình ảnh"
- KHÔNG được nói "hiện tại hệ thống chưa có hình ảnh" nếu knowledge_results có sản phẩm
- KHÔNG được nói "chưa có mô tả chi tiết" nếu knowledge_results có sản phẩm
- Hình ảnh sẽ được hệ thống tự động fetch và hiển thị, bạn chỉ cần giới thiệu sản phẩm bình thường"""
            
            combined_result = await self.llm_provider.generate(
                prompt=combined_prompt,
                context=system_context
            )
            
            # Parse kết quả (có thể có reasoning plan + final answer)
            # Format: [REASONING]...[/REASONING][ANSWER]...[/ANSWER]
            # Hoặc đơn giản: chỉ có final answer
            if "[REASONING]" in combined_result and "[/REASONING]" in combined_result:
                reasoning_start = combined_result.find("[REASONING]") + len("[REASONING]")
                reasoning_end = combined_result.find("[/REASONING]")
                reasoning_plan = combined_result[reasoning_start:reasoning_end].strip()
                
                answer_start = combined_result.find("[ANSWER]")
                if answer_start != -1:
                    answer_start += len("[ANSWER]")
                    final_answer = combined_result[answer_start:].strip()
                else:
                    # Không có [ANSWER] tag, lấy phần sau [/REASONING]
                    final_answer = combined_result[reasoning_end + len("[/REASONING]"):].strip()
            else:
                # Không có tags, toàn bộ là final answer
                final_answer = combined_result.strip()
                reasoning_plan = "Đã phân tích và tổng hợp thông tin trực tiếp"
            
            # Build reasoning context
            reasoning_context = self._build_reasoning_context(
                query=query,
                knowledge_context=knowledge_context,
                tool_context=tool_context,
                reasoning_plan=reasoning_plan
            )
            
            # Tính độ tin cậy
            answer_confidence = self._calculate_confidence(
                knowledge_results=knowledge_results,
                tool_context=tool_context,
                reasoning_plan=reasoning_plan
            )
            
            self.log(f"✅ Reasoning + Synthesis completed in one call (confidence: {answer_confidence:.2%})")
            
        except Exception as e:
            self.log(f"❌ Error in reasoning+synthesis: {str(e)}", level="error")
            # Fallback: tạo câu trả lời đơn giản
            final_answer = self._create_fallback_answer(
                query=query,
                knowledge_context=knowledge_context,
                tool_context=tool_context
            )
            reasoning_context = self._build_simple_reasoning_context(
                query=query,
                knowledge_context=knowledge_context,
                tool_context=tool_context
            )
            answer_confidence = 0.5
        
        # Cập nhật state (KHÔNG overwrite knowledge_results)
        state.update({
            "reasoning_plan": reasoning_plan,
            "reasoning_context": reasoning_context,
            "final_answer": final_answer,
            "answer_confidence": answer_confidence
        })
        
        # 🔥 VALIDATION: Đảm bảo knowledge_results không bị mất
        if "knowledge_results" not in state or len(state.get("knowledge_results", [])) == 0:
            # Nếu knowledge_results bị mất, log warning nhưng không restore (vì có thể thực sự không có)
            if len(knowledge_results) > 0:
                self.log(f"⚠️ Warning: knowledge_results may have been lost. Original count: {len(knowledge_results)}")
        
        return state
    
    def _create_combined_prompt(
        self,
        query: str,
        intent: Dict[str, Any],
        knowledge_context: str,
        tool_context: str,
        knowledge_results: list
    ) -> str:
        """Tạo combined prompt cho reasoning + synthesis"""
        
        # Phát hiện multi-part query
        has_product_query = bool(knowledge_results) or "sản phẩm" in query.lower() or "thịt" in query.lower() or "rau" in query.lower()
        has_sales_query = "doanh số" in query.lower() or "doanh thu" in query.lower() or "thống kê" in query.lower() or "theo tháng" in query.lower()
        has_image_query = "hình ảnh" in query.lower() or "ảnh" in query.lower() or "hình" in query.lower()
        
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
        
        prompt = f"""Bạn cần PHÂN TÍCH và TỔNG HỢP thông tin để trả lời câu hỏi của khách hàng.

                    === CÂU HỎI CỦA KHÁCH HÀNG ===
                    {query}

                    === PHÂN LOẠI YÊU CẦU ===
                    Intent: {intent.get('type', 'unknown')}
                    - Yêu cầu về sản phẩm: {'CÓ' if has_product_query else 'KHÔNG'}
                    - Yêu cầu về hình ảnh: {'CÓ' if has_image_query else 'KHÔNG'}
                    - Yêu cầu về doanh số/thống kê: {'CÓ' if has_sales_query else 'KHÔNG'}

                     === THÔNG TIN TỪ RAG SEARCH (SẢN PHẨM) ===
                     {products_info if products_info else "❌ KHÔNG TÌM THẤY SẢN PHẨM PHÙ HỢP"}

                     {knowledge_context if knowledge_context and not products_info else ""}
                     
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
                     → Mới nói: "Xin lỗi, hiện tại chúng tôi chưa có thông tin về [tên sản phẩm user hỏi]"
                     → KHÔNG được suggest sản phẩm khác
                     
                     ⚠️ TUYỆT ĐỐI KHÔNG ĐƯỢC "BỊA" CHUYỆN:
                     - Nếu có sản phẩm trong danh sách → PHẢI nói về sản phẩm đó
                     - Nếu không có sản phẩm → MỚI nói "chưa có"
                     - KHÔNG được tự đoán hoặc suy diễn - chỉ dựa vào FACT ở trên

                    === THÔNG TIN TỪ DATABASE (DOANH SỐ, THỐNG KÊ, CHI TIẾT) ===
                    {tool_context if tool_context else "Không có thông tin từ database"}

                    🔥 GIẢI PHÁP 3 - XỬ LÝ PARTIAL SUCCESS (Multi-Intent):
                    Bạn được cung cấp kết quả từ nhiều agents:
                    - product_search_result: {'CÓ' if knowledge_results else 'KHÔNG'} ({len(knowledge_results)} sản phẩm)
                    - sales_statistics_result: {'CÓ' if bool(tool_context) and ('doanh' in tool_context.lower() or 'thống kê' in tool_context.lower() or 'revenue' in tool_context.lower()) else 'KHÔNG'}
                    
                    QUY TẮC XỬ LÝ PARTIAL SUCCESS:
                    1. Nếu product_search_result CÓ → Giới thiệu sản phẩm và hình ảnh (hình ảnh sẽ được hiển thị tự động)
                    2. Nếu product_search_result KHÔNG CÓ → Nói "Xin lỗi, hiện tại chúng tôi chưa có thông tin về [tên sản phẩm]"
                    3. Nếu sales_statistics_result CÓ → Hiển thị doanh thu theo tháng
                    4. Nếu sales_statistics_result KHÔNG CÓ → Không nói về doanh thu
                    5. TRẢ LỜI TẤT CẢ PHẦN CÓ DỮ LIỆU, không bỏ sót
                    6. KHÔNG được giả định dữ liệu không có - chỉ dựa vào FACT ở trên

                    === NHIỆM VỤ ===

                    BƯỚC 1 - PHÂN TÍCH (REASONING):
                    1. Xác định user muốn gì? (sản phẩm, doanh số, cả hai?)
                    2. Đánh giá thông tin có đủ không? (có phần nào, thiếu phần nào?)
                    3. Lập kế hoạch trả lời (format, cấu trúc) - trả lời phần có, nói rõ phần không có

                    BƯỚC 2 - TỔNG HỢP (SYNTHESIS):
                    Tạo câu trả lời CUỐI CÙNG, ĐẦY ĐỦ với format:

                    🔥 Nếu có CẢ sản phẩm VÀ doanh số:
                    🥩 Sản phẩm: [Tên sản phẩm]
                    [Mô tả ngắn về sản phẩm]
                    
                    📸 Hình ảnh sản phẩm:
                    (Hình ảnh sẽ được hiển thị kèm theo - KHÔNG xin lỗi về hình ảnh)
                    
                    📊 Doanh thu theo tháng ([Năm]):
                    Tháng 1: [số tiền]đ
                    Tháng 2: [số tiền]đ
                    ...
                    👉 [Nhận xét về tháng bán chạy nhất nếu có]

                     🔥 QUAN TRỌNG:
                     - KHÔNG được nói "xin lỗi, không thể cung cấp hình ảnh"
                     - Hình ảnh sẽ được hệ thống tự động hiển thị
                     - Trả lời bằng tiếng Việt, thân thiện và chuyên nghiệp
                     - Sử dụng TẤT CẢ thông tin có sẵn
                     
                     ⚠️ QUY TẮC NGHIÊM NGẶT - KHÔNG TỰ ĐỘNG SUGGEST:
                     - Nếu user hỏi về sản phẩm CỤ THỂ (ví dụ: "cá hồi") nhưng KHÔNG TÌM THẤY trong kết quả:
                       → PHẢI nói: "Xin lỗi, hiện tại chúng tôi chưa có thông tin về [tên sản phẩm user hỏi]"
                       → KHÔNG được suggest sản phẩm khác (ví dụ: "thịt bò", "sản phẩm tương tự")
                       → KHÔNG được nói "sản phẩm tương tự gần nhất"
                       → KHÔNG được tự động thay thế bằng sản phẩm khác
                     - CHỈ trả về sản phẩm NẾU nó KHỚP với tên sản phẩm user hỏi
                     - Nếu không tìm thấy → nói rõ là không tìm thấy, KHÔNG suggest thay thế

                    === FORMAT TRẢ LỜI ===
                    [REASONING]
                    [Kế hoạch và phân tích ngắn gọn - 2-3 câu]
                    [/REASONING]

                    [ANSWER]
                    [Câu trả lời cuối cùng đầy đủ cho khách hàng]
                    [/ANSWER]

                    Hoặc nếu đơn giản, chỉ cần trả lời trực tiếp (không cần tags).

                    === CÂU TRẢ LỜI CỦA BẠN ===
                """
        
        return prompt
    
    def _build_reasoning_context(
        self,
        query: str,
        knowledge_context: str,
        tool_context: str,
        reasoning_plan: str
    ) -> str:
        """Xây dựng reasoning context"""
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
        context_parts.append(reasoning_plan)
        
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
    
    def _calculate_confidence(
        self,
        knowledge_results: list,
        tool_context: str,
        reasoning_plan: str
    ) -> float:
        """Tính độ tin cậy của câu trả lời"""
        confidence = 0.0
        
        # Có kết quả từ RAG search
        if knowledge_results:
            max_similarity = max([r.get("similarity", 0) for r in knowledge_results], default=0)
            confidence += max_similarity * 0.5  # 50% từ RAG
        
        # Có thông tin từ database
        if tool_context:
            confidence += 0.3  # 30% từ database
        
        # Có reasoning
        if reasoning_plan:
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

