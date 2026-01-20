using System.Text.Json;
using System.Linq;
using FressFood.Models;
using Microsoft.Data.SqlClient;

namespace FressFood.Services
{
    /// <summary>
    /// Handler để xử lý function calls liên quan đến hạn sử dụng sản phẩm
    /// </summary>
    public class ProductExpiryFunctionHandler : IFunctionHandler
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<ProductExpiryFunctionHandler> _logger;

        public ProductExpiryFunctionHandler(
            IConfiguration configuration,
            ILogger<ProductExpiryFunctionHandler> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        /// <summary>
        /// Thực thi function call và trả về kết quả dưới dạng JSON string
        /// </summary>
        public async Task<string> ExecuteFunctionCallAsync(string functionName, string argumentsJson)
        {
            try
            {
                _logger.LogInformation($"Executing function call: {functionName} with arguments: {argumentsJson}");

                switch (functionName)
                {
                    case "getProductExpiry":
                        return await GetProductExpiryAsync(argumentsJson);
                    
                    case "getProductsExpiringSoon":
                        return await GetProductsExpiringSoonAsync(argumentsJson);
                    
                    case "getMonthlyRevenue":
                        return await GetMonthlyRevenueAsync(argumentsJson);
                    
                    case "getRevenueStatistics":
                        return await GetRevenueStatisticsAsync(argumentsJson);
                    
                    case "getBestSellingProductImage":
                        return await GetBestSellingProductImageAsync(argumentsJson);
                    
                    default:
                        throw new ArgumentException($"Unknown function: {functionName}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error executing function call {functionName}");
                return JsonSerializer.Serialize(new
                {
                    error = $"Lỗi khi thực thi function {functionName}: {ex.Message}"
                });
            }
        }

        /// <summary>
        /// Lấy thông tin hạn sử dụng của một sản phẩm cụ thể
        /// </summary>
        private async Task<string> GetProductExpiryAsync(string argumentsJson)
        {
            try
            {
                var args = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(argumentsJson);
                
                string? productName = null;
                string? productId = null;

                if (args != null)
                {
                    if (args.ContainsKey("productName") && args["productName"].ValueKind == JsonValueKind.String)
                    {
                        productName = args["productName"].GetString();
                    }
                    if (args.ContainsKey("productId") && args["productId"].ValueKind == JsonValueKind.String)
                    {
                        productId = args["productId"].GetString();
                    }
                }

                if (string.IsNullOrWhiteSpace(productName) && string.IsNullOrWhiteSpace(productId))
                {
                    return JsonSerializer.Serialize(new
                    {
                        error = "Cần cung cấp productName hoặc productId"
                    });
                }

                var product = await GetProductFromDatabaseAsync(productName, productId);

                if (product == null)
                {
                    return JsonSerializer.Serialize(new
                    {
                        error = $"Không tìm thấy sản phẩm '{productName ?? productId}' trong hệ thống."
                    });
                }

                // Tính toán thời gian còn lại
                var now = DateTime.Now;
                var expiryDate = product.NgayHetHan ?? DateTime.MaxValue;
                var daysRemaining = (expiryDate.Date - now.Date).Days;

                // Format response
                var result = new
                {
                    maSanPham = product.MaSanPham,
                    tenSanPham = product.TenSanPham,
                    ngaySanXuat = product.NgaySanXuat?.ToString("dd/MM/yyyy"),
                    ngayHetHan = product.NgayHetHan?.ToString("dd/MM/yyyy"),
                    daysRemaining = daysRemaining,
                    status = daysRemaining > 0
                        ? (daysRemaining <= 3 ? "Sắp hết hạn" : "Còn hạn")
                        : "Đã hết hạn",
                    message = daysRemaining > 0
                        ? (daysRemaining <= 3
                            ? $"Sản phẩm {product.TenSanPham} còn {daysRemaining} ngày nữa sẽ hết hạn (hết hạn vào ngày {product.NgayHetHan?.ToString("dd/MM/yyyy")})."
                            : $"Sản phẩm {product.TenSanPham} còn hạn sử dụng {daysRemaining} ngày nữa (hết hạn vào ngày {product.NgayHetHan?.ToString("dd/MM/yyyy")}).")
                        : $"Sản phẩm {product.TenSanPham} đã hết hạn vào ngày {product.NgayHetHan?.ToString("dd/MM/yyyy")}."
                };

                return JsonSerializer.Serialize(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetProductExpiryAsync");
                return JsonSerializer.Serialize(new
                {
                    error = $"Lỗi khi lấy thông tin hạn sử dụng: {ex.Message}"
                });
            }
        }

        /// <summary>
        /// Lấy danh sách sản phẩm sắp hết hạn
        /// </summary>
        private async Task<string> GetProductsExpiringSoonAsync(string argumentsJson)
        {
            try
            {
                var args = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(argumentsJson);
                int days = 7; // Mặc định 7 ngày

                if (args != null && args.ContainsKey("days") && args["days"].ValueKind == JsonValueKind.Number)
                {
                    days = args["days"].GetInt32();
                }

                var products = await GetProductsExpiringSoonFromDatabaseAsync(days);

                var result = new
                {
                    days = days,
                    count = products.Count,
                    products = products.Select(p => new
                    {
                        maSanPham = p.MaSanPham,
                        tenSanPham = p.TenSanPham,
                        ngayHetHan = p.NgayHetHan?.ToString("dd/MM/yyyy"),
                        daysRemaining = p.DaysRemaining,
                        status = p.DaysRemaining <= 3 ? "Sắp hết hạn" : "Còn hạn"
                    }).ToList()
                };

                return JsonSerializer.Serialize(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetProductsExpiringSoonAsync");
                return JsonSerializer.Serialize(new
                {
                    error = $"Lỗi khi lấy danh sách sản phẩm sắp hết hạn: {ex.Message}"
                });
            }
        }

        /// <summary>
        /// Lấy thông tin sản phẩm từ database
        /// </summary>
        private async Task<Product?> GetProductFromDatabaseAsync(string? productName, string? productId)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            
            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            string query;
            SqlCommand command;

            if (!string.IsNullOrWhiteSpace(productId))
            {
                // Tìm theo mã sản phẩm
                query = @"
                    SELECT MaSanPham, TenSanPham, NgaySanXuat, NgayHetHan
                    FROM SanPham
                    WHERE MaSanPham = @ProductId AND (IsDeleted = 0 OR IsDeleted IS NULL)";
                command = new SqlCommand(query, connection);
                command.Parameters.AddWithValue("@ProductId", productId);
            }
            else if (!string.IsNullOrWhiteSpace(productName))
            {
                // Tìm theo tên sản phẩm (fuzzy search)
                query = @"
                    SELECT TOP 1 MaSanPham, TenSanPham, NgaySanXuat, NgayHetHan
                    FROM SanPham
                    WHERE TenSanPham LIKE @ProductName AND (IsDeleted = 0 OR IsDeleted IS NULL)
                    ORDER BY TenSanPham";
                command = new SqlCommand(query, connection);
                command.Parameters.AddWithValue("@ProductName", $"%{productName}%");
            }
            else
            {
                return null;
            }

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return new Product
                {
                    MaSanPham = reader["MaSanPham"].ToString() ?? "",
                    TenSanPham = reader["TenSanPham"].ToString() ?? "",
                    NgaySanXuat = reader.IsDBNull(reader.GetOrdinal("NgaySanXuat"))
                        ? null
                        : reader.GetDateTime(reader.GetOrdinal("NgaySanXuat")),
                    NgayHetHan = reader.IsDBNull(reader.GetOrdinal("NgayHetHan"))
                        ? null
                        : reader.GetDateTime(reader.GetOrdinal("NgayHetHan"))
                };
            }

            return null;
        }

        /// <summary>
        /// Lấy danh sách sản phẩm sắp hết hạn từ database
        /// </summary>
        private async Task<List<ProductExpiryInfo>> GetProductsExpiringSoonFromDatabaseAsync(int days)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            var products = new List<ProductExpiryInfo>();

            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            string query = @"
                SELECT MaSanPham, TenSanPham, NgaySanXuat, NgayHetHan,
                       DATEDIFF(day, GETDATE(), NgayHetHan) as DaysRemaining
                FROM SanPham
                WHERE NgayHetHan IS NOT NULL
                  AND NgayHetHan >= GETDATE()
                  AND DATEDIFF(day, GETDATE(), NgayHetHan) <= @Days
                  AND (IsDeleted = 0 OR IsDeleted IS NULL)
                ORDER BY NgayHetHan ASC";

            using var command = new SqlCommand(query, connection);
            command.Parameters.AddWithValue("@Days", days);

            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                products.Add(new ProductExpiryInfo
                {
                    MaSanPham = reader["MaSanPham"].ToString() ?? "",
                    TenSanPham = reader["TenSanPham"].ToString() ?? "",
                    NgaySanXuat = reader.IsDBNull(reader.GetOrdinal("NgaySanXuat"))
                        ? null
                        : reader.GetDateTime(reader.GetOrdinal("NgaySanXuat")),
                    NgayHetHan = reader.IsDBNull(reader.GetOrdinal("NgayHetHan"))
                        ? null
                        : reader.GetDateTime(reader.GetOrdinal("NgayHetHan")),
                    DaysRemaining = reader.IsDBNull(reader.GetOrdinal("DaysRemaining"))
                        ? 0
                        : reader.GetInt32(reader.GetOrdinal("DaysRemaining"))
                });
            }

            return products;
        }

