using System;

namespace FressFood.Services
{
    /// <summary>
    /// Service chính tích hợp RAG (Retrieval Augmented Generation) - LEGACY
    /// Đã chuyển sang dùng PythonRAGService, service này không còn được sử dụng
    /// </summary>
    [Obsolete("Use PythonRAGService instead")]
    public class RAGService
    {
        private readonly DocumentProcessor _documentProcessor;
        private readonly EmbeddingService _embeddingService;
        private readonly VectorStoreService _vectorStore;
        private readonly ILogger<RAGService> _logger;

        public RAGService(
            DocumentProcessor documentProcessor,
            EmbeddingService embeddingService,
            VectorStoreService vectorStore,
            ILogger<RAGService> logger)
        {
            _documentProcessor = documentProcessor;
            _embeddingService = embeddingService;
            _vectorStore = vectorStore;
            _logger = logger;
        }

        /// <summary>
        /// Xử lý và lưu trữ document vào vector store
        /// </summary>
        public async Task<string> ProcessAndStoreDocumentAsync(Stream fileStream, string fileName)
        {
            try
            {
                var fileId = $"DOC-{Guid.NewGuid().ToString().Substring(0, 8)}";
                var fileType = Path.GetExtension(fileName).ToLower();

                _logger.LogInformation($"Processing document: {fileName} (ID: {fileId})");

                // 1. Extract và chunk text
                var chunks = await _documentProcessor.ProcessDocumentAsync(fileStream, fileName, fileId);
                
                if (chunks.Count == 0)
                {
                    throw new Exception("No text extracted from document");
                }

                // 2. Tạo embeddings cho các chunks
                var texts = chunks.Select(c => c.Text).ToList();
                var embeddings = await _embeddingService.CreateEmbeddingsAsync(texts);

                // 3. Lưu document metadata
                await _vectorStore.SaveDocumentAsync(fileId, fileName, fileType);

                // 4. Lưu chunks với embeddings
                await _vectorStore.SaveChunksAsync(chunks, embeddings);

                _logger.LogInformation($"Successfully processed and stored document {fileName} with {chunks.Count} chunks");
                
                return fileId;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error processing document {fileName}");
                throw;
            }
        }

        /// <summary>
        /// Retrieve relevant context từ vector store dựa trên query
        /// </summary>
        public async Task<string> RetrieveContextAsync(string query, int topK = 5, string? fileId = null)
        {
            try
            {
                // 1. Tạo embedding cho query
                var queryEmbedding = await _embeddingService.CreateEmbeddingAsync(query);
                
                if (queryEmbedding == null)
                {
                    _logger.LogWarning("Failed to create embedding for query");
                    return string.Empty;
                }

                // 2. Tìm kiếm các chunks liên quan
                var retrievedChunks = await _vectorStore.SearchSimilarAsync(queryEmbedding, topK, fileId);

                if (retrievedChunks.Count == 0)
                {
                    _logger.LogInformation("No relevant chunks found for query");
                    return string.Empty;
                }

                // 3. Kết hợp các chunks thành context
                var contextBuilder = new System.Text.StringBuilder();
                contextBuilder.AppendLine("Thông tin liên quan từ tài liệu:");
                
                foreach (var retrieved in retrievedChunks.OrderByDescending(r => r.Similarity))
                {
                    contextBuilder.AppendLine($"\n[File: {retrieved.Chunk.FileName}, Chunk {retrieved.Chunk.ChunkIndex}]");
                    contextBuilder.AppendLine(retrieved.Chunk.Text);
                    contextBuilder.AppendLine();
                }

                var context = contextBuilder.ToString();
                _logger.LogInformation($"Retrieved {retrievedChunks.Count} relevant chunks for query");
                
                return context;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving context");
                return string.Empty;
            }
        }

        /// <summary>
        /// Xóa document khỏi vector store
        /// </summary>
        public async Task DeleteDocumentAsync(string fileId)
        {
            await _vectorStore.DeleteDocumentAsync(fileId);
        }

        /// <summary>
        /// Lấy danh sách tất cả documents (Legacy - không còn sử dụng)
        /// </summary>
        [Obsolete("Use PythonRAGService.GetAllDocumentsAsync instead")]
        public async Task<List<VectorStoreDocumentInfo>> GetAllDocumentsAsync()
        {
            return await _vectorStore.GetAllDocumentsAsync();
        }
    }
}

