using FressFood.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Data;

namespace FressFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class FavoriteController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public FavoriteController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // GET: api/Favorite
        [HttpGet]
        public async Task<IActionResult> Get()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var favorites = new List<Favorite>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "SELECT Id, MaTaiKhoan, MaSanPham FROM YeuThich";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var favorite = new Favorite
                            {
                                Id = reader["Id"].ToString(),
                                MaTaiKhoan = reader["MaTaiKhoan"].ToString(),
                                MaSanPham = reader["MaSanPham"].ToString()
                            };
                            favorites.Add(favorite);
                        }
                    }
                }

                return Ok(favorites);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Favorite/User/{maTaiKhoan}
        [HttpGet("User/{maTaiKhoan}")]
        public async Task<IActionResult> GetByUser(string maTaiKhoan)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var favorites = new List<object>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = @"SELECT f.Id, f.MaTaiKhoan, f.MaSanPham, 
                                    p.TenSanPham, p.GiaBan, p.Anh, p.MoTa, p.SoLuongTon
                             FROM YeuThich f
                             INNER JOIN SanPham p ON f.MaSanPham = p.MaSanPham
                             WHERE f.MaTaiKhoan = @MaTaiKhoan";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                var favorite = new
                                {
                                    Id = reader["Id"].ToString(),
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString(),
                                    MaSanPham = reader["MaSanPham"].ToString(),
                                    SanPham = new
                                    {
                                        TenSanPham = reader["TenSanPham"].ToString(),
                                        GiaBan = reader["GiaBan"] != DBNull.Value ? Convert.ToDecimal(reader["GiaBan"]) : 0,
                                        Anh = reader["Anh"].ToString(),
                                        MoTa = reader["MoTa"] != DBNull.Value ? reader["MoTa"].ToString() : "",
                                        SoLuong = reader["SoLuongTon"] != DBNull.Value ? Convert.ToInt32(reader["SoLuongTon"]) : 0,
                                    }
                                };
                                favorites.Add(favorite);
                            }
                        }
                    }
                }

                return Ok(favorites);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Favorite/Check
        [HttpGet("Check")]
        public async Task<IActionResult> CheckFavorite(string maTaiKhoan, string maSanPham)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                bool exists = false;

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "SELECT COUNT(1) FROM YeuThich WHERE MaTaiKhoan = @MaTaiKhoan AND MaSanPham = @MaSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);
                        command.Parameters.AddWithValue("@MaSanPham", maSanPham);

                        var result = await command.ExecuteScalarAsync();
                        exists = Convert.ToInt32(result) > 0;
                    }
                }

                return Ok(new { exists = exists });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Favorite
        [HttpPost]
        public async Task<IActionResult> Post([FromBody] Favorite favorite)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Kiểm tra xem đã tồn tại chưa
                    string checkQuery = "SELECT COUNT(1) FROM YeuThich WHERE MaTaiKhoan = @MaTaiKhoan AND MaSanPham = @MaSanPham";
                    using (var checkCommand = new SqlCommand(checkQuery, connection))
                    {
                        checkCommand.Parameters.AddWithValue("@MaTaiKhoan", favorite.MaTaiKhoan);
                        checkCommand.Parameters.AddWithValue("@MaSanPham", favorite.MaSanPham);

                        var exists = Convert.ToInt32(await checkCommand.ExecuteScalarAsync()) > 0;
                        if (exists)
                        {
                            return Conflict("Sản phẩm đã có trong danh sách yêu thích");
                        }
                    }

                    // Thêm mới
                    string insertQuery = @"INSERT INTO YeuThich (MaTaiKhoan, MaSanPham) 
                                  VALUES (@MaTaiKhoan, @MaSanPham)";

                    using (var command = new SqlCommand(insertQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", favorite.MaTaiKhoan);
                        command.Parameters.AddWithValue("@MaSanPham", favorite.MaSanPham);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok("Thêm vào danh sách yêu thích thành công");
                        else
                            return BadRequest("Thêm vào danh sách yêu thích thất bại");
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Favorite/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "DELETE FROM YeuThich WHERE Id = @Id";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id", id);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok("Xóa khỏi danh sách yêu thích thành công");
                        else
                            return NotFound("Không tìm thấy mục yêu thích để xóa");
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Favorite/Remove
        [HttpDelete("Remove")]
        public async Task<IActionResult> RemoveByProductAndUser(string maTaiKhoan, string maSanPham)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "DELETE FROM YeuThich WHERE MaTaiKhoan = @MaTaiKhoan AND MaSanPham = @MaSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);
                        command.Parameters.AddWithValue("@MaSanPham", maSanPham);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok("Xóa khỏi danh sách yêu thích thành công");
                        else
                            return NotFound("Không tìm thấy mục yêu thích để xóa");
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Favorite/Product/{maTaiKhoan}/{maSanPham}
        [HttpDelete("Product/{maTaiKhoan}/{maSanPham}")]
        public async Task<IActionResult> DeleteFavorite(string maTaiKhoan, string maSanPham)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    string query = "DELETE FROM YeuThich WHERE MaTaiKhoan = @MaTaiKhoan AND MaSanPham = @MaSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);
                        command.Parameters.AddWithValue("@MaSanPham", maSanPham);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok(new { message = "Đã xóa khỏi danh sách yêu thích", success = true });
                        else
                            return NotFound(new { message = "Không tìm thấy mục yêu thích để xóa", success = false });
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