using FressFood.Models;
using FressFood.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Text;

namespace FressFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TraceabilityController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IBlockchainService _blockchainService;
        private readonly ILogger<TraceabilityController> _logger;

        public TraceabilityController(
            IConfiguration configuration,
            IBlockchainService blockchainService,
            ILogger<TraceabilityController> logger)
        {
            _configuration = configuration;
            _blockchainService = blockchainService;
            _logger = logger;
        }

        /// <summary>
        /// Tạo thông tin truy xuất nguồn gốc cho sản phẩm
        /// POST: api/Traceability
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateTraceability([FromBody] CreateTraceabilityRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                
                // Tạo mã truy xuất duy nhất (sẽ được mã hóa thành QR code)
                var maTruyXuat = GenerateTraceabilityId();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Kiểm tra sản phẩm có tồn tại không
                    string checkProductQuery = "SELECT TenSanPham FROM SanPham WHERE MaSanPham = @MaSanPham";
                    string tenSanPham = null;

                    using (var checkCommand = new SqlCommand(checkProductQuery, connection))
                    {
                        checkCommand.Parameters.AddWithValue("@MaSanPham", request.MaSanPham);
                        var result = await checkCommand.ExecuteScalarAsync();
                        if (result == null)
                        {
                            return NotFound(new { error = "Không tìm thấy sản phẩm với mã: " + request.MaSanPham });
                        }
                        tenSanPham = result.ToString();
                    }

                    // Insert thông tin truy xuất
                    string insertQuery = @"INSERT INTO ProductTraceability 
                        (MaTruyXuat, MaSanPham, TenSanPham, NguonGoc, NhaSanXuat, DiaChiSanXuat, 
                         NgaySanXuat, NgayHetHan, NhaCungCap, PhuongTienVanChuyen, NgayNhapKho,
                         ChungNhanChatLuong, SoChungNhan, CoQuanChungNhan, NgayTao)
                        VALUES 
                        (@MaTruyXuat, @MaSanPham, @TenSanPham, @NguonGoc, @NhaSanXuat, @DiaChiSanXuat,
                         @NgaySanXuat, @NgayHetHan, @NhaCungCap, @PhuongTienVanChuyen, @NgayNhapKho,
                         @ChungNhanChatLuong, @SoChungNhan, @CoQuanChungNhan, @NgayTao)";

                    using (var command = new SqlCommand(insertQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaTruyXuat", maTruyXuat);
                        command.Parameters.AddWithValue("@MaSanPham", request.MaSanPham);
                        command.Parameters.AddWithValue("@TenSanPham", tenSanPham);
                        command.Parameters.AddWithValue("@NguonGoc", request.NguonGoc);
                        command.Parameters.AddWithValue("@NhaSanXuat", request.NhaSanXuat);
                        command.Parameters.AddWithValue("@DiaChiSanXuat", request.DiaChiSanXuat);
                        command.Parameters.AddWithValue("@NgaySanXuat", request.NgaySanXuat);
                        command.Parameters.AddWithValue("@NgayHetHan", request.NgayHetHan ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@NhaCungCap", request.NhaCungCap ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@PhuongTienVanChuyen", request.PhuongTienVanChuyen ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@NgayNhapKho", request.NgayNhapKho ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@ChungNhanChatLuong", request.ChungNhanChatLuong ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@SoChungNhan", request.SoChungNhan ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@CoQuanChungNhan", request.CoQuanChungNhan ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@NgayTao", DateTime.Now);

                        await command.ExecuteNonQueryAsync();
                    }

                    // Lấy thông tin vừa tạo
                    var traceability = await GetTraceabilityByMaTruyXuat(connection, maTruyXuat);

                    // Lưu lên blockchain
                    try
                    {
                        var blockchainRecord = await _blockchainService.SaveToBlockchainAsync(traceability);
                        
                        // Cập nhật blockchain info vào database
                        string updateBlockchainQuery = @"UPDATE ProductTraceability 
                            SET BlockchainHash = @Hash, 
                                BlockchainTransactionId = @TransactionId,
                                NgayLuuBlockchain = @NgayLuu
                            WHERE MaTruyXuat = @MaTruyXuat";

                        using (var updateCommand = new SqlCommand(updateBlockchainQuery, connection))
                        {
                            updateCommand.Parameters.AddWithValue("@Hash", blockchainRecord.Hash);
                            updateCommand.Parameters.AddWithValue("@TransactionId", blockchainRecord.TransactionId);
                            updateCommand.Parameters.AddWithValue("@NgayLuu", blockchainRecord.Timestamp);
                            updateCommand.Parameters.AddWithValue("@MaTruyXuat", maTruyXuat);
                            await updateCommand.ExecuteNonQueryAsync();
                        }

                        traceability.BlockchainHash = blockchainRecord.Hash;
                        traceability.BlockchainTransactionId = blockchainRecord.TransactionId;
                        traceability.NgayLuuBlockchain = blockchainRecord.Timestamp;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Failed to save to blockchain, but traceability record was created");
                        // Vẫn trả về success nhưng không có blockchain info
                    }

                    // Tạo QR code URL
                    var qrCodeUrl = $"{Request.Scheme}://{Request.Host}/api/Traceability/qr/{maTruyXuat}";

                    return Ok(new
                    {
                        message = "Tạo thông tin truy xuất thành công",
                        maTruyXuat = maTruyXuat,
                        qrCodeUrl = qrCodeUrl,
                        traceability = traceability
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating traceability");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Quét QR code và lấy thông tin truy xuất
        /// GET: api/Traceability/qr/{maTruyXuat}
        /// </summary>
        [HttpGet("qr/{maTruyXuat}")]
        public async Task<IActionResult> GetTraceabilityByQR(string maTruyXuat)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    var traceability = await GetTraceabilityByMaTruyXuat(connection, maTruyXuat);
                    if (traceability == null)
                    {
                        return NotFound(new { error = "Không tìm thấy thông tin truy xuất với mã: " + maTruyXuat });
                    }

                    // Lấy thông tin sản phẩm
                    var product = await GetProductById(connection, traceability.MaSanPham);

                    // Verify trên blockchain nếu có
                    bool isVerified = false;
                    if (!string.IsNullOrEmpty(traceability.BlockchainTransactionId) && 
                        !string.IsNullOrEmpty(traceability.BlockchainHash))
                    {
                        isVerified = await _blockchainService.VerifyOnBlockchainAsync(
                            traceability.BlockchainTransactionId, 
                            traceability.BlockchainHash);
                    }

                    var response = new ProductTraceabilityResponse
                    {
                        MaTruyXuat = traceability.MaTruyXuat,
                        ProductInfo = product,
                        TraceabilityInfo = traceability,
                        IsVerified = isVerified,
                        BlockchainVerificationUrl = !string.IsNullOrEmpty(traceability.BlockchainTransactionId) 
                            ? $"{Request.Scheme}://{Request.Host}/api/Traceability/verify/{traceability.BlockchainTransactionId}"
                            : null
                    };

                    // Trả về HTML page để hiển thị thông tin (cho mobile browser)
                    return Content(GenerateTraceabilityHtmlPage(response), "text/html", Encoding.UTF8);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting traceability by QR");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// API JSON endpoint để lấy thông tin truy xuất (cho mobile app)
        /// GET: api/Traceability/{maTruyXuat}
        /// </summary>
        [HttpGet("{maTruyXuat}")]
        public async Task<IActionResult> GetTraceability(string maTruyXuat)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    var traceability = await GetTraceabilityByMaTruyXuat(connection, maTruyXuat);
                    if (traceability == null)
                    {
                        return NotFound(new { error = "Không tìm thấy thông tin truy xuất với mã: " + maTruyXuat });
                    }

                    var product = await GetProductById(connection, traceability.MaSanPham);

                    bool isVerified = false;
                    if (!string.IsNullOrEmpty(traceability.BlockchainTransactionId) && 
                        !string.IsNullOrEmpty(traceability.BlockchainHash))
                    {
                        isVerified = await _blockchainService.VerifyOnBlockchainAsync(
                            traceability.BlockchainTransactionId, 
                            traceability.BlockchainHash);
                    }

                    var response = new ProductTraceabilityResponse
                    {
                        MaTruyXuat = traceability.MaTruyXuat,
                        ProductInfo = product,
                        TraceabilityInfo = traceability,
                        IsVerified = isVerified,
                        BlockchainVerificationUrl = !string.IsNullOrEmpty(traceability.BlockchainTransactionId) 
                            ? $"{Request.Scheme}://{Request.Host}/api/Traceability/verify/{traceability.BlockchainTransactionId}"
                            : null
                    };

                    return Ok(response);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting traceability");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Lấy thông tin truy xuất theo mã sản phẩm
        /// GET: api/Traceability/product/{maSanPham}
        /// </summary>
        [HttpGet("product/{maSanPham}")]
        public async Task<IActionResult> GetTraceabilityByProductId(string maSanPham)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    string query = @"SELECT TOP 1 MaTruyXuat, MaSanPham, TenSanPham 
                                   FROM ProductTraceability 
                                   WHERE MaSanPham = @MaSanPham 
                                   ORDER BY NgayTao DESC";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", maSanPham);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                return Ok(new
                                {
                                    maTruyXuat = reader["MaTruyXuat"].ToString(),
                                    maSanPham = reader["MaSanPham"].ToString(),
                                    tenSanPham = reader["TenSanPham"].ToString()
                                });
                            }
                        }
                    }
                }

                return NotFound(new { error = "Sản phẩm này chưa có thông tin truy xuất nguồn gốc" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting traceability by product ID");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Verify thông tin trên blockchain
        /// GET: api/Traceability/verify/{transactionId}
        /// </summary>
        [HttpGet("verify/{transactionId}")]
        public async Task<IActionResult> VerifyBlockchain(string transactionId)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    string query = @"SELECT MaTruyXuat, BlockchainHash, BlockchainTransactionId 
                                   FROM ProductTraceability 
                                   WHERE BlockchainTransactionId = @TransactionId";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@TransactionId", transactionId);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                var hash = reader["BlockchainHash"]?.ToString();
                                var isVerified = await _blockchainService.VerifyOnBlockchainAsync(transactionId, hash);

                                return Ok(new
                                {
                                    transactionId = transactionId,
                                    verified = isVerified,
                                    hash = hash,
                                    message = isVerified ? "Thông tin đã được xác minh trên blockchain" : "Không thể xác minh thông tin"
                                });
                            }
                        }
                    }
                }

                return NotFound(new { error = "Không tìm thấy transaction với ID: " + transactionId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verifying blockchain");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // Helper methods
        private async Task<ProductTraceability?> GetTraceabilityByMaTruyXuat(SqlConnection connection, string maTruyXuat)
        {
            string query = @"SELECT * FROM ProductTraceability WHERE MaTruyXuat = @MaTruyXuat";

            using (var command = new SqlCommand(query, connection))
            {
                command.Parameters.AddWithValue("@MaTruyXuat", maTruyXuat);

                using (var reader = await command.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        return new ProductTraceability
                        {
                            MaTruyXuat = reader["MaTruyXuat"].ToString(),
                            MaSanPham = reader["MaSanPham"].ToString(),
                            TenSanPham = reader["TenSanPham"].ToString(),
                            NguonGoc = reader["NguonGoc"].ToString(),
                            NhaSanXuat = reader["NhaSanXuat"].ToString(),
                            DiaChiSanXuat = reader["DiaChiSanXuat"].ToString(),
                            NgaySanXuat = Convert.ToDateTime(reader["NgaySanXuat"]),
                            NgayHetHan = reader["NgayHetHan"] == DBNull.Value ? null : Convert.ToDateTime(reader["NgayHetHan"]),
                            NhaCungCap = reader["NhaCungCap"] == DBNull.Value ? null : reader["NhaCungCap"].ToString(),
                            PhuongTienVanChuyen = reader["PhuongTienVanChuyen"] == DBNull.Value ? null : reader["PhuongTienVanChuyen"].ToString(),
                            NgayNhapKho = reader["NgayNhapKho"] == DBNull.Value ? null : Convert.ToDateTime(reader["NgayNhapKho"]),
                            ChungNhanChatLuong = reader["ChungNhanChatLuong"] == DBNull.Value ? null : reader["ChungNhanChatLuong"].ToString(),
                            SoChungNhan = reader["SoChungNhan"] == DBNull.Value ? null : reader["SoChungNhan"].ToString(),
                            CoQuanChungNhan = reader["CoQuanChungNhan"] == DBNull.Value ? null : reader["CoQuanChungNhan"].ToString(),
                            BlockchainHash = reader["BlockchainHash"] == DBNull.Value ? null : reader["BlockchainHash"].ToString(),
                            BlockchainTransactionId = reader["BlockchainTransactionId"] == DBNull.Value ? null : reader["BlockchainTransactionId"].ToString(),
                            NgayLuuBlockchain = reader["NgayLuuBlockchain"] == DBNull.Value ? null : Convert.ToDateTime(reader["NgayLuuBlockchain"]),
                            NgayTao = Convert.ToDateTime(reader["NgayTao"]),
                            NgayCapNhat = reader["NgayCapNhat"] == DBNull.Value ? null : Convert.ToDateTime(reader["NgayCapNhat"])
                        };
                    }
                }
            }

            return null;
        }

        private async Task<Product?> GetProductById(SqlConnection connection, string maSanPham)
        {
            string query = @"SELECT MaSanPham, TenSanPham, MoTa, GiaBan, Anh, SoLuongTon, XuatXu, DonViTinh, MaDanhMuc 
                           FROM SanPham WHERE MaSanPham = @MaSanPham";

            using (var command = new SqlCommand(query, connection))
            {
                command.Parameters.AddWithValue("@MaSanPham", maSanPham);

                using (var reader = await command.ExecuteReaderAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        var fileName = reader["Anh"]?.ToString();
                        return new Product
                        {
                            MaSanPham = reader["MaSanPham"].ToString(),
                            TenSanPham = reader["TenSanPham"].ToString(),
                            MoTa = reader["MoTa"]?.ToString(),
                            XuatXu = reader["XuatXu"]?.ToString(),
                            DonViTinh = reader["DonViTinh"]?.ToString(),
                            GiaBan = Convert.ToDecimal(reader["GiaBan"]),
                            SoLuongTon = Convert.ToInt32(reader["SoLuongTon"]),
                            MaDanhMuc = reader["MaDanhMuc"].ToString(),
                            Anh = string.IsNullOrEmpty(fileName) ? null :
                                  $"{Request.Scheme}://{Request.Host}/images/products/{fileName}"
                        };
                    }
                }
            }

            return null;
        }

        private string GenerateTraceabilityId()
        {
            // Tạo mã truy xuất duy nhất: TX + timestamp + random
            return $"TX{DateTime.Now:yyyyMMddHHmmss}{Guid.NewGuid().ToString("N")[..8].ToUpper()}";
        }

        private string GenerateTraceabilityHtmlPage(ProductTraceabilityResponse response)
        {
            var html = $@"
<!DOCTYPE html>
<html lang='vi'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Thông tin truy xuất nguồn gốc</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }}
        .container {{
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.3);
        }}
        .header {{
            text-align: center;
            margin-bottom: 30px;
        }}
        .header h1 {{
            color: #333;
            margin: 0;
            font-size: 24px;
        }}
        .verified-badge {{
            display: inline-block;
            background: #4CAF50;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            margin-top: 10px;
        }}
        .section {{
            margin-bottom: 25px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }}
        .section h2 {{
            color: #667eea;
            margin-top: 0;
            font-size: 18px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }}
        .info-row {{
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #e0e0e0;
        }}
        .info-row:last-child {{
            border-bottom: none;
        }}
        .info-label {{
            font-weight: bold;
            color: #666;
        }}
        .info-value {{
            color: #333;
            text-align: right;
        }}
        .blockchain-info {{
            background: #e8f5e9;
            border-left-color: #4CAF50;
        }}
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🔍 Thông tin truy xuất nguồn gốc</h1>
            {(response.IsVerified ? "<span class='verified-badge'>✓ Đã xác minh trên Blockchain</span>" : "")}
        </div>

        <div class='section'>
            <h2>📦 Thông tin sản phẩm</h2>
            <div class='info-row'>
                <span class='info-label'>Tên sản phẩm:</span>
                <span class='info-value'>{response.ProductInfo?.TenSanPham ?? "N/A"}</span>
            </div>
            <div class='info-row'>
                <span class='info-label'>Mã sản phẩm:</span>
                <span class='info-value'>{response.ProductInfo?.MaSanPham ?? "N/A"}</span>
            </div>
            <div class='info-row'>
                <span class='info-label'>Mã truy xuất:</span>
                <span class='info-value'>{response.MaTruyXuat}</span>
            </div>
        </div>

        <div class='section'>
            <h2>🌍 Nguồn gốc xuất xứ</h2>
            <div class='info-row'>
                <span class='info-label'>Nguồn gốc:</span>
                <span class='info-value'>{response.TraceabilityInfo?.NguonGoc ?? "N/A"}</span>
            </div>
            <div class='info-row'>
                <span class='info-label'>Nhà sản xuất:</span>
                <span class='info-value'>{response.TraceabilityInfo?.NhaSanXuat ?? "N/A"}</span>
            </div>
            <div class='info-row'>
                <span class='info-label'>Địa chỉ sản xuất:</span>
                <span class='info-value'>{response.TraceabilityInfo?.DiaChiSanXuat ?? "N/A"}</span>
            </div>
            <div class='info-row'>
                <span class='info-label'>Ngày sản xuất:</span>
                <span class='info-value'>{response.TraceabilityInfo?.NgaySanXuat:dd/MM/yyyy}</span>
            </div>
            {(response.TraceabilityInfo?.NgayHetHan != null ? $@"
            <div class='info-row'>
                <span class='info-label'>Ngày hết hạn:</span>
                <span class='info-value'>{response.TraceabilityInfo.NgayHetHan:dd/MM/yyyy}</span>
            </div>" : "")}
        </div>

        {(response.TraceabilityInfo?.NhaCungCap != null ? $@"
        <div class='section'>
            <h2>🚚 Thông tin vận chuyển</h2>
            <div class='info-row'>
                <span class='info-label'>Nhà cung cấp:</span>
                <span class='info-value'>{response.TraceabilityInfo.NhaCungCap}</span>
            </div>
            {(response.TraceabilityInfo.PhuongTienVanChuyen != null ? $@"
            <div class='info-row'>
                <span class='info-label'>Phương tiện:</span>
                <span class='info-value'>{response.TraceabilityInfo.PhuongTienVanChuyen}</span>
            </div>" : "")}
            {(response.TraceabilityInfo.NgayNhapKho != null ? $@"
            <div class='info-row'>
                <span class='info-label'>Ngày nhập kho:</span>
                <span class='info-value'>{response.TraceabilityInfo.NgayNhapKho:dd/MM/yyyy}</span>
            </div>" : "")}
        </div>" : "")}

        {(response.TraceabilityInfo?.ChungNhanChatLuong != null ? $@"
        <div class='section'>
            <h2>📜 Chứng nhận chất lượng</h2>
            <div class='info-row'>
                <span class='info-label'>Chứng nhận:</span>
                <span class='info-value'>{response.TraceabilityInfo.ChungNhanChatLuong}</span>
            </div>
            {(response.TraceabilityInfo.SoChungNhan != null ? $@"
            <div class='info-row'>
                <span class='info-label'>Số chứng nhận:</span>
                <span class='info-value'>{response.TraceabilityInfo.SoChungNhan}</span>
            </div>" : "")}
            {(response.TraceabilityInfo.CoQuanChungNhan != null ? $@"
            <div class='info-row'>
                <span class='info-label'>Cơ quan chứng nhận:</span>
                <span class='info-value'>{response.TraceabilityInfo.CoQuanChungNhan}</span>
            </div>" : "")}
        </div>" : "")}

        {(response.TraceabilityInfo?.BlockchainHash != null ? $@"
        <div class='section blockchain-info'>
            <h2>⛓️ Thông tin Blockchain</h2>
            <div class='info-row'>
                <span class='info-label'>Transaction ID:</span>
                <span class='info-value' style='font-size: 10px; word-break: break-all;'>{response.TraceabilityInfo.BlockchainTransactionId}</span>
            </div>
            <div class='info-row'>
                <span class='info-label'>Hash:</span>
                <span class='info-value' style='font-size: 10px; word-break: break-all;'>{response.TraceabilityInfo.BlockchainHash}</span>
            </div>
            {(response.TraceabilityInfo.NgayLuuBlockchain != null ? $@"
            <div class='info-row'>
                <span class='info-label'>Ngày lưu:</span>
                <span class='info-value'>{response.TraceabilityInfo.NgayLuuBlockchain:dd/MM/yyyy HH:mm}</span>
            </div>" : "")}
        </div>" : "")}
    </div>
</body>
</html>";

            return html;
        }
    }
}

