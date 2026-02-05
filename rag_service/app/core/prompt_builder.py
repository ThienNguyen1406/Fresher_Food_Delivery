"""
Prompt Builder - Xây dựng prompts cho LLM
Tạo các prompt được format tốt để LLM có thể hiểu và trả lời chính xác
"""
from typing import Optional


class PromptBuilder:
    """
    Xây dựng prompts cho LLM
    
    Prompt là cách chúng ta giao tiếp với LLM:
    - Cung cấp context từ tài liệu
    - Đưa ra hướng dẫn rõ ràng
    - Đảm bảo LLM trả lời dựa trên thông tin đúng
    """
    
    @staticmethod
    def build_rag_prompt(
        question: str, 
        context: Optional[str] = None,
        conversation_history: Optional[str] = None
    ) -> str:
        """
        Xây dựng prompt cho RAG-based question answering
        
        Prompt này bao gồm:
        - Lịch sử hội thoại (nếu có)
        - Context từ tài liệu (nếu có)
        - Hướng dẫn rõ ràng cho LLM
        - Câu hỏi của người dùng
        
        Args:
            question: Câu hỏi của người dùng
            context: Ngữ cảnh đã tìm được từ tài liệu (tùy chọn)
            conversation_history: Lịch sử hội thoại trước đó (tùy chọn)
            
        Returns:
            Prompt đã được format
        """
        prompt_parts = []
        
        # Thêm lịch sử hội thoại nếu có
        if conversation_history:
            prompt_parts.append("=== LỊCH SỬ HỘI THOẠI ===")
            prompt_parts.append(conversation_history)
            prompt_parts.append("")
        
        # Thêm context từ tài liệu nếu có
        if context:
            prompt_parts.append("=== THÔNG TIN TỪ TÀI LIỆU ===")
            prompt_parts.append(context)
            prompt_parts.append("")
            # Hướng dẫn quan trọng: LLM PHẢI dựa vào context
            prompt_parts.append("QUAN TRỌNG: Bạn PHẢI trả lời câu hỏi của user dựa TRỰC TIẾP trên thông tin từ tài liệu ở trên. "
                              "Thông tin trong tài liệu là CHÍNH XÁC và ĐÁNG TIN CẬY. "
                              "Nếu câu hỏi của user liên quan đến thông tin trong tài liệu, bạn PHẢI sử dụng thông tin đó để trả lời một cách CHI TIẾT và CHÍNH XÁC. "
                              "KHÔNG được nói rằng bạn không có thông tin nếu thông tin đó có trong tài liệu.")
        else:
            # Nếu không có context, dùng prompt chung
            prompt_parts.append("Bạn là trợ lý AI thông minh. Hãy trả lời câu hỏi của người dùng một cách hữu ích và chính xác.")
        
        prompt_parts.append("")
        prompt_parts.append("=== CÂU HỎI CỦA NGƯỜI DÙNG ===")
        prompt_parts.append(question)
        
        return "\n".join(prompt_parts)
    
    @staticmethod
    def build_system_prompt() -> str:
        """
        Xây dựng system prompt cho LLM
        
        System prompt định nghĩa vai trò và hành vi của LLM
        
        Returns:
            System prompt string
        """
        return (
            "Bạn là trợ lý AI thông minh cho hệ thống quản lý thực phẩm tươi sống Fresher Food Delivery. "
            "Bạn có thể trả lời các câu hỏi về:\n"
            "- Sản phẩm: tìm kiếm, thông tin, giá cả, hình ảnh\n"
            "- Đơn hàng: trạng thái, lịch sử\n"
            "- Doanh số và thống kê: doanh thu theo tháng, thống kê bán hàng\n"
            "- Giao hàng và thanh toán\n\n"
            "Nguyên tắc trả lời:\n"
            "1. Sử dụng TẤT CẢ thông tin có sẵn từ lịch sử hội thoại và tài liệu\n"
            "2. Xử lý đầy đủ multi-part queries (ví dụ: hình ảnh + doanh số)\n"
            "3. Format rõ ràng, dễ đọc với số liệu cụ thể\n"
            "4. Trả lời bằng tiếng Việt, thân thiện và chuyên nghiệp\n"
            "5. Nếu thiếu thông tin, nói rõ và đề nghị hỗ trợ thêm"
        )
    
    @staticmethod
    def build_image_search_description_prompt(
        products: list,
        user_description: Optional[str] = None
    ) -> str:
        """
        Xây dựng prompt để LLM tạo mô tả từ kết quả tìm kiếm bằng ảnh
        
        Args:
            products: Danh sách sản phẩm tìm được (có product_name, category_name, price, similarity)
            user_description: Mô tả của người dùng về ảnh (nếu có)
            
        Returns:
            Prompt string để LLM tạo mô tả
        """
        prompt_parts = []
        
        prompt_parts.append("Bạn là trợ lý AI cho hệ thống tìm kiếm sản phẩm bằng ảnh.")
        prompt_parts.append("Người dùng đã tìm kiếm sản phẩm bằng cách upload một bức ảnh.")
        
        if user_description:
            prompt_parts.append(f"Mô tả của người dùng về ảnh: {user_description}")
        
        prompt_parts.append("")
        prompt_parts.append("Dưới đây là các sản phẩm tương tự đã tìm được:")
        prompt_parts.append("")
        
        for i, product in enumerate(products[:10], 1):
            name = product.get('product_name', 'N/A')
            category = product.get('category_name', '')
            price = product.get('price')
            similarity = product.get('similarity', 0.0)
            
            product_info = f"{i}. {name}"
            if category:
                product_info += f" (Danh mục: {category})"
            if price:
                product_info += f" - Giá: {price:,.0f}đ"
            product_info += f" - Độ tương đồng: {similarity*100:.1f}%"
            
            prompt_parts.append(product_info)
        
        prompt_parts.append("")
        prompt_parts.append("Hãy tạo một mô tả ngắn gọn, tự nhiên và thân thiện về kết quả tìm kiếm này.")
        prompt_parts.append("Mô tả nên:")
        prompt_parts.append("- Chào hỏi người dùng")
        prompt_parts.append("- Nêu số lượng sản phẩm tìm được")
        prompt_parts.append("- Giới thiệu 2-3 sản phẩm nổi bật nhất (tên, giá)")
        prompt_parts.append("- Gợi ý người dùng có thể xem thêm nếu muốn")
        prompt_parts.append("- Viết bằng tiếng Việt, tự nhiên như đang trò chuyện")
        prompt_parts.append("- Giới hạn trong 150-200 từ")
        
        return "\n".join(prompt_parts)

