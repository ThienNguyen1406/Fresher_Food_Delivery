using FressFood.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace FressFood.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public ProductController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // GET: api/Products
        [HttpGet]
        public async Task<IActionResult> Get()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var products = new List<Product>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "SELECT MaSanPham, TenSanPham, MoTa, GiaBan, Anh, SoLuongTon, XuatXu, DonViTinh, MaDanhMuc FROM SanPham";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var fileName = reader["Anh"]?.ToString();
                            var product = new Product
                            {
                                MaSanPham = reader["MaSanPham"].ToString(),
                                TenSanPham = reader["TenSanPham"].ToString(),
                                MoTa = reader["MoTa"]?.ToString(),
                                XuatXu = reader["XuatXu"]?.ToString(),
                                DonViTinh = reader["DonViTinh"]?.ToString(),
                                GiaBan = Convert.ToDecimal(reader["GiaBan"]),
                                SoLuongTon = Convert.ToInt32(reader["SoLuongTon"]),
                                MaDanhMuc = reader["MaDanhMuc"].ToString(),
                                // Ghép thành URL để client load ảnh trực tiếp
                                Anh = string.IsNullOrEmpty(fileName) ? null :
                                      $"{Request.Scheme}://{Request.Host}/images/products/{fileName}"
                            };
                            products.Add(product);
                        }
                    }
                }

                return Ok(products);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Products/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetId(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                Product product = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "SELECT MaSanPham, TenSanPham, MoTa, GiaBan, Anh, SoLuongTon, XuatXu, DonViTinh, MaDanhMuc FROM SanPham WHERE MaSanPham = @MaSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        // Thêm parameter cho mã sản phẩm
                        command.Parameters.AddWithValue("@MaSanPham", id);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                var fileName = reader["Anh"]?.ToString();
                                product = new Product
                                {
                                    MaSanPham = reader["MaSanPham"].ToString(),
                                    TenSanPham = reader["TenSanPham"].ToString(),
                                    MoTa = reader["MoTa"]?.ToString(),
                                    XuatXu = reader["XuatXu"]?.ToString(),
                                    DonViTinh = reader["DonViTinh"]?.ToString(),
                                    GiaBan = Convert.ToDecimal(reader["GiaBan"]),
                                    SoLuongTon = Convert.ToInt32(reader["SoLuongTon"]),
                                    MaDanhMuc = reader["MaDanhMuc"].ToString(),
                                    // Ghép thành URL để client load ảnh trực tiếp
                                    Anh = string.IsNullOrEmpty(fileName) ? null :
                                          $"{Request.Scheme}://{Request.Host}/images/products/{fileName}"
                                };
                            }
                        }
                    }
                }

                // Kiểm tra nếu không tìm thấy sản phẩm
                if (product == null)
                {
                    return NotFound(new { error = "Không tìm thấy sản phẩm với mã: " + id });
                }

                return Ok(product);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Product/Search?name=
        [HttpGet("Search")]
        public async Task<IActionResult> Search(string name)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var products = new List<Product>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = @"SELECT MaSanPham, TenSanPham, MoTa, GiaBan, Anh, SoLuongTon, XuatXu, DonViTinh, MaDanhMuc 
                             FROM SanPham 
                             WHERE TenSanPham LIKE '%' + @Name + '%'";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Name", name ?? "");

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                var fileName = reader["Anh"]?.ToString();
                                var product = new Product
                                {
                                    MaSanPham = reader["MaSanPham"].ToString(),
                                    TenSanPham = reader["TenSanPham"].ToString(),
                                    MoTa = reader["MoTa"]?.ToString(),
                                    XuatXu = reader["XuatXu"]?.ToString(),
                                    DonViTinh = reader["DonViTinh"]?.ToString(),
                                    GiaBan = Convert.ToDecimal(reader["GiaBan"]),
                                    SoLuongTon = Convert.ToInt32(reader["SoLuongTon"]),
                                    MaDanhMuc = reader["MaDanhMuc"].ToString(),
                                    Anh = string.IsNullOrEmpty(fileName) ? null :
                                          $"{Request.Scheme}://{Request.Host}/images/products/{fileName}"
                                };
                                products.Add(product);
                            }
                        }
                    }
                }

                return Ok(products);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Product
        [HttpPost]
        public async Task<IActionResult> Post([FromForm] ProductCreateRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Xử lý upload ảnh nếu có
                    string anhFileName = null;
                    if (request.Anh != null && request.Anh.Length > 0)
                    {
                        anhFileName = await SaveProductImage(request.Anh);
                    }

                    // Câu lệnh INSERT kèm OUTPUT để lấy dữ liệu vừa thêm
                    string query = @"INSERT INTO SanPham 
                (TenSanPham, MoTa, GiaBan, Anh, SoLuongTon, XuatXu, DonViTinh, MaDanhMuc) 
                OUTPUT INSERTED.*
                VALUES (@TenSanPham, @MoTa, @GiaBan, @Anh, @SoLuongTon, @XuatXu, @DonViTinh, @MaDanhMuc)";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@TenSanPham", request.TenSanPham);
                        command.Parameters.AddWithValue("@MoTa", request.MoTa ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@GiaBan", request.GiaBan);
                        command.Parameters.AddWithValue("@Anh", anhFileName ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@SoLuongTon", request.SoLuongTon);
                        command.Parameters.AddWithValue("@XuatXu", request.XuatXu ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@DonViTinh", request.DonViTinh ?? (object)DBNull.Value);
                        command.Parameters.AddWithValue("@MaDanhMuc", request.MaDanhMuc);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                var newProduct = new Product
                                {
                                    MaSanPham = reader.GetString(reader.GetOrdinal("MaSanPham")),
                                    TenSanPham = reader.GetString(reader.GetOrdinal("TenSanPham")),
                                    MoTa = reader.IsDBNull(reader.GetOrdinal("MoTa")) ? null : reader.GetString(reader.GetOrdinal("MoTa")),
                                    GiaBan = reader.GetDecimal(reader.GetOrdinal("GiaBan")),
                                    Anh = reader.IsDBNull(reader.GetOrdinal("Anh")) ? null : reader.GetString(reader.GetOrdinal("Anh")),
                                    SoLuongTon = reader.GetInt32(reader.GetOrdinal("SoLuongTon")),
                                    XuatXu = reader.IsDBNull(reader.GetOrdinal("XuatXu")) ? null : reader.GetString(reader.GetOrdinal("XuatXu")),
                                    DonViTinh = reader.IsDBNull(reader.GetOrdinal("DonViTinh")) ? null : reader.GetString(reader.GetOrdinal("DonViTinh")),
                                    MaDanhMuc = reader.GetString(reader.GetOrdinal("MaDanhMuc"))
                                };

                                // Tạo URL đầy đủ nếu có ảnh
                                if (!string.IsNullOrEmpty(newProduct.Anh))
                                {
                                    newProduct.Anh = $"{Request.Scheme}://{Request.Host}/images/products/{newProduct.Anh}";
                                }

                                return Ok(new
                                {
                                    message = "Thêm sản phẩm thành công",
                                    product = newProduct
                                });
                            }
                            else
                            {
                                return BadRequest("Thêm sản phẩm thất bại");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Product/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> Put(string id, [FromForm] ProductUpdateRequest request)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();

                    // Xử lý upload ảnh nếu có file mới
                    string anhFileName = null;
                    if (request.Anh != null && request.Anh.Length > 0)
                    {
                        anhFileName = await SaveProductImage(request.Anh);
                    }

                    // Câu lệnh UPDATE
                    string updateQuery = @"UPDATE SanPham 
                             SET TenSanPham = @TenSanPham,
                                 MoTa = @MoTa,
                                 GiaBan = @GiaBan,
                                 SoLuongTon = @SoLuongTon,
                                 XuatXu = @XuatXu,
                                 DonViTinh = @DonViTinh,
                                 MaDanhMuc = @MaDanhMuc
                             {0}
                             WHERE MaSanPham = @MaSanPham";

                    // Nếu có ảnh mới, thêm cập nhật ảnh
                    if (!string.IsNullOrEmpty(anhFileName))
                    {
                        updateQuery = string.Format(updateQuery, ", Anh = @Anh");
                    }
                    else
                    {
                        updateQuery = string.Format(updateQuery, "");
                    }

                    using (var command = new SqlCommand(updateQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", id);
                        command.Parameters.AddWithValue("@TenSanPham", request.TenSanPham);
                        command.Parameters.AddWithValue("@MoTa", (object?)request.MoTa ?? DBNull.Value);
                        command.Parameters.AddWithValue("@GiaBan", request.GiaBan);
                        command.Parameters.AddWithValue("@SoLuongTon", request.SoLuongTon);
                        command.Parameters.AddWithValue("@XuatXu", (object?)request.XuatXu ?? DBNull.Value);
                        command.Parameters.AddWithValue("@DonViTinh", (object?)request.DonViTinh ?? DBNull.Value);
                        command.Parameters.AddWithValue("@MaDanhMuc", request.MaDanhMuc);

                        if (!string.IsNullOrEmpty(anhFileName))
                        {
                            command.Parameters.AddWithValue("@Anh", anhFileName);
                        }

                        int result = await command.ExecuteNonQueryAsync();

                        if (result == 0)
                            return NotFound(new { message = "Không tìm thấy sản phẩm để cập nhật" });
                    }

                    // Sau khi update, đọc lại sản phẩm vừa cập nhật
                    string selectQuery = "SELECT * FROM SanPham WHERE MaSanPham = @MaSanPham";
                    using (var selectCommand = new SqlCommand(selectQuery, connection))
                    {
                        selectCommand.Parameters.AddWithValue("@MaSanPham", id);

                        using (var reader = await selectCommand.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                var fileName = reader["Anh"]?.ToString();
                                var updatedProduct = new Product
                                {
                                    MaSanPham = reader["MaSanPham"].ToString(),
                                    TenSanPham = reader["TenSanPham"].ToString(),
                                    MoTa = reader["MoTa"] as string,
                                    GiaBan = reader.GetDecimal(reader.GetOrdinal("GiaBan")),
                                    Anh = string.IsNullOrEmpty(fileName) ? null : $"{Request.Scheme}://{Request.Host}/images/products/{fileName}",
                                    SoLuongTon = reader.GetInt32(reader.GetOrdinal("SoLuongTon")),
                                    XuatXu = reader["XuatXu"] as string,
                                    DonViTinh = reader["DonViTinh"] as string,
                                    MaDanhMuc = reader["MaDanhMuc"].ToString()
                                };

                                return Ok(new
                                {
                                    message = "Cập nhật sản phẩm thành công",
                                    product = updatedProduct
                                });
                            }
                        }
                    }
                }

                return NotFound(new { message = "Không tìm thấy sản phẩm sau khi cập nhật" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Product/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    string query = "DELETE FROM SanPham WHERE MaSanPham = @MaSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", id);

                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok("Xóa sản phẩm thành công");
                        else
                            return NotFound("Không tìm thấy sản phẩm để xóa");
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        private async Task<string> SaveProductImage(IFormFile file)
        {
            var folderPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "products");

            if (!Directory.Exists(folderPath))
            {
                Directory.CreateDirectory(folderPath);
            }

            var fileName = $"{DateTime.Now.Ticks}_{Path.GetFileName(file.FileName)}";
            var filePath = Path.Combine(folderPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            return fileName;
        }
    }

    // Model cho request tạo sản phẩm
    public class ProductCreateRequest
    {
        public string TenSanPham { get; set; }
        public string? MoTa { get; set; }
        public decimal GiaBan { get; set; }
        public IFormFile? Anh { get; set; }
        public int SoLuongTon { get; set; }
        public string? XuatXu { get; set; }
        public string? DonViTinh { get; set; }
        public string MaDanhMuc { get; set; }
    }

    // Model cho request cập nhật sản phẩm
    public class ProductUpdateRequest
    {
        public string TenSanPham { get; set; }
        public string? MoTa { get; set; }
        public decimal GiaBan { get; set; }
        public IFormFile? Anh { get; set; }
        public int SoLuongTon { get; set; }
        public string? XuatXu { get; set; }
        public string? DonViTinh { get; set; }
        public string MaDanhMuc { get; set; }
    }
}