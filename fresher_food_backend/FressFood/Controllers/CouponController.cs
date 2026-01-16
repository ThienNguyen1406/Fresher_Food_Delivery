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

        // GET: api/Coupon?maTaiKhoan=xxx
        [HttpGet]
        public async Task<IActionResult> Get([FromQuery] string? maTaiKhoan = null)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var coupons = new List<Coupon>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    
                    // Nếu có maTaiKhoan, lọc ra những voucher user chưa sử dụng
                    string query;
                    if (!string.IsNullOrEmpty(maTaiKhoan))
                    {
                        query = @"SELECT p.Id_phieugiamgia, p.Code, p.GiaTri, p.MoTa, 
                                         ISNULL(p.LoaiGiaTri, 'Amount') as LoaiGiaTri, 
                                         p.SoLuongToiDa, 
                                         ISNULL(p.SoLuongDaSuDung, 0) as SoLuongDaSuDung
                                  FROM PhieuGiamGia p
                                  WHERE (p.SoLuongToiDa IS NULL OR ISNULL(p.SoLuongDaSuDung, 0) < p.SoLuongToiDa)
                                    AND NOT EXISTS (
                                        SELECT 1 FROM LichSuSuDungVoucher l
                                        WHERE l.MaTaiKhoan = @MaTaiKhoan 
                                          AND l.Id_phieugiamgia = p.Id_phieugiamgia
                                    )";
                    }
                    else
                    {
                        // Admin xem tất cả voucher
                        query = "SELECT Id_phieugiamgia, Code, GiaTri, MoTa, ISNULL(LoaiGiaTri, 'Amount') as LoaiGiaTri, SoLuongToiDa, ISNULL(SoLuongDaSuDung, 0) as SoLuongDaSuDung FROM PhieuGiamGia";
                    }

                    using (var command = new SqlCommand(query, connection))
                    {
                        if (!string.IsNullOrEmpty(maTaiKhoan))
                        {
                            // Convert MaTaiKhoan sang INT nếu cần
                            if (int.TryParse(maTaiKhoan, out int maTaiKhoanInt))
                            {
                                command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoanInt);
                            }
                            else
                            {
                                command.Parameters.AddWithValue("@MaTaiKhoan", maTaiKhoan);
                            }
                        }

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                var coupon = new Coupon
                                {
                                    Id_phieugiamgia = reader["Id_phieugiamgia"].ToString(),
                                    Code = reader["Code"].ToString(),
                                    GiaTri = Convert.ToDecimal(reader["GiaTri"]),
                                    MoTa = reader["MoTa"]?.ToString(),
                                    LoaiGiaTri = reader["LoaiGiaTri"]?.ToString() ?? "Amount",
                                    SoLuongToiDa = reader["SoLuongToiDa"] != DBNull.Value ? (int?)Convert.ToInt32(reader["SoLuongToiDa"]) : null,
                                    SoLuongDaSuDung = reader["SoLuongDaSuDung"] != DBNull.Value ? Convert.ToInt32(reader["SoLuongDaSuDung"]) : 0
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
                    string query = @"SELECT Id_phieugiamgia, Code, GiaTri, MoTa, ISNULL(LoaiGiaTri, 'Amount') as LoaiGiaTri, SoLuongToiDa, ISNULL(SoLuongDaSuDung, 0) as SoLuongDaSuDung 
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
                                    MoTa = reader["MoTa"]?.ToString(),
                                    LoaiGiaTri = reader["LoaiGiaTri"]?.ToString() ?? "Amount",
                                    SoLuongToiDa = reader["SoLuongToiDa"] != DBNull.Value ? (int?)Convert.ToInt32(reader["SoLuongToiDa"]) : null,
                                    SoLuongDaSuDung = reader["SoLuongDaSuDung"] != DBNull.Value ? Convert.ToInt32(reader["SoLuongDaSuDung"]) : 0
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
                    string query = "SELECT Id_phieugiamgia, Code, GiaTri, MoTa, ISNULL(LoaiGiaTri, 'Amount') as LoaiGiaTri, SoLuongToiDa, ISNULL(SoLuongDaSuDung, 0) as SoLuongDaSuDung FROM PhieuGiamGia WHERE Id_phieugiamgia = @Id_phieugiamgia";

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
                    string query = "SELECT Id_phieugiamgia, Code, GiaTri, MoTa, ISNULL(LoaiGiaTri, 'Amount') as LoaiGiaTri, SoLuongToiDa, ISNULL(SoLuongDaSuDung, 0) as SoLuongDaSuDung FROM PhieuGiamGia WHERE Code = @Code";

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
                                    MoTa = reader["MoTa"]?.ToString(),
                                    LoaiGiaTri = reader["LoaiGiaTri"]?.ToString() ?? "Amount",
                                    SoLuongToiDa = reader["SoLuongToiDa"] != DBNull.Value ? (int?)Convert.ToInt32(reader["SoLuongToiDa"]) : null,
                                    SoLuongDaSuDung = reader["SoLuongDaSuDung"] != DBNull.Value ? Convert.ToInt32(reader["SoLuongDaSuDung"]) : 0
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
                    string query = @"INSERT INTO PhieuGiamGia (Code, GiaTri, MoTa, LoaiGiaTri, SoLuongToiDa, SoLuongDaSuDung) 
                            VALUES (@Code, @GiaTri, @MoTa, @LoaiGiaTri, @SoLuongToiDa, @SoLuongDaSuDung)";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Code", coupon.Code);
                        command.Parameters.AddWithValue("@GiaTri", coupon.GiaTri);
                        command.Parameters.AddWithValue("@MoTa", coupon.MoTa ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@LoaiGiaTri", coupon.LoaiGiaTri ?? "Amount");
                        command.Parameters.AddWithValue("@SoLuongToiDa", coupon.SoLuongToiDa.HasValue ? (object)coupon.SoLuongToiDa.Value : DBNull.Value);
                        command.Parameters.AddWithValue("@SoLuongDaSuDung", coupon.SoLuongDaSuDung);

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
                                MoTa = @MoTa,
                                LoaiGiaTri = @LoaiGiaTri,
                                SoLuongToiDa = @SoLuongToiDa,
                                SoLuongDaSuDung = @SoLuongDaSuDung
                            WHERE Id_phieugiamgia = @Id_phieugiamgia";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_phieugiamgia", id);
                        command.Parameters.AddWithValue("@Code", coupon.Code);
                        command.Parameters.AddWithValue("@GiaTri", coupon.GiaTri);
                        command.Parameters.AddWithValue("@MoTa", coupon.MoTa ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@LoaiGiaTri", coupon.LoaiGiaTri ?? "Amount");
                        command.Parameters.AddWithValue("@SoLuongToiDa", coupon.SoLuongToiDa.HasValue ? (object)coupon.SoLuongToiDa.Value : DBNull.Value);
                        command.Parameters.AddWithValue("@SoLuongDaSuDung", coupon.SoLuongDaSuDung);

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