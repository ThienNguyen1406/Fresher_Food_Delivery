using FressFood.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace FoodShop.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public UserController(IConfiguration configuration)
        {
            _configuration = configuration;
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
                        return StatusCode(500, new { error = $"Lỗi kết nối database: {sqlEx.Message}. Vui lòng kiểm tra SQL Server đã chạy và database 'FoodOrder' đã tồn tại." });
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
                    string query = "DELETE FROM NguoiDung WHERE MaTaiKhoan = @MaTaiKhoan";

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
                return Ok(new { message = "Xóa người dùng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/User/{id}/avatar - Cập nhật avatar
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
            public string Email { get; set; }
            public string MatKhau { get; set; }
        }

        // Avatar request model
        public class AvatarRequest
        {
            public string? AvatarUrl { get; set; }
        }
    }
}