namespace FressFood.Services
{
    /// <summary>
    /// Interface cho Function Handler Service để xử lý function calling từ AI
    /// </summary>
    public interface IFunctionHandler
    {
        /// <summary>
        /// Thực thi function call và trả về kết quả dưới dạng JSON string
        /// </summary>
        /// <param name="functionName">Tên function cần thực thi</param>
        /// <param name="arguments">Arguments của function (dictionary)</param>
        /// <returns>JSON string chứa kết quả hoặc null nếu có lỗi</returns>
        Task<string?> ExecuteFunctionAsync(string functionName, Dictionary<string, object> arguments);
    }
}

