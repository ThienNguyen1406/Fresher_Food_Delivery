using FressFood.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace FressFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PayController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public PayController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // GET: api/Pay
        [HttpGet]
        public async Task<IActionResult> Get()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var pays = new List<Pay>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "SELECT Id_Pay, Pay_name FROM ThanhToan";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var pay = new Pay
                            {
                                Id_Pay = reader["Id_Pay"].ToString(),
                                Pay_name = reader["Pay_name"].ToString()
                            };
                            pays.Add(pay);
                        }
                    }
                }

                return Ok(pays);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Pay/Search?name=
        [HttpGet("Search")]
        public async Task<IActionResult> Search(string name)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var pays = new List<Pay>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = @"SELECT Id_Pay, Pay_name 
                             FROM ThanhToan 
                             WHERE Pay_name LIKE '%' + @Name + '%'";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Name", name ?? "");

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                var pay = new Pay
                                {
                                    Id_Pay = reader["Id_Pay"].ToString(),
                                    Pay_name = reader["Pay_name"].ToString()
                                };
                                pays.Add(pay);
                            }
                        }
                    }
                }

                return Ok(pays);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Pay/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                Pay pay = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "SELECT Id_Pay, Pay_name FROM ThanhToan WHERE Id_Pay = @Id_Pay";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_Pay", id);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                pay = new Pay
                                {
                                    Id_Pay = reader["Id_Pay"].ToString(),
                                    Pay_name = reader["Pay_name"].ToString()
                                };
                            }
                        }
                    }
                }

                if (pay == null)
                    return NotFound("Không tìm thấy phương thức thanh toán");

                return Ok(pay);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Pay
        [HttpPost]
        public async Task<IActionResult> Post([FromBody] Pay pay)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = @"INSERT INTO ThanhToan (Id_Pay, Pay_name) 
                            VALUES (@Id_Pay, @Pay_name)";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_Pay", pay.Id_Pay);
                        command.Parameters.AddWithValue("@Pay_name", pay.Pay_name);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok("Thêm phương thức thanh toán thành công");
                        else
                            return BadRequest("Thêm phương thức thanh toán thất bại");
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Pay/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> Put(string id, [FromBody] Pay pay)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = @"UPDATE ThanhToan 
                            SET Pay_name = @Pay_name
                            WHERE Id_Pay = @Id_Pay";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_Pay", id);
                        command.Parameters.AddWithValue("@Pay_name", pay.Pay_name);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok("Cập nhật phương thức thanh toán thành công");
                        else
                            return NotFound("Không tìm thấy phương thức thanh toán để cập nhật");
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Pay/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "DELETE FROM ThanhToan WHERE Id_Pay = @Id_Pay";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_Pay", id);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok("Xóa phương thức thanh toán thành công");
                        else
                            return NotFound("Không tìm thấy phương thức thanh toán để xóa");
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