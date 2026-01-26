using FressFood.Models;
using FressFood.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Linq;

namespace FoodShop.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly EmailService _emailService;
        private readonly ILogger<UserController> _logger;

        public UserController(IConfiguration configuration, EmailService emailService, ILogger<UserController> logger)
        {
            _configuration = configuration;
            _emailService = emailService;
            _logger = logger;
        }

        [HttpPost("login")]
        public IActionResult Login(LoginRequest loginRequest)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                
                if (string.IsNullOrEmpty(connectionString))
                {
                    return StatusCode(500, new { error = "Connection string không được cấu hình" });
                }

                User user = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    try
                    {
                        connection.Open();
                    }
                    catch (SqlException sqlEx)
                    {
                        // Lấy tên database từ connection string
                        var dbName = "database";
                        if (!string.IsNullOrEmpty(connectionString))
                        {
                            var dbMatch = System.Text.RegularExpressions.Regex.Match(connectionString, @"Database=([^;]+)", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                            if (dbMatch.Success)
                            {
                                dbName = dbMatch.Groups[1].Value;
                            }
                        }
                        return StatusCode(500, new { error = $"Lỗi kết nối database: {sqlEx.Message}. Vui lòng kiểm tra SQL Server đã chạy và database '{dbName}' đã tồn tại." });
                    }
                    string query = @"SELECT MaTaiKhoan, TenNguoiDung, MatKhau, Email, HoTen, Sdt, DiaChi, VaiTro, Avatar 
                                   FROM NguoiDung 
                                   WHERE Email = @Email AND MatKhau = @MatKhau";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Email", loginRequest.Email);
                        command.Parameters.AddWithValue("@MatKhau", loginRequest.MatKhau);

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                user = new User
                                {
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString() ?? "",
                                    TenNguoiDung = reader["TenNguoiDung"].ToString() ?? "",
                                    MatKhau = reader["MatKhau"].ToString() ?? "",
                                    Email = reader["Email"] as string,
                                    HoTen = reader["HoTen"] as string,
                                    Sdt = reader["Sdt"] as string,
                                    DiaChi = reader["DiaChi"] as string,
                                    VaiTro = reader["VaiTro"].ToString() ?? "User",
                                    Avatar = reader["Avatar"] as string
                                };
                            }
                        }
                    }
                }

                if (user == null)
                {
                    return Unauthorized(new { error = "Tên đăng nhập hoặc mật khẩu không đúng" });
                }

                // Ẩn mật khẩu trước khi trả về
                var userResponse = new
                {
                    user.MaTaiKhoan,
                    user.TenNguoiDung,
                    user.Email,
                    user.HoTen,
                    user.Sdt,
                    user.DiaChi,
                    user.VaiTro,
                    user.Avatar
                };

                return Ok(new { message = "Đăng nhập thành công", user = userResponse });
            }
            catch (SqlException sqlEx)
            {
                return StatusCode(500, new { error = $"Lỗi database: {sqlEx.Message}" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = $"Lỗi đăng nhập: {ex.Message}" });
            }
        }
        // GET: api/User
        [HttpGet]
        public IActionResult Get()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var users = new List<User>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = "SELECT MaTaiKhoan, TenNguoiDung, MatKhau, Email, HoTen, Sdt, DiaChi, VaiTro, Avatar FROM NguoiDung";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var user = new User
                            {
                                MaTaiKhoan = reader["MaTaiKhoan"].ToString() ?? "",
                                TenNguoiDung = reader["TenNguoiDung"].ToString() ?? "",
                                MatKhau = reader["MatKhau"].ToString() ?? "",
                                Email = reader["Email"] as string,
                                HoTen = reader["HoTen"] as string,
                                Sdt = reader["Sdt"] as string,
                                DiaChi = reader["DiaChi"] as string,
                                VaiTro = reader["VaiTro"].ToString() ?? "User",
                                Avatar = reader["Avatar"] as string
                            };
                            users.Add(user);
                        }
                    }
                }
                return Ok(users);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/User/search/{name}
        [HttpGet("search/{name}")]
        public IActionResult SearchByName(string name)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var users = new List<User>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT MaTaiKhoan, TenNguoiDung, MatKhau, Email, HoTen, Sdt, DiaChi, VaiTro, Avatar 
                                   FROM NguoiDung 
                                   WHERE TenNguoiDung LIKE '%' + @Name + '%' OR HoTen LIKE '%' + @Name + '%'";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Name", name);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var user = new User
                                {
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString() ?? "",
                                    TenNguoiDung = reader["TenNguoiDung"].ToString() ?? "",
                                    MatKhau = reader["MatKhau"].ToString() ?? "",
                                    Email = reader["Email"] as string,
                                    HoTen = reader["HoTen"] as string,
                                    Sdt = reader["Sdt"] as string,
                                    DiaChi = reader["DiaChi"] as string,
                                    VaiTro = reader["VaiTro"].ToString() ?? "User",
                                    Avatar = reader["Avatar"] as string
                                };
                                users.Add(user);
                            }
                        }
                    }
                }
                return Ok(users);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/User
        [HttpPost]
        public IActionResult Post(User user)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"INSERT INTO NguoiDung (TenNguoiDung, MatKhau, Email, HoTen, Sdt, DiaChi, VaiTro, Avatar) 
                                   VALUES (@TenNguoiDung, @MatKhau, @Email, @HoTen, @Sdt, @DiaChi, @VaiTro, @Avatar);
                                   SELECT SCOPE_IDENTITY();";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@TenNguoiDung", user.TenNguoiDung);
                        command.Parameters.AddWithValue("@MatKhau", user.MatKhau);
                        command.Parameters.AddWithValue("@Email", user.Email ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@HoTen", user.HoTen ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@Sdt", user.Sdt ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@DiaChi", user.DiaChi ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@VaiTro", user.VaiTro ?? "NguoiDung");
                        command.Parameters.AddWithValue("@Avatar", user.Avatar ?? (object)DBNull.Value);


                        string newId = command.ExecuteScalar()?.ToString();
                        user.MaTaiKhoan = newId;

                    }
                }
                return Ok(new { message = "Thêm người dùng thành công", user });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/User/{id}
        [HttpPut("{id}")]
        public IActionResult Put(string id, User user)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // LẤY THÔNG TIN USER HIỆN TẠI ĐỂ GIỮ NGUYÊN MẬT KHẨU NẾU KHÔNG CUNG CẤP
                    string getCurrentQuery = "SELECT MatKhau FROM NguoiDung WHERE MaTaiKhoan = @MaTaiKhoan";
                    string currentPassword = "";

                    using (var getCommand = new SqlCommand(getCurrentQuery, connection))
                    {
                        getCommand.Parameters.AddWithValue("@MaTaiKhoan", id);
                        var result = getCommand.ExecuteScalar();
                        currentPassword = result?.ToString() ?? "";
                    }

                    // CHỈ CẬP NHẬT MẬT KHẨU NẾU ĐƯỢC CUNG CẤP VÀ KHÁC RỖNG
                    string updateQuery = @"UPDATE NguoiDung 
                               SET TenNguoiDung = @TenNguoiDung, 
                                   MatKhau = @MatKhau, 
                                   Email = @Email, 
                                   HoTen = @HoTen, 
                                   Sdt = @Sdt, 
                                   DiaChi = @DiaChi, 
                                   VaiTro = @VaiTro,
                                   Avatar = @Avatar
                               WHERE MaTaiKhoan = @MaTaiKhoan";

                    using (var command = new SqlCommand(updateQuery, connection))
                    {
                        // Sử dụng id từ route parameter thay vì từ user object
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);
                        command.Parameters.AddWithValue("@TenNguoiDung", user.TenNguoiDung ?? "");

                        // QUAN TRỌNG: Giữ nguyên mật khẩu cũ nếu mật khẩu mới rỗng
                        command.Parameters.AddWithValue("@MatKhau",
                            string.IsNullOrEmpty(user.MatKhau) ? currentPassword : user.MatKhau);

                        command.Parameters.AddWithValue("@Email", user.Email ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@HoTen", user.HoTen ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@Sdt", user.Sdt ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@DiaChi", user.DiaChi ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@VaiTro", user.VaiTro ?? "User");
                        command.Parameters.AddWithValue("@Avatar", user.Avatar ?? (object)DBNull.Value);

                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy người dùng" });
                        }
                    }
                }
                return Ok(new { message = "Cập nhật người dùng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/User/{id}
        [HttpDelete("{id}")]
        public IActionResult Delete(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    // Kiểm tra xem người dùng có tồn tại không
                    string checkQuery = "SELECT COUNT(*) FROM NguoiDung WHERE MaTaiKhoan = @MaTaiKhoan";
                    using (var checkCommand = new SqlCommand(checkQuery, connection))
                    {
                        checkCommand.Parameters.AddWithValue("@MaTaiKhoan", id);
                        int userExists = Convert.ToInt32(checkCommand.ExecuteScalar());
                        if (userExists == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy người dùng" });
                        }
                    }

                    // Xóa các dữ liệu liên quan trước (theo thứ tự để tránh foreign key constraint)
                    // 1. Xóa thông báo (Notification) - có foreign key đến MaNguoiNhan
                    string deleteNotificationsQuery = "DELETE FROM Notification WHERE MaNguoiNhan = @MaTaiKhoan";
                    using (var command = new SqlCommand(deleteNotificationsQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);
                        command.ExecuteNonQuery();
                    }

                    // 2. Xóa tin nhắn (Message) - phải xóa trước vì có thể liên quan đến Chat
                    string deleteMessagesQuery = @"
                        DELETE FROM Message 
                        WHERE MaChat IN (SELECT MaChat FROM Chat WHERE MaNguoiDung = @MaTaiKhoan)";
                    using (var command = new SqlCommand(deleteMessagesQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);
                        command.ExecuteNonQuery();
                    }

                    // 3. Xóa cuộc trò chuyện (Chat)
                    string deleteChatsQuery = "DELETE FROM Chat WHERE MaNguoiDung = @MaTaiKhoan";
                    using (var command = new SqlCommand(deleteChatsQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);
                        command.ExecuteNonQuery();
                    }

                    // 4. Xóa giỏ hàng (GioHang)
                    string deleteCartQuery = "DELETE FROM GioHang WHERE MaTaiKhoan = @MaTaiKhoan";
                    using (var command = new SqlCommand(deleteCartQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);
                        command.ExecuteNonQuery();
                    }

                    // 5. Xóa đơn hàng (DonHang) - nếu có foreign key constraint
                    // Lưu ý: Có thể cần xóa chi tiết đơn hàng trước
                    string deleteOrderDetailsQuery = @"
                        DELETE FROM ChiTietDonHang 
                        WHERE MaDonHang IN (SELECT MaDonHang FROM DonHang WHERE MaTaiKhoan = @MaTaiKhoan)";
                    using (var command = new SqlCommand(deleteOrderDetailsQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);
                        command.ExecuteNonQuery();
                    }

                    string deleteOrdersQuery = "DELETE FROM DonHang WHERE MaTaiKhoan = @MaTaiKhoan";
                    using (var command = new SqlCommand(deleteOrdersQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);
                        command.ExecuteNonQuery();
                    }

                    // 5. Cuối cùng mới xóa người dùng
                    string deleteUserQuery = "DELETE FROM NguoiDung WHERE MaTaiKhoan = @MaTaiKhoan";
                    using (var command = new SqlCommand(deleteUserQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);
                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy người dùng" });
                        }
                    }
                }
                return Ok(new { message = "Xóa người dùng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/User/{id}/avatar - Upload avatar file
        [HttpPost("{id}/avatar")]
        public async Task<IActionResult> UploadAvatar(string id, IFormFile file)
        {
            try
            {
                if (file == null || file.Length == 0)
                {
                    return BadRequest(new { error = "Không có file được upload" });
                }

                // Kiểm tra định dạng file (chỉ cho phép ảnh)
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
                var extension = Path.GetExtension(file.FileName).ToLower();
                
                if (!allowedExtensions.Contains(extension))
                {
                    return BadRequest(new { error = $"Định dạng file không được hỗ trợ. Chỉ chấp nhận: {string.Join(", ", allowedExtensions)}" });
                }

                // Giới hạn kích thước file (5MB)
                if (file.Length > 5 * 1024 * 1024)
                {
                    return BadRequest(new { error = "Kích thước file vượt quá 5MB" });
                }

                // Lưu file ảnh
                var folderPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "avatars");
                if (!Directory.Exists(folderPath))
                {
                    Directory.CreateDirectory(folderPath);
                }

                var fileName = $"{id}_{DateTime.Now.Ticks}{extension}";
                var filePath = Path.Combine(folderPath, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // Lưu đường dẫn vào database (relative path)
                var avatarPath = $"images/avatars/{fileName}";
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"UPDATE NguoiDung 
                                   SET Avatar = @Avatar 
                                   WHERE MaTaiKhoan = @MaTaiKhoan";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);
                        command.Parameters.AddWithValue("@Avatar", avatarPath);

                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            // Xóa file nếu không tìm thấy user
                            if (System.IO.File.Exists(filePath))
                            {
                                System.IO.File.Delete(filePath);
                            }
                            return NotFound(new { error = "Không tìm thấy người dùng" });
                        }
                    }
                }

                // Trả về URL đầy đủ
                var avatarUrl = $"{Request.Scheme}://{Request.Host}/{avatarPath}";
                return Ok(new { message = "Upload avatar thành công", avatarUrl = avatarUrl, avatarPath = avatarPath });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading avatar for user {UserId}", id);
                return StatusCode(500, new { error = $"Lỗi upload avatar: {ex.Message}" });
            }
        }

        // PUT: api/User/{id}/avatar - Cập nhật avatar URL
        [HttpPut("{id}/avatar")]
        public IActionResult UpdateAvatar(string id, [FromBody] AvatarRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"UPDATE NguoiDung 
                                   SET Avatar = @Avatar 
                                   WHERE MaTaiKhoan = @MaTaiKhoan";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);
                        command.Parameters.AddWithValue("@Avatar", request.AvatarUrl ?? (object)DBNull.Value);

                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy người dùng" });
                        }
                    }
                }
                return Ok(new { message = "Cập nhật avatar thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/User/{id}/avatar - Xóa avatar
        [HttpDelete("{id}/avatar")]
        public IActionResult DeleteAvatar(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"UPDATE NguoiDung 
                                   SET Avatar = NULL 
                                   WHERE MaTaiKhoan = @MaTaiKhoan";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);

                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy người dùng" });
                        }
                    }
                }
                return Ok(new { message = "Xóa avatar thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/User/{id} - Lấy thông tin user theo ID
        [HttpGet("{id}")]
        public IActionResult GetUserById(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                User user = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT MaTaiKhoan, TenNguoiDung, MatKhau, Email, HoTen, Sdt, DiaChi, VaiTro, Avatar 
                                   FROM NguoiDung 
                                   WHERE MaTaiKhoan = @MaTaiKhoan";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", id);

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                user = new User
                                {
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString() ?? "",
                                    TenNguoiDung = reader["TenNguoiDung"].ToString() ?? "",
                                    MatKhau = reader["MatKhau"].ToString() ?? "",
                                    Email = reader["Email"] as string,
                                    HoTen = reader["HoTen"] as string,
                                    Sdt = reader["Sdt"] as string,
                                    DiaChi = reader["DiaChi"] as string,
                                    VaiTro = reader["VaiTro"].ToString() ?? "User",
                                    Avatar = reader["Avatar"] as string
                                };
                            }
                        }
                    }
                }

                if (user == null)
                {
                    return NotFound(new { error = "Không tìm thấy người dùng" });
                }

                // Ẩn mật khẩu trước khi trả về
                var userResponse = new
                {
                    user.MaTaiKhoan,
                    user.TenNguoiDung,
                    user.Email,
                    user.HoTen,
                    user.Sdt,
                    user.DiaChi,
                    user.VaiTro,
                    user.Avatar
                };

                return Ok(userResponse);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // Login request model
        public class LoginRequest
        {
            public string Email { get; set; } = string.Empty;
            public string MatKhau { get; set; } = string.Empty;
        }

        // Avatar request model
        public class AvatarRequest
        {
            public string? AvatarUrl { get; set; }
        }

        // POST: api/User/request-password-reset - User yêu cầu đặt lại mật khẩu bằng email
        [HttpPost("request-password-reset")]
        public async Task<IActionResult> RequestPasswordReset([FromBody] CreatePasswordResetRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Email))
                {
                    return BadRequest(new { error = "Email không được để trống" });
                }

                // Validate email format
                if (!System.Text.RegularExpressions.Regex.IsMatch(request.Email, 
                    @"^[^@\s]+@[^@\s]+\.[^@\s]+$", System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                {
                    return BadRequest(new { error = "Email không hợp lệ" });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                string maYeuCau = string.Empty; // Khai báo ở ngoài để có thể sử dụng sau

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Kiểm tra user có tồn tại không
                    string checkUserQuery = @"SELECT MaTaiKhoan, TenNguoiDung, HoTen, Email 
                                            FROM NguoiDung 
                                            WHERE Email = @Email";
                    
                    string? userId = null;
                    string? userName = null;
                    string? userFullName = null;

                    using (var checkCommand = new SqlCommand(checkUserQuery, connection))
                    {
                        checkCommand.Parameters.AddWithValue("@Email", request.Email);
                        using (var reader = checkCommand.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                userId = reader["MaTaiKhoan"]?.ToString();
                                userName = reader["TenNguoiDung"]?.ToString();
                                userFullName = reader["HoTen"]?.ToString();
                            }
                        }
                    }

                    if (string.IsNullOrEmpty(userId))
                    {
                        // Không trả về lỗi chi tiết để bảo mật
                        return Ok(new { message = "Nếu email tồn tại trong hệ thống, bạn sẽ nhận được thông báo." });
                    }

                    // Kiểm tra xem đã có request pending chưa
                    string checkPendingQuery = @"SELECT COUNT(*) 
                                                FROM PasswordResetRequest 
                                                WHERE Email = @Email AND TrangThai = 'Pending'";
                    
                    int pendingCount = 0;
                    using (var checkPendingCommand = new SqlCommand(checkPendingQuery, connection))
                    {
                        checkPendingCommand.Parameters.AddWithValue("@Email", request.Email);
                        pendingCount = (int)checkPendingCommand.ExecuteScalar();
                    }

                    if (pendingCount > 0)
                    {
                        return BadRequest(new { error = "Bạn đã có yêu cầu đang chờ xử lý. Vui lòng đợi admin xem xét." });
                    }

                    // Tạo request mới
                    maYeuCau = $"PWR-{Guid.NewGuid().ToString().Substring(0, 8).ToUpper()}";
                    string insertQuery = @"INSERT INTO PasswordResetRequest 
                                          (MaYeuCau, Email, MaNguoiDung, TenNguoiDung, TrangThai, NgayTao)
                                          VALUES (@MaYeuCau, @Email, @MaNguoiDung, @TenNguoiDung, 'Pending', @NgayTao)";

                    using (var insertCommand = new SqlCommand(insertQuery, connection))
                    {
                        insertCommand.Parameters.AddWithValue("@MaYeuCau", maYeuCau);
                        insertCommand.Parameters.AddWithValue("@Email", request.Email);
                        insertCommand.Parameters.AddWithValue("@MaNguoiDung", userId);
                        insertCommand.Parameters.AddWithValue("@TenNguoiDung", userName ?? userFullName ?? "User");
                        insertCommand.Parameters.AddWithValue("@NgayTao", DateTime.Now);

                        insertCommand.ExecuteNonQuery();
                    }

                    // Gửi thông báo cho tất cả admin
                    string adminQuery = "SELECT MaTaiKhoan, Email FROM NguoiDung WHERE VaiTro = 'Admin' OR VaiTro = N'Admin'";
                    var adminList = new List<(string Id, string Email)>();

                    using (var adminCommand = new SqlCommand(adminQuery, connection))
                    {
                        using (var reader = adminCommand.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                adminList.Add((
                                    reader["MaTaiKhoan"].ToString() ?? "",
                                    reader["Email"]?.ToString() ?? ""
                                ));
                            }
                        }
                    }

                    // Tạo notification cho admin
                    foreach (var admin in adminList)
                    {
                        if (!string.IsNullOrEmpty(admin.Id))
                        {
                            string maThongBao = $"NOTIF_PWR_{maYeuCau}_{admin.Id}_{DateTime.Now:yyyyMMddHHmmss}";
                            string notifQuery = @"INSERT INTO Notification 
                                                (MaThongBao, LoaiThongBao, MaNguoiNhan, TieuDe, NoiDung, DaDoc, NgayTao)
                                                VALUES (@MaThongBao, 'PasswordResetRequest', @MaNguoiNhan, @TieuDe, @NoiDung, 0, @NgayTao)";

                            using (var notifCommand = new SqlCommand(notifQuery, connection))
                            {
                                notifCommand.Parameters.AddWithValue("@MaThongBao", maThongBao);
                                notifCommand.Parameters.AddWithValue("@MaNguoiNhan", admin.Id);
                                notifCommand.Parameters.AddWithValue("@TieuDe", "Yêu cầu đặt lại mật khẩu mới");
                                notifCommand.Parameters.AddWithValue("@NoiDung", $"Người dùng {request.Email} đã yêu cầu đặt lại mật khẩu. Mã yêu cầu: {maYeuCau}");
                                notifCommand.Parameters.AddWithValue("@NgayTao", DateTime.Now);
                                notifCommand.ExecuteNonQuery();
                            }

                            // Gửi email thông báo cho admin (nếu có email)
                            if (!string.IsNullOrEmpty(admin.Email))
                            {
                                _ = Task.Run(async () =>
                                {
                                    await _emailService.NotifyAdminNewPasswordResetRequestAsync(
                                        admin.Email,
                                        request.Email,
                                        userName ?? userFullName ?? "User",
                                        DateTime.Now
                                    );
                                });
                            }
                        }
                    }

                    _logger.LogInformation($"Password reset request created: {maYeuCau} for email: {request.Email}");
                }

                return Ok(new { 
                    message = "Yêu cầu đặt lại mật khẩu đã được gửi. Admin sẽ xem xét và phản hồi qua email của bạn.",
                    maYeuCau 
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating password reset request");
                return StatusCode(500, new { error = $"Lỗi: {ex.Message}" });
            }
        }

        // GET: api/User/password-reset-requests - Admin xem danh sách yêu cầu
        [HttpGet("password-reset-requests")]
        public IActionResult GetPasswordResetRequests([FromQuery] string? trangThai = null)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var requests = new List<PasswordResetRequest>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    
                    string query = @"SELECT MaYeuCau, Email, MaNguoiDung, TenNguoiDung, TrangThai, 
                                    NgayTao, NgayXuLy, MaAdminXuLy
                                    FROM PasswordResetRequest";
                    
                    if (!string.IsNullOrEmpty(trangThai))
                    {
                        query += " WHERE TrangThai = @TrangThai";
                    }
                    
                    query += " ORDER BY NgayTao DESC";

                    using (var command = new SqlCommand(query, connection))
                    {
                        if (!string.IsNullOrEmpty(trangThai))
                        {
                            command.Parameters.AddWithValue("@TrangThai", trangThai);
                        }

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                requests.Add(new PasswordResetRequest
                                {
                                    MaYeuCau = reader["MaYeuCau"].ToString() ?? "",
                                    Email = reader["Email"].ToString() ?? "",
                                    MaNguoiDung = reader["MaNguoiDung"]?.ToString(),
                                    TenNguoiDung = reader["TenNguoiDung"]?.ToString(),
                                    TrangThai = reader["TrangThai"].ToString() ?? "Pending",
                                    NgayTao = reader.GetDateTime(reader.GetOrdinal("NgayTao")),
                                    NgayXuLy = reader.IsDBNull(reader.GetOrdinal("NgayXuLy"))
                                        ? (DateTime?)null
                                        : reader.GetDateTime(reader.GetOrdinal("NgayXuLy")),
                                    MaAdminXuLy = reader["MaAdminXuLy"]?.ToString()
                                });
                            }
                        }
                    }
                }

                return Ok(requests);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting password reset requests");
                return StatusCode(500, new { error = $"Lỗi: {ex.Message}" });
            }
        }

        // POST: api/User/process-password-reset - Admin xử lý yêu cầu
        [HttpPost("process-password-reset")]
        public async Task<IActionResult> ProcessPasswordReset([FromBody] ProcessPasswordResetRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.MaYeuCau))
                {
                    return BadRequest(new { error = "Mã yêu cầu không được để trống" });
                }

                if (request.Action != "Approve" && request.Action != "Reject")
                {
                    return BadRequest(new { error = "Action phải là 'Approve' hoặc 'Reject'" });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Lấy thông tin request
                    string getRequestQuery = @"SELECT MaYeuCau, Email, MaNguoiDung, TenNguoiDung, TrangThai 
                                             FROM PasswordResetRequest 
                                             WHERE MaYeuCau = @MaYeuCau";

                    PasswordResetRequest? resetRequest = null;
                    using (var getCommand = new SqlCommand(getRequestQuery, connection))
                    {
                        getCommand.Parameters.AddWithValue("@MaYeuCau", request.MaYeuCau);
                        using (var reader = getCommand.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                resetRequest = new PasswordResetRequest
                                {
                                    MaYeuCau = reader["MaYeuCau"].ToString() ?? "",
                                    Email = reader["Email"].ToString() ?? "",
                                    MaNguoiDung = reader["MaNguoiDung"]?.ToString(),
                                    TenNguoiDung = reader["TenNguoiDung"]?.ToString(),
                                    TrangThai = reader["TrangThai"].ToString() ?? "Pending"
                                };
                            }
                        }
                    }

                    if (resetRequest == null)
                    {
                        return NotFound(new { error = "Không tìm thấy yêu cầu" });
                    }

                    if (resetRequest.TrangThai != "Pending")
                    {
                        return BadRequest(new { error = "Yêu cầu này đã được xử lý rồi" });
                    }

                    if (request.Action == "Approve")
                    {
                        // Generate password mới
                        string newPassword = GenerateRandomPassword(12);

                        // Cập nhật password trong database
                        string updatePasswordQuery = @"UPDATE NguoiDung 
                                                      SET MatKhau = @NewPassword 
                                                      WHERE MaTaiKhoan = @MaTaiKhoan";

                        using (var updateCommand = new SqlCommand(updatePasswordQuery, connection))
                        {
                            updateCommand.Parameters.AddWithValue("@MaTaiKhoan", resetRequest.MaNguoiDung);
                            updateCommand.Parameters.AddWithValue("@NewPassword", newPassword);
                            int affectedRows = updateCommand.ExecuteNonQuery();

                            if (affectedRows == 0)
                            {
                                return StatusCode(500, new { error = "Không tìm thấy người dùng để cập nhật mật khẩu" });
                            }
                        }

                        // Cập nhật trạng thái request
                        string updateRequestQuery = @"UPDATE PasswordResetRequest 
                                                     SET TrangThai = 'Approved', 
                                                         NgayXuLy = @NgayXuLy, 
                                                         MaAdminXuLy = @MaAdminXuLy,
                                                         MatKhauMoi = @MatKhauMoi
                                                     WHERE MaYeuCau = @MaYeuCau";

                        using (var updateRequestCommand = new SqlCommand(updateRequestQuery, connection))
                        {
                            updateRequestCommand.Parameters.AddWithValue("@MaYeuCau", request.MaYeuCau);
                            updateRequestCommand.Parameters.AddWithValue("@NgayXuLy", DateTime.Now);
                            updateRequestCommand.Parameters.AddWithValue("@MaAdminXuLy", request.MaAdmin ?? "SYSTEM");
                            updateRequestCommand.Parameters.AddWithValue("@MatKhauMoi", newPassword);
                            updateRequestCommand.ExecuteNonQuery();
                        }

                        // Gửi email mật khẩu mới
                        _ = Task.Run(async () =>
                        {
                            try
                            {
                                var emailSent = await _emailService.SendPasswordResetEmailAsync(
                                    resetRequest.Email,
                                    resetRequest.TenNguoiDung ?? "User",
                                    newPassword
                                );
                                
                                if (emailSent)
                                {
                                    _logger.LogInformation($"Password reset email sent successfully to {resetRequest.Email}");
                                }
                                else
                                {
                                    _logger.LogWarning($"Failed to send password reset email to {resetRequest.Email}. Email service may not be configured.");
                                }
                            }
                            catch (Exception emailEx)
                            {
                                _logger.LogError(emailEx, $"Error sending password reset email to {resetRequest.Email}: {emailEx.Message}");
                            }
                        });

                        _logger.LogInformation($"Password reset approved: {request.MaYeuCau} for email: {resetRequest.Email}");
                        
                        return Ok(new { 
                            message = "Yêu cầu đã được chấp nhận. Mật khẩu mới đã được gửi qua email.",
                            maYeuCau = request.MaYeuCau
                        });
                    }
                    else // Reject
                    {
                        // Cập nhật trạng thái request
                        string updateRequestQuery = @"UPDATE PasswordResetRequest 
                                                     SET TrangThai = 'Rejected', 
                                                         NgayXuLy = @NgayXuLy, 
                                                         MaAdminXuLy = @MaAdminXuLy
                                                     WHERE MaYeuCau = @MaYeuCau";

                        using (var updateRequestCommand = new SqlCommand(updateRequestQuery, connection))
                        {
                            updateRequestCommand.Parameters.AddWithValue("@MaYeuCau", request.MaYeuCau);
                            updateRequestCommand.Parameters.AddWithValue("@NgayXuLy", DateTime.Now);
                            updateRequestCommand.Parameters.AddWithValue("@MaAdminXuLy", request.MaAdmin ?? "SYSTEM");
                            updateRequestCommand.ExecuteNonQuery();
                        }

                        // Gửi email thông báo từ chối
                        _ = Task.Run(async () =>
                        {
                            try
                            {
                                var emailSent = await _emailService.SendPasswordResetRejectedEmailAsync(
                                    resetRequest.Email,
                                    resetRequest.TenNguoiDung ?? "User"
                                );
                                
                                if (emailSent)
                                {
                                    _logger.LogInformation($"Password reset rejection email sent successfully to {resetRequest.Email}");
                                }
                                else
                                {
                                    _logger.LogWarning($"Failed to send password reset rejection email to {resetRequest.Email}. Email service may not be configured.");
                                }
                            }
                            catch (Exception emailEx)
                            {
                                _logger.LogError(emailEx, $"Error sending password reset rejection email to {resetRequest.Email}: {emailEx.Message}");
                            }
                        });

                        _logger.LogInformation($"Password reset rejected: {request.MaYeuCau} for email: {resetRequest.Email}");
                        
                        return Ok(new { 
                            message = "Yêu cầu đã bị từ chối. Email thông báo đã được gửi.",
                            maYeuCau = request.MaYeuCau
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing password reset request");
                return StatusCode(500, new { error = $"Lỗi: {ex.Message}" });
            }
        }

        /// <summary>
        /// Generate random password
        /// </summary>
        private string GenerateRandomPassword(int length)
        {
            const string validChars = "ABCDEFGHJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*";
            var random = new Random();
            return new string(Enumerable.Repeat(validChars, length)
                .Select(s => s[random.Next(s.Length)]).ToArray());
        }

        // Change password request model
        public class ChangePasswordRequest
        {
            public string MaTaiKhoan { get; set; } = string.Empty;
            public string MatKhauCu { get; set; } = string.Empty;
            public string MatKhauMoi { get; set; } = string.Empty;
        }

        // Reset password request model (deprecated - giữ để tương thích)
        public class ResetPasswordRequest
        {
            public string PhoneNumber { get; set; } = string.Empty;
            public string NewPassword { get; set; } = string.Empty;
        }

        // POST: api/User/change-password - User đổi mật khẩu (cần mật khẩu cũ)
        [HttpPost("change-password")]
        public IActionResult ChangePassword([FromBody] ChangePasswordRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.MaTaiKhoan))
                {
                    return BadRequest(new { error = "Mã tài khoản không được để trống" });
                }

                if (string.IsNullOrWhiteSpace(request.MatKhauCu))
                {
                    return BadRequest(new { error = "Mật khẩu cũ không được để trống" });
                }

                if (string.IsNullOrWhiteSpace(request.MatKhauMoi))
                {
                    return BadRequest(new { error = "Mật khẩu mới không được để trống" });
                }

                if (request.MatKhauMoi.Length < 6)
                {
                    return BadRequest(new { error = "Mật khẩu mới phải có ít nhất 6 ký tự" });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Kiểm tra mật khẩu cũ có đúng không
                    string checkPasswordQuery = @"SELECT MatKhau FROM NguoiDung WHERE MaTaiKhoan = @MaTaiKhoan";
                    string currentPassword = "";

                    using (var checkCommand = new SqlCommand(checkPasswordQuery, connection))
                    {
                        checkCommand.Parameters.AddWithValue("@MaTaiKhoan", request.MaTaiKhoan);
                        var result = checkCommand.ExecuteScalar();
                        if (result == null)
                        {
                            return NotFound(new { error = "Không tìm thấy tài khoản" });
                        }
                        currentPassword = result.ToString() ?? "";
                    }

                    // Xác thực mật khẩu cũ
                    if (currentPassword != request.MatKhauCu)
                    {
                        return BadRequest(new { error = "Mật khẩu cũ không đúng" });
                    }

                    // Cập nhật mật khẩu mới
                    string updatePasswordQuery = @"UPDATE NguoiDung 
                                                  SET MatKhau = @MatKhauMoi 
                                                  WHERE MaTaiKhoan = @MaTaiKhoan";

                    using (var updateCommand = new SqlCommand(updatePasswordQuery, connection))
                    {
                        updateCommand.Parameters.AddWithValue("@MaTaiKhoan", request.MaTaiKhoan);
                        updateCommand.Parameters.AddWithValue("@MatKhauMoi", request.MatKhauMoi);
                        
                        int affectedRows = updateCommand.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return StatusCode(500, new { error = "Không thể cập nhật mật khẩu" });
                        }
                    }

                    _logger.LogInformation($"Password changed successfully for user: {request.MaTaiKhoan}");
                    return Ok(new { message = "Đổi mật khẩu thành công" });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error changing password");
                return StatusCode(500, new { error = $"Lỗi: {ex.Message}" });
            }
        }

        [Obsolete("Use request-password-reset instead")]
        public IActionResult ResetPassword(ResetPasswordRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.PhoneNumber))
                {
                    return BadRequest(new { error = "Số điện thoại không được để trống" });
                }

                if (string.IsNullOrEmpty(request.NewPassword))
                {
                    return BadRequest(new { error = "Mật khẩu mới không được để trống" });
                }

                if (request.NewPassword.Length < 6)
                {
                    return BadRequest(new { error = "Mật khẩu phải có ít nhất 6 ký tự" });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                if (string.IsNullOrEmpty(connectionString))
                {
                    return StatusCode(500, new { error = "Connection string không được cấu hình" });
                }

                // Format số điện thoại để tìm kiếm (có thể có +84 hoặc 0 ở đầu)
                string phoneNumber = request.PhoneNumber.Trim();
                
                // Loại bỏ +84 và thay bằng 0 nếu cần
                if (phoneNumber.StartsWith("+84"))
                {
                    phoneNumber = "0" + phoneNumber.Substring(3);
                }
                // Đảm bảo có 0 ở đầu nếu chưa có
                else if (!phoneNumber.StartsWith("0"))
                {
                    phoneNumber = "0" + phoneNumber;
                }

                using (var connection = new SqlConnection(connectionString))
                {
                    try
                    {
                        connection.Open();
                    }
                    catch (SqlException sqlEx)
                    {
                        return StatusCode(500, new { error = $"Lỗi kết nối database: {sqlEx.Message}" });
                    }

                    // Tìm user theo số điện thoại
                    string findUserQuery = @"SELECT MaTaiKhoan, Sdt 
                                           FROM NguoiDung 
                                           WHERE Sdt = @Sdt OR Sdt = @SdtWithPlus84 OR Sdt = @SdtWithoutZero";

                    string? userId = null;
                    using (var findCommand = new SqlCommand(findUserQuery, connection))
                    {
                        // Tìm với nhiều format số điện thoại
                        findCommand.Parameters.AddWithValue("@Sdt", phoneNumber);
                        findCommand.Parameters.AddWithValue("@SdtWithPlus84", "+84" + phoneNumber.Substring(1));
                        findCommand.Parameters.AddWithValue("@SdtWithoutZero", phoneNumber.Substring(1));

                        using (var reader = findCommand.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                userId = reader["MaTaiKhoan"]?.ToString();
                            }
                        }
                    }

                    if (string.IsNullOrEmpty(userId))
                    {
                        return NotFound(new { error = "Không tìm thấy tài khoản với số điện thoại này" });
                    }

                    // Cập nhật mật khẩu mới
                    string updateQuery = @"UPDATE NguoiDung 
                                         SET MatKhau = @NewPassword 
                                         WHERE MaTaiKhoan = @MaTaiKhoan";

                    using (var updateCommand = new SqlCommand(updateQuery, connection))
                    {
                        updateCommand.Parameters.AddWithValue("@MaTaiKhoan", userId);
                        updateCommand.Parameters.AddWithValue("@NewPassword", request.NewPassword);

                        int affectedRows = updateCommand.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return StatusCode(500, new { error = "Cập nhật mật khẩu thất bại" });
                        }
                    }
                }

                return Ok(new { message = "Đặt lại mật khẩu thành công" });
            }
            catch (SqlException sqlEx)
            {
                return StatusCode(500, new { error = $"Lỗi database: {sqlEx.Message}" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = $"Lỗi đặt lại mật khẩu: {ex.Message}" });
            }
        }
    }
}