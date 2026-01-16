using System.Net.Http.Json;
using System.Text.Json;

namespace FressFood.Services
{
    /// <summary>
    /// Service tích hợp OpenAI API để xử lý câu hỏi phức tạp
    /// </summary>
    public class OpenAIService : IAIService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<OpenAIService> _logger;
        private readonly HttpClient _httpClient;
        private readonly string? _apiKey;
        private readonly string? _model;
        private readonly bool _isEnabled;

        public OpenAIService(IConfiguration configuration, ILogger<OpenAIService> logger, IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _apiKey = _configuration["OpenAI:ApiKey"];
            _model = _configuration["OpenAI:Model"] ?? "gpt-3.5-turbo";
            _isEnabled = !string.IsNullOrEmpty(_apiKey);

            if (_isEnabled)
            {
                _httpClient.BaseAddress = new Uri("https://api.openai.com/v1/");
                _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {_apiKey}");
            }
            else
            {
                _logger.LogWarning("OpenAI API key not configured. AI features will be disabled.");
            }
        }

        public async Task<string?> GetAIResponseAsync(string userMessage, string? context = null)
        {
            if (!_isEnabled)
            {
                _logger.LogWarning("OpenAI service is disabled. Returning null.");
                return null;
            }

            try
            {
                var systemPrompt = @"Bạn là trợ lý tự động của Fresher Food - một ứng dụng giao thực phẩm tươi sống.
                                        Trách nhiệm của bạn:
                                        - Trả lời câu hỏi của khách hàng một cách thân thiện, chuyên nghiệp
                                        - Cung cấp thông tin về sản phẩm, đơn hàng, giao hàng, thanh toán, doanh thu, thống kê
                                        - Hướng dẫn khách hàng sử dụng ứng dụng
                                        - QUAN TRỌNG: Nếu có thông tin từ tài liệu (được đánh dấu === THÔNG TIN TỪ TÀI LIỆU ===), 
                                          bạn PHẢI sử dụng thông tin đó để trả lời. KHÔNG được nói rằng bạn không có thông tin 
                                          nếu thông tin đó có trong tài liệu.
                                        - BẠN CÓ THỂ trả lời các câu hỏi về doanh thu, thống kê, đơn hàng nếu thông tin đó có trong tài liệu.
                                          KHÔNG được từ chối trả lời về doanh thu/đơn hàng nếu thông tin có trong tài liệu.
                                        - Nếu user đề cập đến 'số đó', 'nó', 'cái đó', 'kết quả đó', 'số vừa rồi' hoặc các từ thay thế tương tự, 
                                          hãy tham chiếu đến thông tin từ lịch sử hội thoại trước đó để hiểu user đang nói về cái gì.
                                        - Nếu không có thông tin trong tài liệu và không biết câu trả lời, hãy đề nghị khách hàng liên hệ admin

                                        Trả lời bằng tiếng Việt, ngắn gọn và dễ hiểu (tối đa 300 từ).";

                var messages = new List<object>
                {
                    new { role = "system", content = systemPrompt }
                };

                // Thêm context nếu có (có thể chứa conversation history và RAG context)
                if (!string.IsNullOrEmpty(context))
                {
                    // Parse context: có thể chứa "Lịch sử hội thoại:" và "=== THÔNG TIN TỪ TÀI LIỆU ==="
                    var contextToAdd = context;
                    
                    // Nếu context chứa "Lịch sử hội thoại:", parse và thêm vào messages
                    if (context.Contains("Lịch sử hội thoại:"))
                    {
                        var parts = context.Split(new[] { "Lịch sử hội thoại:" }, StringSplitOptions.None);
                        if (parts.Length > 1)
                        {
                            // Lấy phần trước "Lịch sử hội thoại:" (ngữ cảnh chung)
                            var beforeHistory = parts[0].Trim();
                            
                            // Lấy phần sau "Lịch sử hội thoại:" và tách ra
                            var afterHistory = parts[1];
                            var historyAndRest = afterHistory.Split(new[] { "\n\n" }, 2, StringSplitOptions.None);
                            var historyPart = historyAndRest[0];
                            var restContext = historyAndRest.Length > 1 ? historyAndRest[1] : "";
                            
                            // Thêm ngữ cảnh chung (nếu có)
                            if (!string.IsNullOrWhiteSpace(beforeHistory))
                            {
                                messages.Add(new { role = "system", content = beforeHistory });
                            }
                            
                            // Parse conversation history và thêm vào messages
                            var historyLines = historyPart.Split('\n', StringSplitOptions.RemoveEmptyEntries);
                            foreach (var line in historyLines)
                            {
                                if (line.Contains("User:") || line.Contains("Assistant:"))
                                {
                                    var role = line.StartsWith("User:") ? "user" : "assistant";
                                    var content = line.Substring(line.IndexOf(':') + 1).Trim();
                                    if (!string.IsNullOrEmpty(content))
                                    {
                                        messages.Add(new { role = role, content = content });
                                    }
                                }
                            }
                            
                            // Thêm phần còn lại (RAG context, etc.) - QUAN TRỌNG
                            if (!string.IsNullOrWhiteSpace(restContext))
                            {
                                messages.Add(new { role = "system", content = restContext });
                            }
                        }
                    }
                    else
                    {
                        // Context thông thường (không có conversation history) - thêm toàn bộ context
                        messages.Add(new { role = "system", content = context });
                    }
                }

                messages.Add(new { role = "user", content = userMessage });

                var requestBody = new
                {
                    model = _model,
                    messages = messages,
                    max_tokens = 300,
                    temperature = 0.7
                };

                var response = await _httpClient.PostAsJsonAsync("chat/completions", requestBody);
                
                if (response.IsSuccessStatusCode)
                {
                    var responseData = await response.Content.ReadFromJsonAsync<JsonElement>();
                    
                    if (responseData.TryGetProperty("choices", out var choices) && 
                        choices.GetArrayLength() > 0)
                    {
                        var firstChoice = choices[0];
                        if (firstChoice.TryGetProperty("message", out var message) &&
                            message.TryGetProperty("content", out var content))
                        {
                            var aiResponse = content.GetString();
                            if (!string.IsNullOrEmpty(aiResponse))
                            {
                                var preview = aiResponse.Length > 50 ? aiResponse.Substring(0, 50) : aiResponse;
                                _logger.LogInformation($"OpenAI response received: {preview}...");
                            }
                            return aiResponse;
                        }
                    }
                }
                else
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"OpenAI API error: {response.StatusCode} - {errorContent}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling OpenAI API");
            }

            return null;
        }
    }
}
