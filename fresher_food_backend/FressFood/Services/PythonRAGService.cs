using System.Net.Http.Json;
using System.Text.Json;
using System.Text;

namespace FressFood.Services
{
    /// <summary>
    /// Service gọi Python RAG service qua HTTP API
    /// </summary>
    public class PythonRAGService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<PythonRAGService> _logger;
        private readonly HttpClient _httpClient;
        private readonly string _ragServiceUrl;

        public PythonRAGService(
            IConfiguration configuration,
            ILogger<PythonRAGService> logger,
            IHttpClientFactory httpClientFactory)
        {
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClientFactory.CreateClient();
            _httpClient.Timeout = TimeSpan.FromSeconds(60); // Tăng timeout lên 60 giây
            _ragServiceUrl = _configuration["RAGService:Url"] ?? "http://localhost:8000";
            _logger.LogInformation($"PythonRAGService initialized with URL: {_ragServiceUrl}");
        }

        /// <summary>
        /// Upload và xử lý document
        /// </summary>
        public async Task<ProcessDocumentResponse?> ProcessAndStoreDocumentAsync(Stream fileStream, string fileName)
        {
            try
            {
                var url = $"{_ragServiceUrl}/api/documents/upload";
                
                using var content = new MultipartFormDataContent();
                var streamContent = new StreamContent(fileStream);
                streamContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("application/octet-stream");
                content.Add(streamContent, "file", fileName);

                var response = await _httpClient.PostAsync(url, content);
                
                if (response.IsSuccessStatusCode)
                {
                    var result = await response.Content.ReadFromJsonAsync<ProcessDocumentResponse>();
                    _logger.LogInformation($"Document processed successfully: {fileName}");
                    return result;
                }
                else
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"Error processing document: {response.StatusCode} - {errorContent}");
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error calling Python RAG service for document processing");
                return null;
            }
        }

        /// <summary>
        /// Retrieve context từ vector store
        /// </summary>
        public async Task<RetrieveContextResponse?> RetrieveContextAsync(string query, int topK = 5, string? fileId = null)
        {
            try
            {
                var url = $"{_ragServiceUrl}/api/query/retrieve";
                _logger.LogInformation($"Calling RAG service: {url} with query: '{query.Substring(0, Math.Min(100, query.Length))}...'");
                
                var request = new
                {
                    question = query,
                    file_id = fileId,
                    top_k = topK
                };

                _logger.LogInformation($"Sending request to RAG service: {System.Text.Json.JsonSerializer.Serialize(request)}");
                
                var response = await _httpClient.PostAsJsonAsync(url, request);
                
                _logger.LogInformation($"RAG service response status: {response.StatusCode}");
                
                if (response.IsSuccessStatusCode)
                {
                    var responseContent = await response.Content.ReadAsStringAsync();
                    _logger.LogInformation($"RAG service response content length: {responseContent.Length} chars");
                    
                    var result = await response.Content.ReadFromJsonAsync<RetrieveContextResponse>();
                    
                    if (result != null)
                    {
                        _logger.LogInformation($"Retrieved context: HasContext={result.HasContext}, Chunks count={result.Chunks?.Count ?? 0}, Context length={result.Context?.Length ?? 0}");
                    }
                    else
                    {
                        _logger.LogWarning("RAG service returned success but result is null. Response content: " + responseContent.Substring(0, Math.Min(500, responseContent.Length)));
                    }
                    
                    return result;
                }
                else
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"Error retrieving context: {response.StatusCode} - {errorContent}");
                    return null;
                }
            }
            catch (TaskCanceledException ex)
            {
                _logger.LogError(ex, $"RAG service request timeout after {_httpClient.Timeout.TotalSeconds} seconds");
                return null;
            }
            catch (HttpRequestException ex)
            {
                _logger.LogError(ex, $"HTTP error calling RAG service at {_ragServiceUrl}. Is the service running?");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error calling Python RAG service for context retrieval: {ex.Message}");
                _logger.LogError(ex, $"Stack trace: {ex.StackTrace}");
                return null;
            }
        }

        /// <summary>
        /// Lấy danh sách tất cả documents
        /// </summary>
        public async Task<List<DocumentInfo>> GetAllDocumentsAsync()
        {
            try
            {
                var url = $"{_ragServiceUrl}/api/documents";
                var response = await _httpClient.GetAsync(url);
                
                if (response.IsSuccessStatusCode)
                {
                    var documents = await response.Content.ReadFromJsonAsync<List<DocumentInfo>>();
                    return documents ?? new List<DocumentInfo>();
                }
                else
                {
                    _logger.LogError($"Error getting documents: {response.StatusCode}");
                    return new List<DocumentInfo>();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling Python RAG service to get documents");
                return new List<DocumentInfo>();
            }
        }

        /// <summary>
        /// Xóa document
        /// </summary>
        public async Task<bool> DeleteDocumentAsync(string fileId)
        {
            try
            {
                var url = $"{_ragServiceUrl}/api/documents/{fileId}";
                var response = await _httpClient.DeleteAsync(url);
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation($"Document {fileId} deleted successfully");
                    return true;
                }
                else
                {
                    _logger.LogError($"Error deleting document: {response.StatusCode}");
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error calling Python RAG service to delete document {fileId}");
                return false;
            }
        }

        /// <summary>
        /// Kiểm tra Python RAG service có đang chạy không
        /// </summary>
        public async Task<bool> IsServiceAvailableAsync()
        {
            try
            {
                var url = $"{_ragServiceUrl}/health";
                var response = await _httpClient.GetAsync(url);
                return response.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }
    }

    public class ProcessDocumentResponse
    {
        public string FileId { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public int TotalChunks { get; set; }
        public string Message { get; set; } = string.Empty;
    }

    public class RetrieveContextResponse
    {
        public string Context { get; set; } = string.Empty;
        public List<RetrievedChunkInfo> Chunks { get; set; } = new();
        public bool HasContext { get; set; }
    }

    public class RetrievedChunkInfo
    {
        public string ChunkId { get; set; } = string.Empty;
        public string? FileId { get; set; }
        public string FileName { get; set; } = string.Empty;
        public int ChunkIndex { get; set; }
        public string Text { get; set; } = string.Empty;
        public float Similarity { get; set; }
    }

    public class DocumentInfo
    {
        public string FileId { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public string? FileType { get; set; }
        public int TotalChunks { get; set; }
        public string UploadDate { get; set; } = string.Empty;
    }
}

