using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using FressFood.Models;

namespace FressFood.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DeliveryAddressController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<DeliveryAddressController> _logger;

        public DeliveryAddressController(IConfiguration configuration, ILogger<DeliveryAddressController> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        // GET: api/deliveryaddress/{maTaiKhoan}
        /// <summary>
        /// Lấy danh sách địa chỉ giao hàng của user
        /// </summary>
        [HttpGet("{maTaiKhoan}")]
        public IActionResult GetDeliveryAddresses(string maTaiKhoan)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var addresses = new List<DeliveryAddress>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"
                        SELECT MaDiaChi, MaTaiKhoan, HoTen, SoDienThoai, DiaChi, 
                               LaDiaChiMacDinh, NgayTao, NgayCapNhat
                        FROM DiaChiGiaoHang
                        WHERE MaTaiKhoan = @MaTaiKhoan
                        ORDER BY LaDiaChiMacDinh DESC, NgayTao DESC";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                addresses.Add(new DeliveryAddress
                                {
                                    MaDiaChi = reader["MaDiaChi"].ToString() ?? "",
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString() ?? "",
                                    HoTen = reader["HoTen"].ToString() ?? "",
                                    SoDienThoai = reader["SoDienThoai"].ToString() ?? "",
                                    DiaChi = reader["DiaChi"].ToString() ?? "",
                                    LaDiaChiMacDinh = reader["LaDiaChiMacDinh"] as bool? ?? false,
                                    NgayTao = reader.GetDateTime(reader.GetOrdinal("NgayTao")),
                                    NgayCapNhat = reader.IsDBNull(reader.GetOrdinal("NgayCapNhat"))
                                        ? null
                                        : reader.GetDateTime(reader.GetOrdinal("NgayCapNhat"))
                                });
                            }
                        }
                    }
                }

                return Ok(addresses);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting delivery addresses");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/deliveryaddress/{maTaiKhoan}/default
        /// <summary>
        /// Lấy địa chỉ mặc định của user
        /// </summary>
        [HttpGet("{maTaiKhoan}/default")]
        public IActionResult GetDefaultAddress(string maTaiKhoan)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                DeliveryAddress? address = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"
                        SELECT TOP 1 MaDiaChi, MaTaiKhoan, HoTen, SoDienThoai, DiaChi, 
                               LaDiaChiMacDinh, NgayTao, NgayCapNhat
                        FROM DiaChiGiaoHang
                        WHERE MaTaiKhoan = @MaTaiKhoan
                        ORDER BY LaDiaChiMacDinh DESC, NgayTao DESC";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                address = new DeliveryAddress
                                {
                                    MaDiaChi = reader["MaDiaChi"].ToString() ?? "",
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString() ?? "",
                                    HoTen = reader["HoTen"].ToString() ?? "",
                                    SoDienThoai = reader["SoDienThoai"].ToString() ?? "",
                                    DiaChi = reader["DiaChi"].ToString() ?? "",
                                    LaDiaChiMacDinh = reader["LaDiaChiMacDinh"] as bool? ?? false,
                                    NgayTao = reader.GetDateTime(reader.GetOrdinal("NgayTao")),
                                    NgayCapNhat = reader.IsDBNull(reader.GetOrdinal("NgayCapNhat"))
                                        ? null
                                        : reader.GetDateTime(reader.GetOrdinal("NgayCapNhat"))
                                };
                            }
                        }
                    }
                }

                if (address == null)
                {
                    return NotFound(new { error = "Không tìm thấy địa chỉ mặc định" });
                }

                return Ok(address);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting default address");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/deliveryaddress
        /// <summary>
        /// Tạo địa chỉ giao hàng mới
        /// </summary>
        [HttpPost]
        public IActionResult CreateDeliveryAddress([FromBody] DeliveryAddressRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.MaTaiKhoan))
                {
                    return BadRequest(new { error = "MaTaiKhoan is required" });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var maDiaChi = $"DC-{Guid.NewGuid().ToString().Substring(0, 8).ToUpper()}";

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Nếu đặt làm mặc định, bỏ mặc định của các địa chỉ khác
                    if (request.LaDiaChiMacDinh)
                    {
                        string updateQuery = @"
                            UPDATE DiaChiGiaoHang
                            SET LaDiaChiMacDinh = 0
                            WHERE MaTaiKhoan = @MaTaiKhoan";

                        using (var updateCommand = new SqlCommand(updateQuery, connection))
                        {
                            updateCommand.Parameters.AddWithValue("@MaTaiKhoan", request.MaTaiKhoan);
                            updateCommand.ExecuteNonQuery();
                        }
                    }

                    // Tạo địa chỉ mới
                    string insertQuery = @"
                        INSERT INTO DiaChiGiaoHang 
                        (MaDiaChi, MaTaiKhoan, HoTen, SoDienThoai, DiaChi, LaDiaChiMacDinh, NgayTao)
                        VALUES 
                        (@MaDiaChi, @MaTaiKhoan, @HoTen, @SoDienThoai, @DiaChi, @LaDiaChiMacDinh, GETDATE())";

                    using (var command = new SqlCommand(insertQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaDiaChi", maDiaChi);
                        command.Parameters.AddWithValue("@MaTaiKhoan", request.MaTaiKhoan);
                        command.Parameters.AddWithValue("@HoTen", request.HoTen);
                        command.Parameters.AddWithValue("@SoDienThoai", request.SoDienThoai);
                        command.Parameters.AddWithValue("@DiaChi", request.DiaChi);
                        command.Parameters.AddWithValue("@LaDiaChiMacDinh", request.LaDiaChiMacDinh);

                        command.ExecuteNonQuery();
                    }
                }

                return Ok(new { maDiaChi = maDiaChi, message = "Địa chỉ đã được tạo thành công" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating delivery address");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/deliveryaddress/{maDiaChi}
        /// <summary>
        /// Cập nhật địa chỉ giao hàng
        /// </summary>
        [HttpPut("{maDiaChi}")]
        public IActionResult UpdateDeliveryAddress(string maDiaChi, [FromBody] DeliveryAddressRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Kiểm tra địa chỉ có tồn tại không
                    string checkQuery = "SELECT MaTaiKhoan FROM DiaChiGiaoHang WHERE MaDiaChi = @MaDiaChi";
                    string? maTaiKhoan = null;

                    using (var checkCommand = new SqlCommand(checkQuery, connection))
                    {
                        checkCommand.Parameters.AddWithValue("@MaDiaChi", maDiaChi);
                        var result = checkCommand.ExecuteScalar();
                        if (result == null)
                        {
                            return NotFound(new { error = "Không tìm thấy địa chỉ" });
                        }
                        maTaiKhoan = result.ToString();
                    }

                    // Nếu đặt làm mặc định, bỏ mặc định của các địa chỉ khác
                    if (request.LaDiaChiMacDinh)
                    {
                        string updateQuery = @"
                            UPDATE DiaChiGiaoHang
                            SET LaDiaChiMacDinh = 0
                            WHERE MaTaiKhoan = @MaTaiKhoan AND MaDiaChi != @MaDiaChi";

                        using (var updateCommand = new SqlCommand(updateQuery, connection))
                        {
                            updateCommand.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);
                            updateCommand.Parameters.AddWithValue("@MaDiaChi", maDiaChi);
                            updateCommand.ExecuteNonQuery();
                        }
                    }

                    // Cập nhật địa chỉ
                    string query = @"
                        UPDATE DiaChiGiaoHang
                        SET HoTen = @HoTen,
                            SoDienThoai = @SoDienThoai,
                            DiaChi = @DiaChi,
                            LaDiaChiMacDinh = @LaDiaChiMacDinh,
                            NgayCapNhat = GETDATE()
                        WHERE MaDiaChi = @MaDiaChi";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaDiaChi", maDiaChi);
                        command.Parameters.AddWithValue("@HoTen", request.HoTen);
                        command.Parameters.AddWithValue("@SoDienThoai", request.SoDienThoai);
                        command.Parameters.AddWithValue("@DiaChi", request.DiaChi);
                        command.Parameters.AddWithValue("@LaDiaChiMacDinh", request.LaDiaChiMacDinh);

                        int rowsAffected = command.ExecuteNonQuery();
                        if (rowsAffected == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy địa chỉ để cập nhật" });
                        }
                    }
                }

                return Ok(new { message = "Địa chỉ đã được cập nhật thành công" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating delivery address");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/deliveryaddress/{maDiaChi}
        /// <summary>
        /// Xóa địa chỉ giao hàng
        /// </summary>
        [HttpDelete("{maDiaChi}")]
        public IActionResult DeleteDeliveryAddress(string maDiaChi)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = "DELETE FROM DiaChiGiaoHang WHERE MaDiaChi = @MaDiaChi";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaDiaChi", maDiaChi);

                        int rowsAffected = command.ExecuteNonQuery();
                        if (rowsAffected == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy địa chỉ để xóa" });
                        }
                    }
                }

                return Ok(new { message = "Địa chỉ đã được xóa thành công" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting delivery address");
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}
