using Microsoft.Data.SqlClient;
using System.Data;

namespace FressFood.Services
{
    /// <summary>
    /// Service lưu trữ và tìm kiếm vectors trong SQL Server
    /// Sử dụng cosine similarity để tìm các chunks liên quan
    /// </summary>
    public class VectorStoreService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<VectorStoreService> _logger;

        public VectorStoreService(IConfiguration configuration, ILogger<VectorStoreService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        /// <summary>
        /// Khởi tạo bảng vector nếu chưa có
        /// </summary>
        public async Task InitializeDatabaseAsync()
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");

            try
            {
                using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();

                // Tạo bảng Document nếu chưa có
                string createDocumentTable = @"
                    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Document')
                    CREATE TABLE Document (
                        FileId NVARCHAR(50) PRIMARY KEY,
                        FileName NVARCHAR(500) NOT NULL,
                        UploadDate DATETIME NOT NULL,
                        FileType NVARCHAR(10),
                        TotalChunks INT DEFAULT 0
                    )";

                // Tạo bảng DocumentChunk nếu chưa có
                string createChunkTable = @"
                    IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentChunk')
                    CREATE TABLE DocumentChunk (
                        ChunkId NVARCHAR(100) PRIMARY KEY,
                        FileId NVARCHAR(50) NOT NULL,
                        FileName NVARCHAR(500) NOT NULL,
                        ChunkIndex INT NOT NULL,
                        Text NVARCHAR(MAX) NOT NULL,
                        StartIndex INT,
                        EndIndex INT,
                        Embedding NVARCHAR(MAX), -- JSON array of floats
                        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
                        FOREIGN KEY (FileId) REFERENCES Document(FileId) ON DELETE CASCADE
                    )";

                // Tạo index để tìm kiếm nhanh
                string createIndex = @"
                    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DocumentChunk_FileId')
                    CREATE INDEX IX_DocumentChunk_FileId ON DocumentChunk(FileId);
                    
                    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DocumentChunk_FileName')
                    CREATE INDEX IX_DocumentChunk_FileName ON DocumentChunk(FileName);";

                using (var command = new SqlCommand(createDocumentTable, connection))
                {
                    await command.ExecuteNonQueryAsync();
                }

                using (var command = new SqlCommand(createChunkTable, connection))
                {
                    await command.ExecuteNonQueryAsync();
                }

                using (var command = new SqlCommand(createIndex, connection))
                {
                    await command.ExecuteNonQueryAsync();
                }

                _logger.LogInformation("Vector store database initialized successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing vector store database");
                throw;
            }
        }

        /// <summary>
        /// Lưu document metadata
        /// </summary>
        public async Task SaveDocumentAsync(string fileId, string fileName, string fileType)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");

            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            string query = @"
                IF EXISTS (SELECT 1 FROM Document WHERE FileId = @FileId)
                    UPDATE Document 
                    SET FileName = @FileName, FileType = @FileType, UploadDate = @UploadDate
                    WHERE FileId = @FileId
                ELSE
                    INSERT INTO Document (FileId, FileName, FileType, UploadDate)
                    VALUES (@FileId, @FileName, @FileType, @UploadDate)";

            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@FileId", fileId);
            command.Parameters.AddWithValue("@FileName", fileName);
            command.Parameters.AddWithValue("@FileType", fileType);
            command.Parameters.AddWithValue("@UploadDate", DateTime.Now);