        /// <summary>
        /// Lấy doanh thu theo tháng
        /// </summary>
        private async Task<string> GetMonthlyRevenueAsync(string argumentsJson)
        {
            try
            {
                var args = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(argumentsJson);
                int? year = null;

                if (args != null && args.ContainsKey("year") && args["year"].ValueKind == JsonValueKind.Number)
                {
                    year = args["year"].GetInt32();
                }

                if (!year.HasValue)
                {
                    year = DateTime.Now.Year;
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var monthlyRevenue = new Dictionary<int, decimal>();

                using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();

                string query = @"
                    SELECT 
                        MONTH(dh.NgayDat) as Thang,
                        ISNULL(SUM(od.GiaBan * od.SoLuong), 0) as DoanhThu
                    FROM DonHang dh
                    LEFT JOIN ChiTietDonHang od ON dh.MaDonHang = od.MaDonHang
                    WHERE YEAR(dh.NgayDat) = @Year
                        AND (dh.TrangThai IN (N'Hoàn thành', N'Đã giao hàng', 'completed', 'completed')
                             OR dh.TrangThai LIKE '%complete%'
                             OR dh.TrangThai LIKE '%Complete%')
                    GROUP BY MONTH(dh.NgayDat)
                    ORDER BY MONTH(dh.NgayDat)";

                using var command = new SqlCommand(query, connection);
                command.Parameters.AddWithValue("@Year", year.Value);

                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    var thang = reader.GetInt32(reader.GetOrdinal("Thang"));
                    var doanhThu = reader.IsDBNull(reader.GetOrdinal("DoanhThu"))
                        ? 0
                        : reader.GetDecimal(reader.GetOrdinal("DoanhThu"));
                    monthlyRevenue[thang] = doanhThu;
                }

                // Đảm bảo có đủ 12 tháng
                var result = new List<object>();
                for (int month = 1; month <= 12; month++)
                {
                    result.Add(new
                    {
                        thang = month,
                        tenThang = GetMonthName(month),
                        doanhThu = monthlyRevenue.ContainsKey(month) ? monthlyRevenue[month] : 0
                    });
                }

                var totalRevenue = monthlyRevenue.Values.Sum();

                return JsonSerializer.Serialize(new
                {
                    year = year.Value,
                    totalRevenue = totalRevenue,
                    monthlyData = result,
                    message = $"Tổng doanh thu năm {year.Value}: {totalRevenue:N0} VND"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetMonthlyRevenueAsync");
                return JsonSerializer.Serialize(new
                {
                    error = $"Lỗi khi lấy doanh thu theo tháng: {ex.Message}"
                });
            }
        }

        /// <summary>
        /// Lấy thống kê doanh thu theo khoảng thời gian
        /// </summary>
        private async Task<string> GetRevenueStatisticsAsync(string argumentsJson)
        {
            try
            {
                var args = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(argumentsJson);
                DateTime? startDate = null;
                DateTime? endDate = null;

                if (args != null)
                {
                    if (args.ContainsKey("startDate") && args["startDate"].ValueKind == JsonValueKind.String)
                    {
                        if (DateTime.TryParse(args["startDate"].GetString(), out var parsedStartDate))
                        {
                            startDate = parsedStartDate;
                        }
                    }
                    if (args.ContainsKey("endDate") && args["endDate"].ValueKind == JsonValueKind.String)
                    {
                        if (DateTime.TryParse(args["endDate"].GetString(), out var parsedEndDate))
                        {
                            endDate = parsedEndDate;
                        }
                    }
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                
                using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();

                string baseCondition = "";
                if (startDate.HasValue)
                {
                    baseCondition += " AND CAST(dh.NgayDat AS DATE) >= @StartDate";
                }
                if (endDate.HasValue)
                {
                    baseCondition += " AND CAST(dh.NgayDat AS DATE) <= @EndDate";
                }

                string revenueQuery = @"
                    SELECT 
                        ISNULL(SUM(od.GiaBan * od.SoLuong), 0) as TongDoanhThu,
                        COUNT(DISTINCT dh.MaDonHang) as TongDonHang,
                        COUNT(DISTINCT dh.MaTaiKhoan) as TongKhachHang
                    FROM DonHang dh
                    LEFT JOIN ChiTietDonHang od ON dh.MaDonHang = od.MaDonHang
                    WHERE (dh.TrangThai IN (N'Hoàn thành', N'Đã giao hàng', 'completed', 'completed')
                           OR dh.TrangThai LIKE '%complete%'
                           OR dh.TrangThai LIKE '%Complete%')" + baseCondition;

                using var command = new SqlCommand(revenueQuery, connection);
                if (startDate.HasValue)
                {
                    command.Parameters.AddWithValue("@StartDate", startDate.Value.Date);
                }
                if (endDate.HasValue)
                {
                    command.Parameters.AddWithValue("@EndDate", endDate.Value.Date);
                }

                decimal tongDoanhThu = 0;
                int tongDonHang = 0;
                int tongKhachHang = 0;

                using var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    tongDoanhThu = reader.IsDBNull(reader.GetOrdinal("TongDoanhThu"))
                        ? 0
                        : reader.GetDecimal(reader.GetOrdinal("TongDoanhThu"));
                    tongDonHang = reader.IsDBNull(reader.GetOrdinal("TongDonHang"))
                        ? 0
                        : reader.GetInt32(reader.GetOrdinal("TongDonHang"));
                    tongKhachHang = reader.IsDBNull(reader.GetOrdinal("TongKhachHang"))
                        ? 0
                        : reader.GetInt32(reader.GetOrdinal("TongKhachHang"));
                }

                var result = new
                {
                    tongDoanhThu = tongDoanhThu,
                    tongDonHang = tongDonHang,
                    tongKhachHang = tongKhachHang,
                    startDate = startDate?.ToString("dd/MM/yyyy"),
                    endDate = endDate?.ToString("dd/MM/yyyy"),
                    message = $"Tổng doanh thu: {tongDoanhThu:N0} VND, Tổng đơn hàng: {tongDonHang}, Tổng khách hàng: {tongKhachHang}"
                };

                return JsonSerializer.Serialize(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetRevenueStatisticsAsync");
                return JsonSerializer.Serialize(new
                {
                    error = $"Lỗi khi lấy thống kê doanh thu: {ex.Message}"
                });
            }
        }

        /// <summary>
        /// Lấy hình ảnh sản phẩm bán chạy nhất
        /// </summary>
        private async Task<string> GetBestSellingProductImageAsync(string argumentsJson)
        {
            try
            {
                var bestSellingProduct = await GetBestSellingProductFromDatabaseAsync();

                if (bestSellingProduct == null)
                {
                    return JsonSerializer.Serialize(new
                    {
                        error = "Không tìm thấy sản phẩm bán chạy nhất trong hệ thống."
                    });
                }

                // Lấy base URL từ config hoặc sử dụng giá trị mặc định
                var baseUrl = _configuration["AppSettings:BaseUrl"] ?? "https://localhost:7240";
                var imageUrl = string.IsNullOrEmpty(bestSellingProduct.Anh) 
                    ? null 
                    : $"{baseUrl}/images/products/{bestSellingProduct.Anh}";

                var result = new
                {
                    maSanPham = bestSellingProduct.MaSanPham,
                    tenSanPham = bestSellingProduct.TenSanPham,
                    anh = bestSellingProduct.Anh,
                    anhUrl = imageUrl,
                    giaBan = bestSellingProduct.GiaBan,
                    soLuongTon = bestSellingProduct.SoLuongTon,
                    tongBan = bestSellingProduct.TongBan,
                    message = $"Sản phẩm bán chạy nhất là {bestSellingProduct.TenSanPham} với tổng số lượng đã bán là {bestSellingProduct.TongBan}.",
                    imagePath = imageUrl != null ? $"Hình ảnh sản phẩm: {imageUrl}" : "Sản phẩm này chưa có hình ảnh."
                };

                return JsonSerializer.Serialize(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in GetBestSellingProductImageAsync");
                return JsonSerializer.Serialize(new
                {
                    error = $"Lỗi khi lấy hình ảnh sản phẩm bán chạy nhất: {ex.Message}"
                });
            }
        }

        /// <summary>
        /// Lấy sản phẩm bán chạy nhất từ database
        /// </summary>
        private async Task<BestSellingProductInfo?> GetBestSellingProductFromDatabaseAsync()
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            
            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            string query = @"
                SELECT TOP 1
                    s.MaSanPham,
                    s.TenSanPham,
                    s.Anh,
                    s.GiaBan,
                    s.SoLuongTon,
                    ISNULL(SUM(ct.SoLuong), 0) as TongBan
                FROM SanPham s
                LEFT JOIN ChiTietDonHang ct ON s.MaSanPham = ct.MaSanPham
                WHERE (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
                GROUP BY s.MaSanPham, s.TenSanPham, s.Anh, s.GiaBan, s.SoLuongTon
                ORDER BY TongBan DESC";

            using var command = new SqlCommand(query, connection);
            using var reader = await command.ExecuteReaderAsync();
            
            if (await reader.ReadAsync())
            {
                return new BestSellingProductInfo
                {
                    MaSanPham = reader["MaSanPham"].ToString() ?? "",
                    TenSanPham = reader["TenSanPham"].ToString() ?? "",
                    Anh = reader["Anh"]?.ToString(),
                    GiaBan = reader.IsDBNull(reader.GetOrdinal("GiaBan"))
                        ? 0
                        : reader.GetDecimal(reader.GetOrdinal("GiaBan")),
                    SoLuongTon = reader.IsDBNull(reader.GetOrdinal("SoLuongTon"))
                        ? 0
                        : reader.GetInt32(reader.GetOrdinal("SoLuongTon")),
                    TongBan = reader.IsDBNull(reader.GetOrdinal("TongBan"))
                        ? 0
                        : reader.GetInt32(reader.GetOrdinal("TongBan"))
                };
            }

            return null;
        }

        /// <summary>
        /// Lấy tên tháng bằng tiếng Việt
        /// </summary>
        private string GetMonthName(int month)
        {
            return month switch
            {
                1 => "Tháng 1",
                2 => "Tháng 2",
                3 => "Tháng 3",
                4 => "Tháng 4",
                5 => "Tháng 5",
                6 => "Tháng 6",
                7 => "Tháng 7",
                8 => "Tháng 8",
                9 => "Tháng 9",
                10 => "Tháng 10",
                11 => "Tháng 11",
                12 => "Tháng 12",
                _ => $"Tháng {month}"
            };
        }
    }

    /// <summary>
    /// Model để lưu thông tin hạn sử dụng sản phẩm
    /// </summary>
    public class ProductExpiryInfo
    {
        public string MaSanPham { get; set; } = string.Empty;
        public string TenSanPham { get; set; } = string.Empty;
        public DateTime? NgaySanXuat { get; set; }
        public DateTime? NgayHetHan { get; set; }
        public int DaysRemaining { get; set; }
    }

    /// <summary>
    /// Model để lưu thông tin sản phẩm bán chạy nhất
    /// </summary>
    public class BestSellingProductInfo
    {
        public string MaSanPham { get; set; } = string.Empty;
        public string TenSanPham { get; set; } = string.Empty;
        public string? Anh { get; set; }
        public decimal GiaBan { get; set; }
        public int SoLuongTon { get; set; }
        public int TongBan { get; set; }
    }
}

