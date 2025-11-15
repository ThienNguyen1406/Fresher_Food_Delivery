using FressFood.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace FoodShop.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RatingsController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public RatingsController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // GET: api/ratings
        [HttpGet]
        public IActionResult GetRatings()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var ratings = new List<Rating>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = "SELECT MaSanPham, MaTaiKhoan, NoiDung, SoSao FROM DanhGia";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var rating = new Rating
                            {
                                MaSanPham = reader["MaSanPham"].ToString(),
                                MaTaiKhoan = reader["MaTaiKhoan"].ToString(),
                                NoiDung = reader["NoiDung"] as string,
                                SoSao = Convert.ToInt32(reader["SoSao"])
                            };
                            ratings.Add(rating);
                        }
                    }
                }

                return Ok(ratings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/ratings/{maSanPham}
        [HttpGet("{maSanPham}")]
        public IActionResult GetRatingsByProduct(string maSanPham)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var ratings = new List<Rating>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT MaSanPham, MaTaiKhoan, NoiDung, SoSao 
                                   FROM DanhGia 
                                   WHERE MaSanPham = @MaSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", maSanPham);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var rating = new Rating
                                {
                                    MaSanPham = reader["MaSanPham"].ToString(),
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString(),
                                    NoiDung = reader["NoiDung"] as string,
                                    SoSao = Convert.ToInt32(reader["SoSao"])
                                };
                                ratings.Add(rating);
                            }
                        }
                    }
                }

                return Ok(ratings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/ratings/product/{maSanPham}/average
        [HttpGet("product/{maSanPham}/average")]
        public IActionResult GetAverageRating(string maSanPham)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT 
                                    AVG(CAST(SoSao AS FLOAT)) as AverageRating,
                                    COUNT(*) as TotalRatings
                                    FROM DanhGia 
                                    WHERE MaSanPham = @MaSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", maSanPham);

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                var averageRating = reader["AverageRating"] != DBNull.Value ?
                                    Convert.ToDouble(reader["AverageRating"]) : 0.0;
                                var totalRatings = Convert.ToInt32(reader["TotalRatings"]);

                                return Ok(new
                                {
                                    averageRating = Math.Round(averageRating, 1),
                                    totalRatings = totalRatings
                                });
                            }
                        }
                    }
                }

                return Ok(new { averageRating = 0.0, totalRatings = 0 });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/ratings
        [HttpPost]
        public IActionResult AddRating([FromBody] Rating rating)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Kiểm tra xem đã đánh giá chưa
                    string checkQuery = @"SELECT COUNT(*) FROM DanhGia 
                                        WHERE MaSanPham = @MaSanPham AND MaTaiKhoan = @MaTaiKhoan";

                    using (var checkCommand = new SqlCommand(checkQuery, connection))
                    {
                        checkCommand.Parameters.AddWithValue("@MaSanPham", rating.MaSanPham);
                        checkCommand.Parameters.AddWithValue("@MaTaiKhoan", rating.MaTaiKhoan);

                        var existingCount = (int)checkCommand.ExecuteScalar();
                        if (existingCount > 0)
                        {
                            return BadRequest(new { error = "Bạn đã đánh giá sản phẩm này rồi" });
                        }
                    }

                    // Thêm đánh giá mới
                    string insertQuery = @"INSERT INTO DanhGia (MaSanPham, MaTaiKhoan, NoiDung, SoSao)
                                         VALUES (@MaSanPham, @MaTaiKhoan, @NoiDung, @SoSao)";

                    using (var command = new SqlCommand(insertQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", rating.MaSanPham);
                        command.Parameters.AddWithValue("@MaTaiKhoan", rating.MaTaiKhoan);
                        command.Parameters.AddWithValue("@NoiDung", (object?)rating.NoiDung ?? DBNull.Value);
                        command.Parameters.AddWithValue("@SoSao", rating.SoSao);

                        int rowsAffected = command.ExecuteNonQuery();

                        if (rowsAffected > 0)
                        {
                            return Ok(new
                            {
                                message = "Thêm đánh giá thành công!",
                                rating = rating
                            });
                        }
                        else
                        {
                            return BadRequest(new { error = "Không thể thêm đánh giá" });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/ratings
        [HttpPut]
        public IActionResult UpdateRating([FromBody] Rating rating)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    string query = @"UPDATE DanhGia 
                                   SET NoiDung = @NoiDung, SoSao = @SoSao
                                   WHERE MaSanPham = @MaSanPham AND MaTaiKhoan = @MaTaiKhoan";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", rating.MaSanPham);
                        command.Parameters.AddWithValue("@MaTaiKhoan", rating.MaTaiKhoan);
                        command.Parameters.AddWithValue("@NoiDung", (object?)rating.NoiDung ?? DBNull.Value);
                        command.Parameters.AddWithValue("@SoSao", rating.SoSao);

                        int rowsAffected = command.ExecuteNonQuery();

                        if (rowsAffected > 0)
                        {
                            return Ok(new
                            {
                                message = "Cập nhật đánh giá thành công!",
                                rating = rating
                            });
                        }
                        else
                        {
                            return NotFound(new { error = "Không tìm thấy đánh giá để cập nhật" });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/ratings/{maSanPham}/{maTaiKhoan}
        [HttpDelete("{maSanPham}/{maTaiKhoan}")]
        public IActionResult DeleteRating(string maSanPham, string maTaiKhoan)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    string query = @"DELETE FROM DanhGia 
                                   WHERE MaSanPham = @MaSanPham AND MaTaiKhoan = @MaTaiKhoan";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", maSanPham);
                        command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);

                        int rowsAffected = command.ExecuteNonQuery();

                        if (rowsAffected > 0)
                        {
                            return Ok(new
                            {
                                message = "Xóa đánh giá thành công!",
                                maSanPham = maSanPham,
                                maTaiKhoan = maTaiKhoan
                            });
                        }
                        else
                        {
                            return NotFound(new { error = "Không tìm thấy đánh giá để xóa" });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/ratings/user/{maTaiKhoan}/{maSanPham}
        [HttpGet("user/{maTaiKhoan}/{maSanPham}")]
        public IActionResult GetUserRating(string maTaiKhoan, string maSanPham)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                Rating? rating = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT MaSanPham, MaTaiKhoan, NoiDung, SoSao 
                                   FROM DanhGia 
                                   WHERE MaSanPham = @MaSanPham AND MaTaiKhoan = @MaTaiKhoan";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", maSanPham);
                        command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                rating = new Rating
                                {
                                    MaSanPham = reader["MaSanPham"].ToString(),
                                    MaTaiKhoan = reader["MaTaiKhoan"].ToString(),
                                    NoiDung = reader["NoiDung"] as string,
                                    SoSao = Convert.ToInt32(reader["SoSao"])
                                };
                            }
                        }
                    }
                }

                if (rating != null)
                {
                    return Ok(rating);
                }
                else
                {
                    return NotFound(new { error = "Không tìm thấy đánh giá" });
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}