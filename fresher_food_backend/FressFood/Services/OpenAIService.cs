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
                                        - Cung cấp thông tin về sản phẩm, đơn hàng, giao hàng, thanh toán
                                        - Hướng dẫn khách hàng sử dụng ứng dụng
                                        - Nếu không biết câu trả lời, hãy đề nghị khách hàng liên hệ admin

                                        Trả lời bằng tiếng Việt, ngắn gọn và dễ hiểu (tối đa 200 từ).";

                var messages = new List<object>
                {
                    new { role = "system", content = systemPrompt }
                };

                // Thêm context nếu có
                if (!string.IsNullOrEmpty(context))
                {
                    messages.Add(new { role = "system", content = $"Ngữ cảnh: {context}" });
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
