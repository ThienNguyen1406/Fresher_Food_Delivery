using FressFood.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace FoodShop.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NotificationController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public NotificationController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        /// <summary>
        /// Lấy danh sách thông báo cho admin
        /// GET: api/Notification/admin/{maAdmin}
        /// </summary>
        [HttpGet("admin/{maAdmin}")]
        public IActionResult GetNotificationsByAdmin(string maAdmin, [FromQuery] bool? unreadOnly = false)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var notifications = new List<Notification>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    string query = @"SELECT MaThongBao, LoaiThongBao, MaDonHang, MaNguoiNhan, 
                                    TieuDe, NoiDung, DaDoc, NgayTao, NgayDoc
                                    FROM Notification
                                    WHERE MaNguoiNhan = @MaNguoiNhan";
                    
                    if (unreadOnly == true)
                    {
                        query += " AND DaDoc = 0";
                    }
                    
                    query += " ORDER BY NgayTao DESC";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaNguoiNhan", maAdmin);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                notifications.Add(new Notification
                                {
                                    MaThongBao = reader["MaThongBao"].ToString(),
                                    LoaiThongBao = reader["LoaiThongBao"].ToString(),
                                    MaDonHang = reader["MaDonHang"] as string,
                                    MaNguoiNhan = reader["MaNguoiNhan"].ToString(),
                                    TieuDe = reader["TieuDe"].ToString(),
                                    NoiDung = reader["NoiDung"] as string,
                                    DaDoc = Convert.ToBoolean(reader["DaDoc"]),
                                    NgayTao = Convert.ToDateTime(reader["NgayTao"]),
                                    NgayDoc = reader["NgayDoc"] as DateTime?
                                });
                            }
                        }
                    }
                }

                return Ok(new { message = "Lấy danh sách thông báo thành công", data = notifications });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Đếm số thông báo chưa đọc của admin
        /// GET: api/Notification/admin/{maAdmin}/unread-count
        /// </summary>
        [HttpGet("admin/{maAdmin}/unread-count")]
        public IActionResult GetUnreadCount(string maAdmin)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                int count = 0;

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    string query = @"SELECT COUNT(*) 
                                    FROM Notification
                                    WHERE MaNguoiNhan = @MaNguoiNhan AND DaDoc = 0";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaNguoiNhan", maAdmin);
                        count = Convert.ToInt32(command.ExecuteScalar());
                    }
                }

                return Ok(new { message = "Lấy số thông báo chưa đọc thành công", count = count });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Đánh dấu thông báo đã đọc
        /// PUT: api/Notification/{maThongBao}/read
        /// </summary>
        [HttpPut("{maThongBao}/read")]
        public IActionResult MarkAsRead(string maThongBao)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    string query = @"UPDATE Notification 
                                    SET DaDoc = 1, NgayDoc = GETDATE()
                                    WHERE MaThongBao = @MaThongBao";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaThongBao", maThongBao);
                        
                        int rowsAffected = command.ExecuteNonQuery();
                        
                        if (rowsAffected > 0)
                        {
                            return Ok(new { message = "Đánh dấu thông báo đã đọc thành công" });
                        }
                        else
                        {
                            return NotFound(new { error = "Không tìm thấy thông báo" });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Đánh dấu tất cả thông báo của admin đã đọc
        /// PUT: api/Notification/admin/{maAdmin}/read-all
        /// </summary>
        [HttpPut("admin/{maAdmin}/read-all")]
        public IActionResult MarkAllAsRead(string maAdmin)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    string query = @"UPDATE Notification 
                                    SET DaDoc = 1, NgayDoc = GETDATE()
                                    WHERE MaNguoiNhan = @MaNguoiNhan AND DaDoc = 0";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaNguoiNhan", maAdmin);
                        
                        int rowsAffected = command.ExecuteNonQuery();
                        
                        return Ok(new { 
                            message = "Đánh dấu tất cả thông báo đã đọc thành công",
                            count = rowsAffected 
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}

