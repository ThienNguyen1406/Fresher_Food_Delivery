using System.Net.Http.Json;
using System.Text.Json;
using System;

namespace FressFood.Services
{
    /// <summary>
    /// Service tích hợp OpenAI API để xử lý câu hỏi phức tạp với Function Calling
    /// </summary>
    public class OpenAIService : IAIService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<OpenAIService> _logger;
        private readonly HttpClient _httpClient;
        private readonly string? _apiKey;
        private readonly string? _model;
        private readonly bool _isEnabled;
        private readonly IFunctionHandler? _functionHandler;

        public OpenAIService(
            IConfiguration configuration, 
            ILogger<OpenAIService> logger, 
            IHttpClientFactory httpClientFactory,
            IFunctionHandler? functionHandler = null)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _apiKey = _configuration["OpenAI:ApiKey"];
            _model = _configuration["OpenAI:Model"] ?? "gpt-3.5-turbo";
            _isEnabled = !string.IsNullOrEmpty(_apiKey);
            _functionHandler = functionHandler;

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
                // Kiểm tra xem context có chứa RAG context không
                bool hasRAGContext = !string.IsNullOrEmpty(context) && 
                                     (context.Contains("=== THÔNG TIN TỪ TÀI LIỆU ===") || 
                                      context.Contains("Thông tin liên quan từ tài liệu:") ||
                                      context.Contains("Thông tin từ tài liệu:"));
                
                var systemPrompt = @"Bạn là trợ lý tự động của Fresher Food - một ứng dụng giao thực phẩm tươi sống.
                                        Trách nhiệm của bạn:
                                        - Trả lời câu hỏi của khách hàng một cách thân thiện, chuyên nghiệp
                                        - Cung cấp thông tin về sản phẩm, đơn hàng, giao hàng, thanh toán, doanh thu, thống kê
                                        - Hướng dẫn khách hàng sử dụng ứng dụng
                                        - QUAN TRỌNG: Nếu có thông tin từ tài liệu (được đánh dấu === THÔNG TIN TỪ TÀI LIỆU === hoặc 'Thông tin liên quan từ tài liệu'), 
                                          bạn PHẢI ƯU TIÊN sử dụng thông tin đó để trả lời. KHÔNG được gọi function nếu thông tin đã có trong tài liệu.
                                          CHỈ gọi function khi: (1) Không có thông tin trong tài liệu, HOẶC (2) Cần dữ liệu real-time như số lượng tồn kho hiện tại, đơn hàng mới nhất.
                                        - Nếu thông tin trong tài liệu có đầy đủ để trả lời (tên sản phẩm, giá, mô tả), hãy sử dụng thông tin đó.
                                          KHÔNG được nói rằng bạn không có thông tin nếu thông tin đó có trong tài liệu.
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

