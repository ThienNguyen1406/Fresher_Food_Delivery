using System.Net.Http.Json;
using System.Text.Json;

namespace FressFood.Services
{
    /// <summary>
    /// Service tạo embeddings từ text sử dụng OpenAI Embeddings API
    /// </summary>
    public class EmbeddingService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmbeddingService> _logger;
        private readonly HttpClient _httpClient;
        private readonly string? _apiKey;
        private readonly string _model;
        private readonly bool _isEnabled;

        public EmbeddingService(IConfiguration configuration, ILogger<EmbeddingService> logger, IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _apiKey = _configuration["OpenAI:ApiKey"];
            _model = _configuration["OpenAI:EmbeddingModel"] ?? "text-embedding-3-small";
            _isEnabled = !string.IsNullOrEmpty(_apiKey);

            if (_isEnabled)
            {
                _httpClient.BaseAddress = new Uri("https://api.openai.com/v1/");
                _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {_apiKey}");
            }
            else
            {
                _logger.LogWarning("OpenAI API key not configured. Embedding features will be disabled.");
            }
        }

        /// <summary>
        /// Tạo embedding vector từ text
        /// </summary>
        public async Task<float[]?> CreateEmbeddingAsync(string text)
        {
            if (!_isEnabled)
            {
                _logger.LogWarning("Embedding service is disabled. Returning null.");
                return null;
            }

            if (string.IsNullOrWhiteSpace(text))
            {
                return null;
            }

            try
            {
                var requestBody = new
                {
                    model = _model,
                    input = text,
                    encoding_format = "float"
                };

                var response = await _httpClient.PostAsJsonAsync("embeddings", requestBody);
                
                if (response.IsSuccessStatusCode)
                {
                    var responseData = await response.Content.ReadFromJsonAsync<JsonElement>();
                    
                    if (responseData.TryGetProperty("data", out var data) && 
                        data.GetArrayLength() > 0)
                    {
                        var firstItem = data[0];
                        if (firstItem.TryGetProperty("embedding", out var embedding))
                        {
                            var embeddingArray = new List<float>();
                            foreach (var value in embedding.EnumerateArray())
                            {
                                embeddingArray.Add((float)value.GetDouble());
                            }
                            
                            _logger.LogInformation($"Created embedding with {embeddingArray.Count} dimensions");
                            return embeddingArray.ToArray();
                        }
                    }
                }
                else
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"OpenAI Embeddings API error: {response.StatusCode} - {errorContent}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating embedding");
            }

            return null;
        }

        /// <summary>
        /// Tạo embeddings cho nhiều texts cùng lúc (batch)
        /// </summary>
        public async Task<List<float[]?>> CreateEmbeddingsAsync(List<string> texts)
        {
            if (!_isEnabled || texts == null || texts.Count == 0)
            {
                return new List<float[]?>();
            }

            var embeddings = new List<float[]?>();
            
            // OpenAI hỗ trợ batch, nhưng để đơn giản, xử lý từng cái
            // Có thể tối ưu sau bằng cách gửi batch request
            foreach (var text in texts)
            {
                var embedding = await CreateEmbeddingAsync(text);
                embeddings.Add(embedding);
            }

            return embeddings;
        }
    }
}

