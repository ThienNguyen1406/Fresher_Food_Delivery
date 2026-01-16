using FressFood.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace FoodShop.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CartsController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CartsController(IConfiguration configuration, IHttpContextAccessor httpContextAccessor)
        {
            _configuration = configuration;
            _httpContextAccessor = httpContextAccessor;
        }

        
        // GET: api/Carts/user/{userId}
        [HttpGet("user/{userId}")]
        public IActionResult GetCartByUser(string userId)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var cartItems = new List<CartItemDetail>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    string query = @"
                        SELECT 
                            spgh.MaGioHang,
                            spgh.MaSanPham, 
                            spgh.SoLuong,
                            sp.TenSanPham,
                            sp.GiaBan,
                            sp.Anh,
                            sp.SoLuongTon,
                            sp.NgayHetHan,
                            dm.TenDanhMuc,
                            gh.MaTaiKhoan
                        FROM SanPham_GioHang spgh
                        INNER JOIN GioHang gh ON spgh.MaGioHang = gh.MaGioHang
                        INNER JOIN SanPham sp ON spgh.MaSanPham = sp.MaSanPham
                        INNER JOIN DanhMuc dm ON sp.MaDanhMuc = dm.MaDanhMuc
                        WHERE gh.MaTaiKhoan = @MaTaiKhoan AND (sp.IsDeleted = 0 OR sp.IsDeleted IS NULL)";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", userId);

                        // Đọc tất cả dữ liệu vào list trước, sau đó mới tính giá để tránh lỗi DataReader
                        var tempItems = new List<(string MaGioHang, string MaSanPham, int SoLuong, string TenSanPham, decimal GiaBan, string? Anh, int SoLuongTon, DateTime? NgayHetHan, string TenDanhMuc, string MaTaiKhoan)>();
                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                tempItems.Add((
                                    MaGioHang: reader["MaGioHang"].ToString() ?? "",
                                    MaSanPham: reader["MaSanPham"].ToString() ?? "",
                                    SoLuong: Convert.ToInt32(reader["SoLuong"]),
                                    TenSanPham: reader["TenSanPham"].ToString() ?? "",
                                    GiaBan: Convert.ToDecimal(reader["GiaBan"]),
                                    Anh: reader["Anh"] as string,
                                    SoLuongTon: Convert.ToInt32(reader["SoLuongTon"]),
                                    NgayHetHan: reader["NgayHetHan"] != DBNull.Value && reader["NgayHetHan"] != null 
                                        ? (DateTime?)Convert.ToDateTime(reader["NgayHetHan"]) 
                                        : null,
                                    TenDanhMuc: reader["TenDanhMuc"].ToString() ?? "",
                                    MaTaiKhoan: reader["MaTaiKhoan"].ToString() ?? ""
                                ));
                            }
                        }
                        
                        // Sau khi đóng reader, mới tính giá thực tế
                        foreach (var item in tempItems)
                        {
                            var anh = item.Anh;
                            var anhUrl = !string.IsNullOrEmpty(anh) ? GetFullImageUrl(anh) : null;
                            
                            // Tính giá thực tế (có Sale và giảm giá hết hạn) - connection đã không còn reader mở
                            var giaThucTe = TinhGiaThucTe(item.MaSanPham, item.GiaBan, item.NgayHetHan, connection);
                            var thanhTien = item.SoLuong * giaThucTe;
                            
                            // Debug: Log để kiểm tra
                            Console.WriteLine($"[Cart FINAL] {item.MaSanPham} ({item.TenSanPham}): GiaBan={item.GiaBan}, GiaThucTe={giaThucTe}, SoLuong={item.SoLuong}, ThanhTien={thanhTien}");
                            System.Diagnostics.Debug.WriteLine($"[Cart] {item.MaSanPham}: GiaBan={item.GiaBan}, GiaThucTe={giaThucTe}, SoLuong={item.SoLuong}, ThanhTien={thanhTien}");

                            var cartItem = new CartItemDetail
                            {
                                MaGioHang = item.MaGioHang,
                                MaSanPham = item.MaSanPham,
                                SoLuong = item.SoLuong,
                                TenSanPham = item.TenSanPham,
                                GiaBan = item.GiaBan,
                                Anh = anhUrl,
                                SoLuongTon = item.SoLuongTon,
                                NgayHetHan = item.NgayHetHan,
                                TenDanhMuc = item.TenDanhMuc,
                                MaTaiKhoan = item.MaTaiKhoan,
                                ThanhTien = thanhTien
                            };
                            cartItems.Add(cartItem);
                        }
                    }

                    decimal tongTien = cartItems.Sum(item => item.ThanhTien);
                    int tongSoLuong = cartItems.Sum(item => item.SoLuong);

                    var result = new
                    {
                        MaTaiKhoan = userId,
                        TongTien = tongTien,
                        TongSoLuong = tongSoLuong,
                        SanPham = cartItems
                    };

                    return Ok(result);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Carts/add
        [HttpPost("add")]
        public IActionResult AddToCart([FromBody] AddToCartRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    if (!KiemTraTonKho(request.MaSanPham, request.SoLuong, connection))
                    {
                        return BadRequest(new { error = "Số lượng sản phẩm trong kho không đủ" });
                    }

                    string maGioHang = TaoHoacLayGioHang(request.MaTaiKhoan, connection);

                    int soLuongHienTai = LaySoLuongHienTai(maGioHang, request.MaSanPham, connection);

                    if (soLuongHienTai > 0)
                    {
                        CapNhatSoLuong(maGioHang, request.MaSanPham, soLuongHienTai + request.SoLuong, connection);
                    }
                    else
                    {
                        ThemMoiVaoGioHang(maGioHang, request.MaSanPham, request.SoLuong, connection);
                    }

                    return Ok(new { message = "Thêm vào giỏ hàng thành công" });
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Carts/remove/{userId}/{productId}
        [HttpDelete("remove/{userId}/{productId}")]
        public IActionResult RemoveFromCart(string userId, string productId)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    string query = @"
                        DELETE FROM SanPham_GioHang 
                        WHERE MaGioHang IN (SELECT MaGioHang FROM GioHang WHERE MaTaiKhoan = @MaTaiKhoan) 
                        AND MaSanPham = @MaSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", userId);
                        command.Parameters.AddWithValue("@MaSanPham", productId);

                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy sản phẩm trong giỏ hàng" });
                        }
                    }
                }

                return Ok(new { message = "Xóa sản phẩm khỏi giỏ hàng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Carts/update-quantity
        [HttpPut("update-quantity")]
        public IActionResult UpdateQuantity([FromBody] UpdateQuantityRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    if (!KiemTraTonKho(request.MaSanPham, request.SoLuong, connection))
                    {
                        return BadRequest(new { error = "Số lượng sản phẩm trong kho không đủ" });
                    }

                    string query = @"
                        UPDATE SanPham_GioHang 
                        SET SoLuong = @SoLuong 
                        WHERE MaGioHang IN (SELECT MaGioHang FROM GioHang WHERE MaTaiKhoan = @MaTaiKhoan) 
                        AND MaSanPham = @MaSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", request.MaTaiKhoan);
                        command.Parameters.AddWithValue("@MaSanPham", request.MaSanPham);
                        command.Parameters.AddWithValue("@SoLuong", request.SoLuong);

                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy sản phẩm trong giỏ hàng" });
                        }
                    }
                }

                return Ok(new { message = "Cập nhật số lượng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Carts/clear/{userId}
        [HttpDelete("clear/{userId}")]
        public IActionResult ClearCart(string userId)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"
                        DELETE FROM SanPham_GioHang 
                          WHERE MaGioHang IN (SELECT MaGioHang FROM GioHang WHERE MaTaiKhoan = @MaTaiKhoan)";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", userId);
                        int affectedRows = command.ExecuteNonQuery();

                        return Ok(new { message = $"Đã xóa {affectedRows} sản phẩm khỏi giỏ hàng" });
                    }

                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        #region Helper Methods

        /// <summary>
        /// Tính giá thực tế của sản phẩm (có Sale và giảm giá hết hạn)
        ///    // @"
        //  DELETE FROM SanPham_GioHang 
        // WHERE MaGioHang IN (SELECT MaGioHang FROM GioHang WHERE MaTaiKhoan = @MaTaiKhoan)";
        /// </summary>
        /// 
        private decimal TinhGiaThucTe(string maSanPham, decimal giaBan, DateTime? ngayHetHan, SqlConnection connection)
        {
            decimal giaThucTe = giaBan;
            
            // QUY TẮC: Kiểm tra Sale TRƯỚC. Nếu có Sale thì KHÔNG kiểm tra giảm giá hết hạn nữa
            // Nếu không có Sale, mới kiểm tra giảm giá hết hạn (30% nếu còn ≤ 7 ngày)
            
            // Kiểm tra Sale (khuyến mãi) TRƯỚC
            decimal? giaTriKhuyenMai = null;
            string? loaiGiaTri = null;
            try
            {
                string saleQuery = @"
                    SELECT TOP 1 GiaTriKhuyenMai, ISNULL(LoaiGiaTri, 'Amount') as LoaiGiaTri
                    FROM KhuyenMai
                    WHERE (MaSanPham = @MaSanPham OR MaSanPham = 'ALL')
                      AND TrangThai = 'Active'
                      AND NgayBatDau <= GETDATE()
                      AND NgayKetThuc >= GETDATE()
                    ORDER BY CASE WHEN MaSanPham = @MaSanPham THEN 0 ELSE 1 END";
                
                using (var saleCommand = new SqlCommand(saleQuery, connection))
                {
                    saleCommand.Parameters.AddWithValue("@MaSanPham", maSanPham);
                    
                    using (var saleReader = saleCommand.ExecuteReader())
                    {
                        if (saleReader.Read())
                        {
                            giaTriKhuyenMai = Convert.ToDecimal(saleReader["GiaTriKhuyenMai"]);
                            loaiGiaTri = saleReader["LoaiGiaTri"]?.ToString() ?? "Amount";
                            Console.WriteLine($"[Cart Price] {maSanPham}: Tim thay Sale, GiaTriKhuyenMai={giaTriKhuyenMai}, LoaiGiaTri={loaiGiaTri}");
                        }
                        else
                        {
                            Console.WriteLine($"[Cart Price] {maSanPham}: Khong tim thay Sale (kiem tra trong DB)");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                // Log lỗi nhưng vẫn tiếp tục
                Console.WriteLine($"[Cart Price] Error getting sale for {maSanPham}: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"[Cart] Error getting sale for {maSanPham}: {ex.Message}");
            }
            
            // Áp dụng giảm giá: Nếu có Sale thì CHỈ áp dụng Sale, KHÔNG kiểm tra giảm giá hết hạn
            if (giaTriKhuyenMai.HasValue && giaTriKhuyenMai.Value > 0)
            {
                // Có Sale -> CHỈ tính giá theo Sale, KHÔNG áp dụng giảm giá hết hạn
                if (loaiGiaTri == "Percent")
                {
                    // Giảm giá theo phần trăm: GiaThucTe = GiaBan * (1 - GiaTriKhuyenMai / 100)
                    // Ví dụ: GiaTriKhuyenMai = 30 -> giảm 30%
                    decimal phanTramGiam = giaTriKhuyenMai.Value / 100m;
                    decimal soTienGiam = giaBan * phanTramGiam;
                    giaThucTe = Math.Max(0, giaBan - soTienGiam);
                    Console.WriteLine($"[Cart Price] {maSanPham}: Dung Sale PERCENT, GiaBan={giaBan}, Giam={giaTriKhuyenMai.Value}%, SoTienGiam={soTienGiam}, GiaThucTe={giaThucTe}");
                }
                else
                {
                    // Giảm giá theo số tiền: GiaThucTe = GiaBan - GiaTriKhuyenMai
                    giaThucTe = Math.Max(0, giaBan - giaTriKhuyenMai.Value);
                    Console.WriteLine($"[Cart Price] {maSanPham}: Dung Sale AMOUNT, GiaBan={giaBan}, GiaTriKhuyenMai={giaTriKhuyenMai.Value}, GiaThucTe={giaThucTe}");
                }
            }
            else
            {
                // KHÔNG có Sale -> mới kiểm tra giảm giá hết hạn (30% nếu còn ≤ 7 ngày)
                if (ngayHetHan.HasValue)
                {
                    var now = DateTime.Now;
                    var daysUntilExpiry = (ngayHetHan.Value.Date - now.Date).Days;
                    Console.WriteLine($"[Cart Price] {maSanPham}: NgayHetHan={ngayHetHan.Value:yyyy-MM-dd}, DaysUntilExpiry={daysUntilExpiry}");
                    if (daysUntilExpiry >= 0 && daysUntilExpiry <= 7)
                    {
                        decimal giamGiaHetHan = giaBan * 0.3m;
                        giaThucTe = Math.Max(0, giaBan - giamGiaHetHan);
                        Console.WriteLine($"[Cart Price] {maSanPham}: Dung giam gia het han 30%, GiaBan={giaBan}, GiamGiaHetHan={giamGiaHetHan}, GiaThucTe={giaThucTe}");
                    }
                    else
                    {
                        Console.WriteLine($"[Cart Price] {maSanPham}: Khong co giam gia, GiaThucTe={giaThucTe} (giaBan)");
                    }
                }
                else
                {
                    Console.WriteLine($"[Cart Price] {maSanPham}: Khong co giam gia, GiaThucTe={giaThucTe} (giaBan)");
                }
            }
            
            var finalPrice = Math.Max(0, giaThucTe);
            Console.WriteLine($"[Cart Price] {maSanPham}: FINAL GiaThucTe={finalPrice}");
            return finalPrice;
        }

        private string GetFullImageUrl(string imageName)
        {
            var request = _httpContextAccessor.HttpContext?.Request;
            if (request == null) return null;

            var baseUrl = $"{request.Scheme}://{request.Host}";
            return $"{baseUrl}/images/products/{imageName}";
        }

        private bool KiemTraTonKho(string maSanPham, int soLuong, SqlConnection connection)
        {
            string query = "SELECT SoLuongTon FROM SanPham WHERE MaSanPham = @MaSanPham AND (IsDeleted = 0 OR IsDeleted IS NULL)";

            using (var command = new SqlCommand(query, connection))
            {
                command.Parameters.AddWithValue("@MaSanPham", maSanPham);
                var result = command.ExecuteScalar();
                if (result == null) return false;

                int soLuongTon = Convert.ToInt32(result);
                return soLuongTon >= soLuong;
            }
        }

        private string TaoHoacLayGioHang(string maTaiKhoan, SqlConnection connection)
        {
            string checkQuery = "SELECT MaGioHang FROM GioHang WHERE MaTaiKhoan = @MaTaiKhoan";

            using (var command = new SqlCommand(checkQuery, connection))
            {
                command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);
                var result = command.ExecuteScalar();
                if (result != null)
                    return result.ToString() ?? "";
            }

            string insertQuery = "INSERT INTO GioHang (MaTaiKhoan) OUTPUT INSERTED.MaGioHang VALUES (@MaTaiKhoan)";
            using (var command = new SqlCommand(insertQuery, connection))
            {
                command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);
                return command.ExecuteScalar()?.ToString() ?? "";
            }
        }

        private int LaySoLuongHienTai(string maGioHang, string maSanPham, SqlConnection connection)
        {
            string query = "SELECT SoLuong FROM SanPham_GioHang WHERE MaGioHang = @MaGioHang AND MaSanPham = @MaSanPham";

            using (var command = new SqlCommand(query, connection))
            {
                command.Parameters.AddWithValue("@MaGioHang", maGioHang);
                command.Parameters.AddWithValue("@MaSanPham", maSanPham);
                var result = command.ExecuteScalar();
                return result == null ? 0 : Convert.ToInt32(result);
            }
        }

        private void CapNhatSoLuong(string maGioHang, string maSanPham, int soLuong, SqlConnection connection)
        {
            string query = "UPDATE SanPham_GioHang SET SoLuong = @SoLuong WHERE MaGioHang = @MaGioHang AND MaSanPham = @MaSanPham";
            using (var command = new SqlCommand(query, connection))
            {
                command.Parameters.AddWithValue("@MaGioHang", maGioHang);
                command.Parameters.AddWithValue("@MaSanPham", maSanPham);
                command.Parameters.AddWithValue("@SoLuong", soLuong);
                command.ExecuteNonQuery();
            }
        }

        private void ThemMoiVaoGioHang(string maGioHang, string maSanPham, int soLuong, SqlConnection connection)
        {
            string query = "INSERT INTO SanPham_GioHang (MaGioHang, MaSanPham, SoLuong) VALUES (@MaGioHang, @MaSanPham, @SoLuong)";
            using (var command = new SqlCommand(query, connection))
            {
                command.Parameters.AddWithValue("@MaGioHang", maGioHang);
                command.Parameters.AddWithValue("@MaSanPham", maSanPham);
                command.Parameters.AddWithValue("@SoLuong", soLuong);
                command.ExecuteNonQuery();
            }
        }

        #endregion
    }

    // Models
    public class AddToCartRequest
    {
        public required string MaTaiKhoan { get; set; }
        public required string MaSanPham { get; set; }
        public int SoLuong { get; set; }
    }

    public class UpdateQuantityRequest
    {
        public required string MaTaiKhoan { get; set; }
        public required string MaSanPham { get; set; }
        public int SoLuong { get; set; }
    }

    public class CartItemDetail
    {
        public required string MaGioHang { get; set; }
        public required string MaSanPham { get; set; }
        public int SoLuong { get; set; }
        public string TenSanPham { get; set; } = string.Empty;
        public decimal GiaBan { get; set; }
        public string? Anh { get; set; }
        public int SoLuongTon { get; set; }
        public DateTime? NgayHetHan { get; set; }
        public string TenDanhMuc { get; set; } = string.Empty;
        public required string MaTaiKhoan { get; set; }
        public decimal ThanhTien { get; set; }
    }
}