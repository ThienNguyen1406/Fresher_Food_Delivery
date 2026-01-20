using System.Net.Http.Json;
using System.Text.Json;

namespace FressFood.Services
{
    /// <summary>
    /// Function Handler sử dụng Python service để xử lý function calls
    /// </summary>
    public class PythonFunctionHandler : IFunctionHandler
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<PythonFunctionHandler> _logger;
        private readonly HttpClient _httpClient;
        private readonly string _ragServiceUrl;

        public PythonFunctionHandler(
            IConfiguration configuration,
            ILogger<PythonFunctionHandler> logger,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
            _ragServiceUrl = _configuration["RAGService:Url"] ?? "http://localhost:8000";
            _logger.LogInformation($"PythonFunctionHandler initialized with URL: {_ragServiceUrl}");
        }

        /// <summary>
        /// Thực thi function call thông qua Python service
        /// </summary>
        public async Task<string> ExecuteFunctionCallAsync(string functionName, string argumentsJson)
        {
            try
            {
                _logger.LogInformation($"Executing function call via Python service: {functionName} with arguments: {argumentsJson}");

                // Parse arguments từ JSON string
                var arguments = JsonSerializer.Deserialize<Dictionary<string, object>>(argumentsJson) 
                    ?? new Dictionary<string, object>();

                var url = $"{_ragServiceUrl}/api/functions/execute";
                
                var request = new
                {
                    function_name = functionName,
                    arguments = arguments
                };

                var response = await _httpClient.PostAsJsonAsync(url, request);

                if (response.IsSuccessStatusCode)
                {
                    var result = await response.Content.ReadFromJsonAsync<FunctionCallResponse>();
                    
                    if (result != null && result.Success)
                    {
                        _logger.LogInformation($"Function {functionName} executed successfully via Python service");
                        return result.Result;
                    }
                    else
                    {
                        var error = result?.Error ?? "Unknown error";
                        _logger.LogError($"Function {functionName} failed: {error}");
                        return JsonSerializer.Serialize(new
                        {
                            error = error
                        });
                    }
                }
                else
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"Error calling Python function service: {response.StatusCode} - {errorContent}");
                    return JsonSerializer.Serialize(new
                    {
                        error = $"Lỗi khi gọi Python function service: {response.StatusCode}"
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error executing function call {functionName} via Python service");
                return JsonSerializer.Serialize(new
                {
                    error = $"Lỗi khi thực thi function {functionName}: {ex.Message}"
                });
            }
        }

        private class FunctionCallResponse
        {
            public string Result { get; set; } = string.Empty;
            public bool Success { get; set; }
            public string? Error { get; set; }
        }
    }
}

