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
            "Bạn là trợ lý AI thông minh cho hệ thống quản lý thực phẩm tươi sống. "
            "Bạn có thể trả lời các câu hỏi về sản phẩm, đơn hàng, và các thông tin khác trong hệ thống. "
            "Hãy trả lời một cách thân thiện, chính xác và hữu ích."
        )

