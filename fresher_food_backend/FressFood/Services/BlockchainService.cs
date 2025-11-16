using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using FressFood.Models;

namespace FressFood.Services
{
    /// <summary>
    /// Service để tương tác với blockchain
    /// Lưu ý: Đây là một implementation đơn giản
    /// Trong production, bạn nên tích hợp với blockchain network thực tế (Ethereum, Hyperledger, etc.)
    /// </summary>
    public interface IBlockchainService
    {
        Task<BlockchainRecord> SaveToBlockchainAsync(ProductTraceability traceability);
        Task<bool> VerifyOnBlockchainAsync(string transactionId, string hash);
        Task<BlockchainRecord?> GetFromBlockchainAsync(string transactionId);
    }

    public class BlockchainService : IBlockchainService
    {
        private readonly ILogger<BlockchainService> _logger;
        private readonly IConfiguration _configuration;

        // Trong production, đây sẽ là URL của blockchain network
        private readonly string _blockchainApiUrl;

        public BlockchainService(ILogger<BlockchainService> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
            _blockchainApiUrl = _configuration["Blockchain:ApiUrl"] ?? "https://api.blockchain.example.com";
        }

        /// <summary>
        /// Lưu thông tin truy xuất lên blockchain
        /// </summary>
        public async Task<BlockchainRecord> SaveToBlockchainAsync(ProductTraceability traceability)
        {
            try
            {
                // Tạo hash từ dữ liệu truy xuất
                var dataToHash = JsonSerializer.Serialize(new
                {
                    traceability.MaTruyXuat,
                    traceability.MaSanPham,
                    traceability.TenSanPham,
                    traceability.NguonGoc,
                    traceability.NhaSanXuat,
                    traceability.DiaChiSanXuat,
                    traceability.NgaySanXuat,
                    traceability.NgayHetHan,
                    traceability.NgayTao
                });

                var hash = ComputeHash(dataToHash);

                // Tạo transaction ID (trong production, đây sẽ là transaction ID thực từ blockchain)
                var transactionId = GenerateTransactionId();

                // Trong production, bạn sẽ gọi API blockchain thực tế
                // Ví dụ: await _httpClient.PostAsync($"{_blockchainApiUrl}/transactions", ...)
                
                // Hiện tại, chúng ta sẽ mô phỏng việc lưu trữ
                _logger.LogInformation($"Saving to blockchain - TransactionId: {transactionId}, Hash: {hash}");

                // Simulate blockchain storage
                // Trong thực tế, bạn có thể:
                // 1. Sử dụng Ethereum Smart Contract
                // 2. Sử dụng Hyperledger Fabric
                // 3. Sử dụng IPFS (InterPlanetary File System)
                // 4. Sử dụng các blockchain service như AWS Managed Blockchain

                return new BlockchainRecord
                {
                    TransactionId = transactionId,
                    Hash = hash,
                    Timestamp = DateTime.UtcNow,
                    Data = dataToHash,
                    Status = "Confirmed"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving to blockchain");
                throw;
            }
        }

        /// <summary>
        /// Xác minh thông tin trên blockchain
        /// </summary>
        public async Task<bool> VerifyOnBlockchainAsync(string transactionId, string hash)
        {
            try
            {
                // Trong production, bạn sẽ query blockchain network
                // Ví dụ: await _httpClient.GetAsync($"{_blockchainApiUrl}/transactions/{transactionId}")
                
                _logger.LogInformation($"Verifying on blockchain - TransactionId: {transactionId}, Hash: {hash}");
                
                // Simulate verification
                // Trong thực tế, bạn sẽ so sánh hash từ database với hash trên blockchain
                return await Task.FromResult(true);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verifying on blockchain");
                return false;
            }
        }

        /// <summary>
        /// Lấy thông tin từ blockchain
        /// </summary>
        public async Task<BlockchainRecord?> GetFromBlockchainAsync(string transactionId)
        {
            try
            {
                // Trong production, query từ blockchain network
                _logger.LogInformation($"Getting from blockchain - TransactionId: {transactionId}");
                
                // Simulate retrieval
                return await Task.FromResult<BlockchainRecord?>(null);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting from blockchain");
                return null;
            }
        }

        /// <summary>
        /// Tính toán hash SHA256 từ dữ liệu
        /// </summary>
        private string ComputeHash(string data)
        {
            using (var sha256 = SHA256.Create())
            {
                var bytes = Encoding.UTF8.GetBytes(data);
                var hash = sha256.ComputeHash(bytes);
                return Convert.ToHexString(hash).ToLower();
            }
        }

        /// <summary>
        /// Tạo Transaction ID duy nhất
        /// </summary>
        private string GenerateTransactionId()
        {
            // Trong production, đây sẽ là transaction ID từ blockchain network
            return $"0x{DateTime.UtcNow.Ticks:X}{Guid.NewGuid().ToString("N")[..16]}";
        }
    }

    /// <summary>
    /// Model cho blockchain record
    /// </summary>
    public class BlockchainRecord
    {
        public string TransactionId { get; set; }
        public string Hash { get; set; }
        public DateTime Timestamp { get; set; }
        public string Data { get; set; }
        public string Status { get; set; } // Pending, Confirmed, Failed
    }
}