                // Định nghĩa các functions có sẵn cho OpenAI Function Calling
                // Sử dụng object[] để tránh lỗi "No best type found for implicitly-typed array"
                object[] functions = new object[]
                {
                    new
                    {
                        name = "getProductsExpiringSoon",
                        description = "Lấy danh sách sản phẩm sắp hết hạn (trong vòng X ngày). Dùng khi user hỏi về sản phẩm gần hết hạn, sắp hết hạn, cần kiểm tra hạn sử dụng.",
                        parameters = new
                        {
                            type = "object",
                            properties = new
                            {
                                days = new
                                {
                                    type = "integer",
                                    description = "Số ngày còn lại trước khi hết hạn (mặc định: 7 ngày)"
                                }
                            }
                        }
                    },
                    new
                    {
                        name = "getActivePromotions",
                        description = "Lấy danh sách khuyến mãi đang hoạt động. Dùng khi user hỏi về khuyến mãi, giảm giá, sale, chương trình khuyến mãi hiện tại.",
                        parameters = new
                        {
                            type = "object",
                            properties = new
                            {
                                productId = new
                                {
                                    type = "string",
                                    description = "Mã sản phẩm cụ thể (tùy chọn). Nếu không có, trả về tất cả khuyến mãi."
                                },
                                limit = new
                                {
                                    type = "integer",
                                    description = "Số lượng khuyến mãi tối đa (mặc định: 20)"
                                }
                            }
                        }
                    },
                    new
                    {
                        name = "getProductInfo",
                        description = "Lấy thông tin chi tiết của một sản phẩm. Dùng khi user hỏi về thông tin sản phẩm cụ thể như tên, giá, mô tả, số lượng tồn kho, hạn sử dụng. Có thể tìm bằng tên sản phẩm hoặc mã sản phẩm. Ví dụ: 'giá bán của rau xanh', 'thông tin về cá hồi', 'sản phẩm táo'.",
                        parameters = new
                        {
                            type = "object",
                            properties = new
                            {
                                productId = new
                                {
                                    type = "string",
                                    description = "Mã sản phẩm (nếu có)"
                                },
                                productName = new
                                {
                                    type = "string",
                                    description = "Tên sản phẩm (có thể dùng thay cho productId). Ví dụ: 'rau xanh', 'cá hồi', 'táo', 'thịt bò'. Nếu user chỉ nói tên sản phẩm mà không có mã, dùng productName."
                                }
                            },
                            required = new string[] { }  // Không bắt buộc, có thể dùng productId hoặc productName
                        }
                    },
                    new
                    {
                        name = "getCategoryProducts",
                        description = "Lấy danh sách sản phẩm theo danh mục. Dùng khi user hỏi về sản phẩm trong một danh mục cụ thể như 'rau củ', 'trái cây', 'thịt cá', 'đồ uống'.",
                        parameters = new
                        {
                            type = "object",
                            properties = new
                            {
                                categoryName = new
                                {
                                    type = "string",
                                    description = "Tên danh mục sản phẩm. Ví dụ: 'Rau củ', 'Trái cây', 'Thịt cá', 'Đồ uống'"
                                },
                                limit = new
                                {
                                    type = "integer",
                                    description = "Số lượng sản phẩm tối đa (mặc định: 20)"
                                }
                            },
                            required = new[] { "categoryName" }
                        }
                    },
                    new
                    {
                        name = "getTopProducts",
                        description = "Lấy danh sách sản phẩm bán chạy nhất. Dùng khi user hỏi về sản phẩm phổ biến, bán chạy, nổi bật.",
                        parameters = new
                        {
                            type = "object",
                            properties = new
                            {
                                limit = new
                                {
                                    type = "integer",
                                    description = "Số lượng sản phẩm (mặc định: 10)"
                                }
                            }
                        }
                    }
                };

                // Nếu có RAG context, chỉ cho phép gọi function cho các trường hợp cần real-time data
                // Các function cần real-time: getProductsExpiringSoon, getActivePromotions (có thể thay đổi theo thời gian)
                // Các function có thể dùng RAG: getProductInfo, getTopProducts (nếu đã có trong RAG)
                object[] functionsToUse = functions;
                string functionCallMode = "auto";
                
                if (hasRAGContext)
                {
                    _logger.LogInformation("RAG context detected. Restricting function calls to real-time data only.");
                    // Chỉ cho phép các function cần real-time data
                    functionsToUse = new object[]
                    {
                        new
                        {
                            name = "getProductsExpiringSoon",
                            description = "Lấy danh sách sản phẩm sắp hết hạn (trong vòng X ngày). Dùng khi user hỏi về sản phẩm gần hết hạn, sắp hết hạn, cần kiểm tra hạn sử dụng. CHỈ gọi khi cần dữ liệu real-time về hạn sử dụng.",
                            parameters = new
                            {
                                type = "object",
                                properties = new
                                {
                                    days = new
                                    {
                                        type = "integer",
                                        description = "Số ngày còn lại trước khi hết hạn (mặc định: 7 ngày)"
                                    }
                                }
                            }
                        },
                        new
                        {
                            name = "getActivePromotions",
                            description = "Lấy danh sách khuyến mãi đang hoạt động. Dùng khi user hỏi về khuyến mãi, giảm giá, sale, chương trình khuyến mãi hiện tại. CHỈ gọi khi cần dữ liệu real-time về khuyến mãi.",
                            parameters = new
                            {
                                type = "object",
                                properties = new
                                {
                                    productId = new
                                    {
                                        type = "string",
                                        description = "Mã sản phẩm cụ thể (tùy chọn). Nếu không có, trả về tất cả khuyến mãi."
                                    },
                                    limit = new
                                    {
                                        type = "integer",
                                        description = "Số lượng khuyến mãi tối đa (mặc định: 20)"
                                    }
                                }
                            }
                        }
                    };
                    // Vẫn cho phép auto nhưng chỉ với functions hạn chế
                    functionCallMode = "auto";
                }
                
