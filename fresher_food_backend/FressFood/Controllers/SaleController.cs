using FressFood.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace FressFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SaleController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public SaleController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // GET: api/Sale - Lấy danh sách tất cả khuyến mãi
        [HttpGet]
        public IActionResult GetAllSales()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var sales = new List<Sale>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT Id_sale, GiaTriKhuyenMai, MoTaChuongTrinh, 
                                   NgayBatDau, NgayKetThuc, TrangThai, MaSanPham
                                   FROM KhuyenMai 
                                   ORDER BY NgayBatDau DESC";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var sale = new Sale
                            {
                                Id_sale = reader["Id_sale"].ToString() ?? "",
                                GiaTriKhuyenMai = Convert.ToDecimal(reader["GiaTriKhuyenMai"]),
                                MoTaChuongTrinh = reader["MoTaChuongTrinh"] as string,
                                NgayBatDau = Convert.ToDateTime(reader["NgayBatDau"]),
                                NgayKetThuc = Convert.ToDateTime(reader["NgayKetThuc"]),
                                TrangThai = reader["TrangThai"] as string,
                                MaSanPham = reader["MaSanPham"].ToString() ?? ""
                            };
                            sales.Add(sale);
                        }
                    }
                }
                return Ok(new
                {
                    success = true,
                    data = sales,
                    message = "Lấy danh sách khuyến mãi thành công"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message
                });
            }
        }


        // GET: api/Sale/{id} - Lấy khuyến mãi theo ID
        [HttpGet("{id}")]
        public IActionResult GetSaleById(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                Sale sale = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT Id_sale, GiaTriKhuyenMai, MoTaChuongTrinh, 
                                   NgayBatDau, NgayKetThuc, TrangThai, MaSanPham
                                   FROM KhuyenMai 
                                   WHERE Id_sale = @Id_sale";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_sale", id);

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                sale = new Sale
                                {
                                    Id_sale = reader["Id_sale"].ToString() ?? "",
                                    GiaTriKhuyenMai = Convert.ToDecimal(reader["GiaTriKhuyenMai"]),
                                    MoTaChuongTrinh = reader["MoTaChuongTrinh"] as string,
                                    NgayBatDau = Convert.ToDateTime(reader["NgayBatDau"]),
                                    NgayKetThuc = Convert.ToDateTime(reader["NgayKetThuc"]),
                                    TrangThai = reader["TrangThai"] as string,
                                    MaSanPham = reader["MaSanPham"].ToString() ?? ""
                                };
                            }
                        }
                    }
                }

                if (sale == null)
                    return NotFound(new
                    {
                        success = false,
                        error = "Không tìm thấy khuyến mãi"
                    });

                return Ok(new
                {
                    success = true,
                    data = sale,
                    message = "Lấy thông tin khuyến mãi thành công"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message
                });
            }
        }

        // POST: api/Sale - Thêm khuyến mãi mới
        [HttpPost]
        public IActionResult CreateSale([FromBody] Sale sale)
        {
            try
            {
                // Validation
                if (sale.NgayKetThuc <= sale.NgayBatDau)
                {
                    return BadRequest(new
                    {
                        success = false,
                        error = "Ngày kết thúc phải sau ngày bắt đầu"
                    });
                }

                if (sale.GiaTriKhuyenMai <= 0)
                {
                    return BadRequest(new
                    {
                        success = false,
                        error = "Giá trị khuyến mãi phải lớn hơn 0"
                    });
                }

                if (string.IsNullOrEmpty(sale.MaSanPham))
                {
                    return BadRequest(new
                    {
                        success = false,
                        error = "Mã sản phẩm không được để trống"
                    });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Sử dụng NEWID() để tạo ID mới
                    string query = @"INSERT INTO KhuyenMai (GiaTriKhuyenMai, MoTaChuongTrinh, 
                                   NgayBatDau, NgayKetThuc, TrangThai, MaSanPham) 
                                   OUTPUT INSERTED.id_sale
                                   VALUES ( @GiaTriKhuyenMai, @MoTaChuongTrinh, 
                                   @NgayBatDau, @NgayKetThuc, @TrangThai, @MaSanPham);
                                   ";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@GiaTriKhuyenMai", sale.GiaTriKhuyenMai);
                        command.Parameters.AddWithValue("@MoTaChuongTrinh", sale.MoTaChuongTrinh ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@NgayBatDau", sale.NgayBatDau);
                        command.Parameters.AddWithValue("@NgayKetThuc", sale.NgayKetThuc);
                        command.Parameters.AddWithValue("@TrangThai", sale.TrangThai ?? "Active");
                        command.Parameters.AddWithValue("@MaSanPham", sale.MaSanPham);

                        var newId = command.ExecuteScalar()?.ToString();
                        sale.Id_sale = newId;
                    }
                }

                return Ok(new
                {
                    success = true,
                    data = sale,
                    message = "Thêm khuyến mãi thành công"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message
                });
            }
        }

        // PUT: api/Sale/{id} - Cập nhật khuyến mãi
        [HttpPut("{id}")]
        public IActionResult UpdateSale(string id, [FromBody] Sale sale)
        {
            try
            {
                // Validation
                if (sale.NgayKetThuc <= sale.NgayBatDau)
                {
                    return BadRequest(new
                    {
                        success = false,
                        error = "Ngày kết thúc phải sau ngày bắt đầu"
                    });
                }

                if (sale.GiaTriKhuyenMai <= 0)
                {
                    return BadRequest(new
                    {
                        success = false,
                        error = "Giá trị khuyến mãi phải lớn hơn 0"
                    });
                }

                if (string.IsNullOrEmpty(sale.MaSanPham))
                {
                    return BadRequest(new
                    {
                        success = false,
                        error = "Mã sản phẩm không được để trống"
                    });
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"UPDATE KhuyenMai 
                                   SET GiaTriKhuyenMai = @GiaTriKhuyenMai,
                                       MoTaChuongTrinh = @MoTaChuongTrinh,
                                       NgayBatDau = @NgayBatDau,
                                       NgayKetThuc = @NgayKetThuc,
                                       TrangThai = @TrangThai,
                                       MaSanPham = @MaSanPham
                                   WHERE Id_sale = @Id_sale";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_sale", id);
                        command.Parameters.AddWithValue("@GiaTriKhuyenMai", sale.GiaTriKhuyenMai);
                        command.Parameters.AddWithValue("@MoTaChuongTrinh", sale.MoTaChuongTrinh ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@NgayBatDau", sale.NgayBatDau);
                        command.Parameters.AddWithValue("@NgayKetThuc", sale.NgayKetThuc);
                        command.Parameters.AddWithValue("@TrangThai", sale.TrangThai ?? "Active");
                        command.Parameters.AddWithValue("@MaSanPham", sale.MaSanPham);

                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return NotFound(new
                            {
                                success = false,
                                error = "Không tìm thấy khuyến mãi"
                            });
                        }
                    }
                }

                return Ok(new
                {
                    success = true,
                    message = "Cập nhật khuyến mãi thành công"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message
                });
            }
        }

        // DELETE: api/Sale/{id} - Xóa khuyến mãi
        [HttpDelete("{id}")]
        public IActionResult DeleteSale(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = "DELETE FROM KhuyenMai WHERE Id_sale = @Id_sale";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Id_sale", id);

                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return NotFound(new
                            {
                                success = false,
                                error = "Không tìm thấy khuyến mãi"
                            });
                        }
                    }
                }

                return Ok(new
                {
                    success = true,
                    message = "Xóa khuyến mãi thành công"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message
                });
            }
        }

        // GET: api/Sale/product/{maSanPham} - Lấy khuyến mãi theo sản phẩm
        [HttpGet("product/{maSanPham}")]
        public IActionResult GetSaleByProduct(string maSanPham)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var sales = new List<Sale>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT Id_sale, GiaTriKhuyenMai, MoTaChuongTrinh, 
                                   NgayBatDau, NgayKetThuc, TrangThai, MaSanPham
                                   FROM KhuyenMai 
                                   WHERE MaSanPham = @MaSanPham
                                   ORDER BY NgayBatDau DESC";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", maSanPham);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var sale = new Sale
                                {
                                    Id_sale = reader["Id_sale"].ToString() ?? "",
                                    GiaTriKhuyenMai = Convert.ToDecimal(reader["GiaTriKhuyenMai"]),
                                    MoTaChuongTrinh = reader["MoTaChuongTrinh"] as string,
                                    NgayBatDau = Convert.ToDateTime(reader["NgayBatDau"]),
                                    NgayKetThuc = Convert.ToDateTime(reader["NgayKetThuc"]),
                                    TrangThai = reader["TrangThai"] as string,
                                    MaSanPham = reader["MaSanPham"].ToString() ?? ""
                                };
                                sales.Add(sale);
                            }
                        }
                    }
                }

                return Ok(new
                {
                    success = true,
                    data = sales,
                    message = "Lấy danh sách khuyến mãi theo sản phẩm thành công"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    error = ex.Message
                });
            }
        }
    }
}