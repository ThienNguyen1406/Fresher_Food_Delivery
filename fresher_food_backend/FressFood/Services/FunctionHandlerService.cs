using System.Net.Http.Json;
using System.Text.Json;

namespace FressFood.Services
{
    /// <summary>
    /// Service gọi Python Function Handler service qua HTTP API
    /// </summary>
    public class FunctionHandlerService : IFunctionHandler
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<FunctionHandlerService> _logger;
        private readonly HttpClient _httpClient;
        private readonly string _ragServiceUrl;

        public FunctionHandlerService(
            IConfiguration configuration,
            ILogger<FunctionHandlerService> logger,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
            _ragServiceUrl = _configuration["RAGService:Url"] ?? "http://localhost:8000";
            _logger.LogInformation($"FunctionHandlerService initialized with URL: {_ragServiceUrl}");
        }

        /// <summary>
        /// Thực thi function call và trả về kết quả dưới dạng JSON string
        /// </summary>
        public async Task<string?> ExecuteFunctionAsync(string functionName, Dictionary<string, object> arguments)
        {
            try
            {
                var url = $"{_ragServiceUrl}/api/functions/execute";
                _logger.LogInformation($"Calling function handler: {functionName} with {arguments.Count} arguments");

                var request = new
                {
                    function_name = functionName,
                    arguments = arguments
                };

                var response = await _httpClient.PostAsJsonAsync(url, request);

                if (response.IsSuccessStatusCode)
                {
                    var result = await response.Content.ReadAsStringAsync();
                    _logger.LogInformation($"Function {functionName} executed successfully");
                    return result;
                }
                else
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"Error executing function {functionName}: {response.StatusCode} - {errorContent}");
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error calling function handler for {functionName}");
                return null;
            }
        }
    }
}