                var requestBody = new
                {
                    model = _model,
                    messages = messages,
                    functions = functionsToUse,
                    function_call = functionCallMode,  // Cho phép AI tự quyết định khi nào gọi function
                    max_tokens = 500,  // Tăng lên để có thể trả lời dài hơn khi có function results
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
                        if (firstChoice.TryGetProperty("message", out var message))
                        {
                            // Kiểm tra xem có function call không
                            if (message.TryGetProperty("function_call", out var functionCall))
                            {
                                // AI muốn gọi function
                                var functionName = functionCall.TryGetProperty("name", out var nameProp) 
                                    ? nameProp.GetString() 
                                    : null;
                                var functionArgs = functionCall.TryGetProperty("arguments", out var argsProp) 
                                    ? argsProp.GetString() 
                                    : "{}";

                                if (!string.IsNullOrEmpty(functionName) && _functionHandler != null)
                                {
                                    _logger.LogInformation($"OpenAI requested function call: {functionName} with args: {functionArgs}");

                                    // Parse arguments
                                    var arguments = JsonSerializer.Deserialize<Dictionary<string, object>>(functionArgs) 
                                        ?? new Dictionary<string, object>();

                                    // Thực thi function
                                    var functionResult = await _functionHandler.ExecuteFunctionAsync(functionName, arguments);

                                    if (!string.IsNullOrEmpty(functionResult))
                                    {
                                        _logger.LogInformation($"Function {functionName} executed successfully. Result length: {functionResult.Length}");

                                        // Gửi lại kết quả function cho OpenAI để tạo câu trả lời cuối cùng
                                        messages.Add(new 
                                        { 
                                            role = "assistant", 
                                            content = (string?)null,
                                            function_call = new
                                            {
                                                name = functionName,
                                                arguments = functionArgs
                                            }
                                        });
                                        messages.Add(new 
                                        { 
                                            role = "function", 
                                            name = functionName,
                                            content = functionResult
                                        });

                                        // Gọi lại OpenAI với function result
                                        var secondRequestBody = new
                                        {
                                            model = _model,
                                            messages = messages,
                                            functions = functions,
                                            function_call = "auto",
                                            max_tokens = 500,
                                            temperature = 0.7
                                        };

                                        var secondResponse = await _httpClient.PostAsJsonAsync("chat/completions", secondRequestBody);
                                        
                                        if (secondResponse.IsSuccessStatusCode)
                                        {
                                            var secondResponseData = await secondResponse.Content.ReadFromJsonAsync<JsonElement>();
                                            if (secondResponseData.TryGetProperty("choices", out var secondChoices) && 
                                                secondChoices.GetArrayLength() > 0)
                                            {
                                                var secondFirstChoice = secondChoices[0];
                                                if (secondFirstChoice.TryGetProperty("message", out var secondMessage) &&
                                                    secondMessage.TryGetProperty("content", out var secondContent))
                                                {
                                                    var finalResponse = secondContent.GetString();
                                                    if (!string.IsNullOrEmpty(finalResponse))
                                                    {
                                                        _logger.LogInformation($"OpenAI final response with function result: {finalResponse.Substring(0, Math.Min(100, finalResponse.Length))}...");
                                                        return finalResponse;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            else if (message.TryGetProperty("content", out var content))
                            {
                                // Trả lời thông thường (không có function call)
                                var aiResponse = content.GetString();
                                if (!string.IsNullOrEmpty(aiResponse))
                                {
                                    var preview = aiResponse.Length > 50 ? aiResponse.Substring(0, 50) : aiResponse;
                                    _logger.LogInformation($"OpenAI response received: {preview}...");
                                    return aiResponse;
                                }
                            }
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