            await command.ExecuteNonQueryAsync();
        }

        /// <summary>
        /// Lưu chunks với embeddings
        /// </summary>
        public async Task SaveChunksAsync(List<DocumentChunk> chunks, List<float[]?> embeddings)
        {
            if (chunks == null || chunks.Count == 0)
                return;

            var connectionString = _configuration.GetConnectionString("DefaultConnection");

            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            // Xóa chunks cũ của file nếu có
            if (chunks[0].FileId != null)
            {
                string deleteQuery = "DELETE FROM DocumentChunk WHERE FileId = @FileId";
                using var deleteCommand = new SqlCommand(deleteQuery, connection);
                deleteCommand.Parameters.AddWithValue("@FileId", chunks[0].FileId);
                await deleteCommand.ExecuteNonQueryAsync();
            }

            // Lưu chunks mới
            string insertQuery = @"
                INSERT INTO DocumentChunk (ChunkId, FileId, FileName, ChunkIndex, Text, StartIndex, EndIndex, Embedding, CreatedDate)
                VALUES (@ChunkId, @FileId, @FileName, @ChunkIndex, @Text, @StartIndex, @EndIndex, @Embedding, @CreatedDate)";

            for (int i = 0; i < chunks.Count; i++)
            {
                var chunk = chunks[i];
                var embedding = i < embeddings.Count ? embeddings[i] : null;

                using var command = new SqlCommand(insertQuery, connection);
                command.Parameters.AddWithValue("@ChunkId", chunk.Id);
                command.Parameters.AddWithValue("@FileId", (object)chunk.FileId ?? DBNull.Value);
                command.Parameters.AddWithValue("@FileName", chunk.FileName);
                command.Parameters.AddWithValue("@ChunkIndex", chunk.ChunkIndex);
                command.Parameters.AddWithValue("@Text", chunk.Text);
                command.Parameters.AddWithValue("@StartIndex", chunk.StartIndex);
                command.Parameters.AddWithValue("@EndIndex", chunk.EndIndex);
                command.Parameters.AddWithValue("@Embedding", embedding != null ? System.Text.Json.JsonSerializer.Serialize(embedding) : DBNull.Value);
                command.Parameters.AddWithValue("@CreatedDate", DateTime.Now);

                await command.ExecuteNonQueryAsync();
            }

            // Cập nhật TotalChunks
            if (chunks[0].FileId != null)
            {
                string updateQuery = "UPDATE Document SET TotalChunks = @TotalChunks WHERE FileId = @FileId";
                using var updateCommand = new SqlCommand(updateQuery, connection);
                updateCommand.Parameters.AddWithValue("@FileId", chunks[0].FileId);
                updateCommand.Parameters.AddWithValue("@TotalChunks", chunks.Count);
                await updateCommand.ExecuteNonQueryAsync();
            }

            _logger.LogInformation($"Saved {chunks.Count} chunks to vector store");
        }

        /// <summary>
        /// Tìm kiếm các chunks liên quan dựa trên query embedding
        /// Sử dụng cosine similarity
        /// </summary>
        public async Task<List<RetrievedChunk>> SearchSimilarAsync(float[] queryEmbedding, int topK = 5, string? fileId = null)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            var results = new List<RetrievedChunk>();

            try
            {
                using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();

                string whereClause = fileId != null ? "WHERE FileId = @FileId" : "";
                string query = $@"
                    SELECT ChunkId, FileId, FileName, ChunkIndex, Text, StartIndex, EndIndex, Embedding
                    FROM DocumentChunk
                    {whereClause}
                    AND Embedding IS NOT NULL";

                using var command = new SqlCommand(query, connection);
                if (fileId != null)
                {
                    command.Parameters.AddWithValue("@FileId", fileId);
                }

                using var reader = await command.ExecuteReaderAsync();
                var candidates = new List<(DocumentChunk chunk, float[] embedding, float similarity)>();

                while (await reader.ReadAsync())
                {
                    var chunk = new DocumentChunk
                    {
                        Id = reader["ChunkId"].ToString()!,
                        FileId = reader["FileId"]?.ToString(),
                        FileName = reader["FileName"].ToString()!,
                        ChunkIndex = Convert.ToInt32(reader["ChunkIndex"]),
                        Text = reader["Text"].ToString()!,
                        StartIndex = reader.IsDBNull(reader.GetOrdinal("StartIndex")) ? 0 : Convert.ToInt32(reader["StartIndex"]),
                        EndIndex = reader.IsDBNull(reader.GetOrdinal("EndIndex")) ? 0 : Convert.ToInt32(reader["EndIndex"])
                    };

                    var embeddingJson = reader["Embedding"]?.ToString();
                    if (!string.IsNullOrEmpty(embeddingJson))
                    {
                        var embedding = System.Text.Json.JsonSerializer.Deserialize<float[]>(embeddingJson);
                        if (embedding != null && embedding.Length == queryEmbedding.Length)
                        {
                            var similarity = CosineSimilarity(queryEmbedding, embedding);
                            candidates.Add((chunk, embedding, similarity));
                        }
                    }
                }

                // Sắp xếp theo similarity và lấy top K
                var topCandidates = candidates
                    .OrderByDescending(c => c.similarity)
                    .Take(topK)
                    .ToList();

                results = topCandidates.Select(c => new RetrievedChunk
                {
                    Chunk = c.chunk,
                    Similarity = c.similarity
                }).ToList();

                _logger.LogInformation($"Found {results.Count} similar chunks");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching similar chunks");
            }

            return results;
        }

        /// <summary>
        /// Tính cosine similarity giữa hai vectors
        /// </summary>
        private float CosineSimilarity(float[] vectorA, float[] vectorB)
        {
            if (vectorA.Length != vectorB.Length)
                return 0;

            float dotProduct = 0;
            float magnitudeA = 0;
            float magnitudeB = 0;

            for (int i = 0; i < vectorA.Length; i++)
            {
                dotProduct += vectorA[i] * vectorB[i];
                magnitudeA += vectorA[i] * vectorA[i];
                magnitudeB += vectorB[i] * vectorB[i];
            }

            magnitudeA = (float)Math.Sqrt(magnitudeA);
            magnitudeB = (float)Math.Sqrt(magnitudeB);

            if (magnitudeA == 0 || magnitudeB == 0)
                return 0;

            return dotProduct / (magnitudeA * magnitudeB);
        }

        /// <summary>
        /// Xóa document và tất cả chunks của nó
        /// </summary>
        public async Task DeleteDocumentAsync(string fileId)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");

            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            string query = "DELETE FROM Document WHERE FileId = @FileId";
            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@FileId", fileId);
            await command.ExecuteNonQueryAsync();

            _logger.LogInformation($"Deleted document {fileId} and all its chunks");
        }

        /// <summary>
        /// Lấy danh sách tất cả documents (Legacy - không còn sử dụng)
        /// </summary>
        [Obsolete("Use PythonRAGService.GetAllDocumentsAsync instead")]
        public async Task<List<VectorStoreDocumentInfo>> GetAllDocumentsAsync()
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            var documents = new List<VectorStoreDocumentInfo>();

            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            string query = "SELECT FileId, FileName, FileType, UploadDate, TotalChunks FROM Document ORDER BY UploadDate DESC";

            using var command = new SqlCommand(query, connection);
            using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                documents.Add(new VectorStoreDocumentInfo
                {
                    FileId = reader["FileId"].ToString()!,
                    FileName = reader["FileName"].ToString()!,
                    FileType = reader["FileType"]?.ToString(),
                    UploadDate = reader.GetDateTime(reader.GetOrdinal("UploadDate")),
                    TotalChunks = reader.IsDBNull(reader.GetOrdinal("TotalChunks")) ? 0 : Convert.ToInt32(reader["TotalChunks"])
                });
            }

            return documents;
        }
    }

    /// <summary>
    /// Model cho retrieved chunk với similarity score
    /// </summary>
    public class RetrievedChunk
    {
        public DocumentChunk Chunk { get; set; } = null!;
        public float Similarity { get; set; }
    }

    /// <summary>
    /// Model cho document info (Legacy - không còn sử dụng, đã chuyển sang Python RAG service)
    /// </summary>
    [Obsolete("Use PythonRAGService.DocumentInfo instead")]
    public class VectorStoreDocumentInfo
    {
        public string FileId { get; set; } = string.Empty;
        public string FileName { get; set; } = string.Empty;
        public string? FileType { get; set; }
        public DateTime UploadDate { get; set; }
        public int TotalChunks { get; set; }
    }
}

