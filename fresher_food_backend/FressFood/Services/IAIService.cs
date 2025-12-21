namespace FressFood.Services
{
    /// <summary>
    /// Interface cho AI Service để xử lý câu hỏi phức tạp
    /// </summary>
    public interface IAIService
    {
        /// <summary>
        /// Gửi câu hỏi đến AI và nhận câu trả lời
        /// </summary>
        /// <param name="userMessage">Tin nhắn từ user</param>
        /// <param name="context">Ngữ cảnh bổ sung (tùy chọn)</param>
        /// <returns>Câu trả lời từ AI hoặc null nếu có lỗi</returns>
        Task<string?> GetAIResponseAsync(string userMessage, string? context = null);
    }
}
