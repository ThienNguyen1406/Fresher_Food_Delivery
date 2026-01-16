using FressFood.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace FressFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CouponController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public CouponController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // GET: api/Coupon
        [HttpGet]
        public async Task<IActionResult> Get()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var coupons = new List<Coupon>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "SELECT Id_phieugiamgia, Code, GiaTri, MoTa FROM PhieuGiamGia";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var coupon = new Coupon
                            {
                                Id_phieugiamgia = reader["Id_phieugiamgia"].ToString(),
                                Code = reader["Code"].ToString(),
                                GiaTri = Convert.ToDecimal(reader["GiaTri"]),
                                MoTa = reader["MoTa"]?.ToString()
                            };
                            coupons.Add(coupon);
                        }
                    }
                }

                return Ok(coupons);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Coupon/Search?code=
        [HttpGet("Search")]
        public async Task<IActionResult> Search(string code)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var coupons = new List<Coupon>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = @"SELECT Id_phieugiamgia, Code, GiaTri, MoTa 
                             FROM PhieuGiamGia 
                             WHERE Code LIKE '%' + @Code + '%'";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Code", code ?? "");

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                var coupon = new Coupon
                                {
                                    Id_phieugiamgia = reader["Id_phieugiamgia"].ToString(),
                                    Code = reader["Code"].ToString(),
                                    GiaTri = Convert.ToDecimal(reader["GiaTri"]),
                                    MoTa = reader["MoTa"]?.ToString()
                                };
                                coupons.Add(coupon);
                            }
                        }
                    }
                }

                return Ok(coupons);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Coupon/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                Coupon coupon = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "SELECT Id_phieugiamgia, Code, GiaTri, MoTa FROM PhieuGiamGia WHERE Id_phieugiamgia = @Id_phieugiamgia";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_phieugiamgia", id);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                coupon = new Coupon
                                {
                                    Id_phieugiamgia = reader["Id_phieugiamgia"].ToString(),
                                    Code = reader["Code"].ToString(),
                                    GiaTri = Convert.ToDecimal(reader["GiaTri"]),
                                    MoTa = reader["MoTa"]?.ToString()
                                };
                            }
                        }
                    }
                }

                if (coupon == null)
                    return NotFound("Không tìm thấy phiếu giảm giá");

                return Ok(coupon);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Coupon/Code/{code}
        [HttpGet("Code/{code}")]
        public async Task<IActionResult> GetByCode(string code)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                Coupon coupon = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "SELECT Id_phieugiamgia, Code, GiaTri, MoTa FROM PhieuGiamGia WHERE Code = @Code";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Code", code);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                coupon = new Coupon
                                {
                                    Id_phieugiamgia = reader["Id_phieugiamgia"].ToString(),
                                    Code = reader["Code"].ToString(),
                                    GiaTri = Convert.ToDecimal(reader["GiaTri"]),
                                    MoTa = reader["MoTa"]?.ToString()
                                };
                            }
                        }
                    }
                }

                if (coupon == null)
                    return NotFound("Không tìm thấy phiếu giảm giá với mã này");

                return Ok(coupon);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Coupon
        [HttpPost]
        public async Task<IActionResult> Post([FromBody] Coupon coupon)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = @"INSERT INTO PhieuGiamGia (Code, GiaTri, MoTa) 
                            VALUES (@Code, @GiaTri, @MoTa)";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Code", coupon.Code);
                        command.Parameters.AddWithValue("@GiaTri", coupon.GiaTri);
                        command.Parameters.AddWithValue("@MoTa", coupon.MoTa ?? (object)DBNull.Value);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok("Thêm phiếu giảm giá thành công");
                        else
                            return BadRequest("Thêm phiếu giảm giá thất bại");
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Coupon/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> Put(string id, [FromBody] Coupon coupon)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = @"UPDATE PhieuGiamGia 
                            SET Code = @Code,
                                GiaTri = @GiaTri,
                                MoTa = @MoTa
                            WHERE Id_phieugiamgia = @Id_phieugiamgia";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_phieugiamgia", id);
                        command.Parameters.AddWithValue("@Code", coupon.Code);
                        command.Parameters.AddWithValue("@GiaTri", coupon.GiaTri);
                        command.Parameters.AddWithValue("@MoTa", coupon.MoTa ?? (object)DBNull.Value);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok("Cập nhật phiếu giảm giá thành công");
                        else
                            return NotFound("Không tìm thấy phiếu giảm giá để cập nhật");
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Coupon/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "DELETE FROM PhieuGiamGia WHERE Id_phieugiamgia = @Id_phieugiamgia";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_phieugiamgia", id);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok("Xóa phiếu giảm giá thành công");
                        else
                            return NotFound("Không tìm thấy phiếu giảm giá để xóa");
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