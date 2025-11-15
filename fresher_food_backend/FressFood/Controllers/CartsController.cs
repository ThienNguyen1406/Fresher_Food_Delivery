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
                            dm.TenDanhMuc,
                            gh.MaTaiKhoan
                        FROM SanPham_GioHang spgh
                        INNER JOIN GioHang gh ON spgh.MaGioHang = gh.MaGioHang
                        INNER JOIN SanPham sp ON spgh.MaSanPham = sp.MaSanPham
                        INNER JOIN DanhMuc dm ON sp.MaDanhMuc = dm.MaDanhMuc
                        WHERE gh.MaTaiKhoan = @MaTaiKhoan";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", userId);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var anh = reader["Anh"] as string;
                                var anhUrl = !string.IsNullOrEmpty(anh) ? GetFullImageUrl(anh) : null;

                                var cartItem = new CartItemDetail
                                {
                                    MaGioHang = reader["MaGioHang"].ToString() ?? "",
                                    MaSanPham = reader["MaSanPham"].ToString() ?? "",
                                    SoLuong = Convert.ToInt32(reader["SoLuong"]),
                                    TenSanPham = reader["TenSanPham"].ToString() ?? "",
                                    GiaBan = Convert.ToDecimal(reader["GiaBan"]),
                                    Anh = anhUrl,
                                    SoLuongTon = Convert.ToInt32(reader["SoLuongTon"]),
                                    TenDanhMuc = reader["TenDanhMuc"].ToString() ?? "",
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString() ?? "",
                                    ThanhTien = Convert.ToInt32(reader["SoLuong"]) * Convert.ToDecimal(reader["GiaBan"])
                                };
                                cartItems.Add(cartItem);
                            }
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

        private string GetFullImageUrl(string imageName)
        {
            var request = _httpContextAccessor.HttpContext?.Request;
            if (request == null) return null;

            var baseUrl = $"{request.Scheme}://{request.Host}";
            return $"{baseUrl}/images/products/{imageName}";
        }

        private bool KiemTraTonKho(string maSanPham, int soLuong, SqlConnection connection)
        {
            string query = "SELECT SoLuongTon FROM SanPham WHERE MaSanPham = @MaSanPham";

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
        public string TenDanhMuc { get; set; } = string.Empty;
        public required string MaTaiKhoan { get; set; }
        public decimal ThanhTien { get; set; }
    }
}