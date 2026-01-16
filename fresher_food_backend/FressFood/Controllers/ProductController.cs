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
                    // Chỉ lấy sản phẩm chưa bị xóa (soft delete)
                    string query = @"SELECT MaSanPham, TenSanPham, MoTa, GiaBan, Anh, SoLuongTon, XuatXu, DonViTinh, MaDanhMuc, NgaySanXuat, NgayHetHan 
                                     FROM SanPham 
                                     WHERE (IsDeleted = 0 OR IsDeleted IS NULL)";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        var tempProducts = new List<(string MaSanPham, string TenSanPham, string? MoTa, string? XuatXu, string DonViTinh, decimal GiaBan, int SoLuongTon, string MaDanhMuc, DateTime? NgaySanXuat, DateTime? NgayHetHan, string? Anh)>();
                        
                        while (await reader.ReadAsync())
                        {
                            var fileName = reader["Anh"]?.ToString();
                            tempProducts.Add((
                                MaSanPham: reader["MaSanPham"].ToString(),
                                TenSanPham: reader["TenSanPham"].ToString(),
                                MoTa: reader["MoTa"]?.ToString(),
                                XuatXu: reader["XuatXu"]?.ToString(),
                                DonViTinh: reader["DonViTinh"].ToString(),
                                GiaBan: Convert.ToDecimal(reader["GiaBan"]),
                                SoLuongTon: Convert.ToInt32(reader["SoLuongTon"]),
                                MaDanhMuc: reader["MaDanhMuc"].ToString(),
                                NgaySanXuat: reader.IsDBNull(reader.GetOrdinal("NgaySanXuat")) 
                                    ? (DateTime?)null 
                                    : reader.GetDateTime(reader.GetOrdinal("NgaySanXuat")),
                                NgayHetHan: reader.IsDBNull(reader.GetOrdinal("NgayHetHan")) 
                                    ? (DateTime?)null 
                                    : reader.GetDateTime(reader.GetOrdinal("NgayHetHan")),
                                Anh: fileName
                            ));
                        }
                        
                        // Sau khi đóng reader, tính giá thực tế cho từng sản phẩm
                        foreach (var item in tempProducts)
                        {
                            var giaThucTe = TinhGiaThucTe(item.MaSanPham, item.GiaBan, item.NgayHetHan, connection);
                            var anhUrl = string.IsNullOrEmpty(item.Anh) ? null :
                                        $"{Request.Scheme}://{Request.Host}/images/products/{item.Anh}";
                            
                            var product = new Product
                            {
                                MaSanPham = item.MaSanPham,
                                TenSanPham = item.TenSanPham,
                                MoTa = item.MoTa,
                                XuatXu = item.XuatXu,
                                DonViTinh = item.DonViTinh,
                                GiaBan = giaThucTe, // Trả về giá thực tế (đã giảm giá)
                                SoLuongTon = item.SoLuongTon,
                                MaDanhMuc = item.MaDanhMuc,
                                NgaySanXuat = item.NgaySanXuat,
                                NgayHetHan = item.NgayHetHan,
                                Anh = anhUrl
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
                    string query = @"SELECT MaSanPham, TenSanPham, MoTa, GiaBan, Anh, SoLuongTon, XuatXu, DonViTinh, MaDanhMuc, NgaySanXuat, NgayHetHan 
                                     FROM SanPham 
                                     WHERE MaSanPham = @MaSanPham AND (IsDeleted = 0 OR IsDeleted IS NULL)";

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
                                    NgaySanXuat = reader.IsDBNull(reader.GetOrdinal("NgaySanXuat")) 
                                        ? null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgaySanXuat")),
                                    NgayHetHan = reader.IsDBNull(reader.GetOrdinal("NgayHetHan")) 
                                        ? null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgayHetHan")),
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
                    string query = @"SELECT MaSanPham, TenSanPham, MoTa, GiaBan, Anh, SoLuongTon, XuatXu, DonViTinh, MaDanhMuc, NgaySanXuat, NgayHetHan 
                             FROM SanPham 
                             WHERE TenSanPham LIKE '%' + @Name + '%' AND (IsDeleted = 0 OR IsDeleted IS NULL)";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Name", name ?? "");

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            var tempProducts = new List<(string MaSanPham, string TenSanPham, string? MoTa, string? XuatXu, string DonViTinh, decimal GiaBan, int SoLuongTon, string MaDanhMuc, DateTime? NgaySanXuat, DateTime? NgayHetHan, string? Anh)>();
                            
                            while (await reader.ReadAsync())
                            {
                                var fileName = reader["Anh"]?.ToString();
                                tempProducts.Add((
                                    MaSanPham: reader["MaSanPham"].ToString(),
                                    TenSanPham: reader["TenSanPham"].ToString(),
                                    MoTa: reader["MoTa"]?.ToString(),
                                    XuatXu: reader["XuatXu"]?.ToString(),
                                    DonViTinh: reader["DonViTinh"].ToString(),
                                    GiaBan: Convert.ToDecimal(reader["GiaBan"]),
                                    SoLuongTon: Convert.ToInt32(reader["SoLuongTon"]),
                                    MaDanhMuc: reader["MaDanhMuc"].ToString(),
                                    NgaySanXuat: reader.IsDBNull(reader.GetOrdinal("NgaySanXuat")) 
                                        ? (DateTime?)null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgaySanXuat")),
                                    NgayHetHan: reader.IsDBNull(reader.GetOrdinal("NgayHetHan")) 
                                        ? (DateTime?)null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgayHetHan")),
                                    Anh: fileName
                                ));
                            }
                            
                            // Sau khi đóng reader, tính giá thực tế cho từng sản phẩm
                            foreach (var item in tempProducts)
                            {
                                var giaThucTe = TinhGiaThucTe(item.MaSanPham, item.GiaBan, item.NgayHetHan, connection);
                                var anhUrl = string.IsNullOrEmpty(item.Anh) ? null :
                                            $"{Request.Scheme}://{Request.Host}/images/products/{item.Anh}";
                                
                                var product = new Product
                                {
                                    MaSanPham = item.MaSanPham,
                                    TenSanPham = item.TenSanPham,
                                    MoTa = item.MoTa,
                                    XuatXu = item.XuatXu,
                                    DonViTinh = item.DonViTinh,
                                    GiaBan = giaThucTe, // Trả về giá thực tế (đã giảm giá)
                                    SoLuongTon = item.SoLuongTon,
                                    MaDanhMuc = item.MaDanhMuc,
                                    NgaySanXuat = item.NgaySanXuat,
                                    NgayHetHan = item.NgayHetHan,
                                    Anh = anhUrl
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
                (TenSanPham, MoTa, GiaBan, Anh, SoLuongTon, XuatXu, DonViTinh, MaDanhMuc, NgaySanXuat, NgayHetHan) 
                OUTPUT INSERTED.*
                VALUES (@TenSanPham, @MoTa, @GiaBan, @Anh, @SoLuongTon, @XuatXu, @DonViTinh, @MaDanhMuc, @NgaySanXuat, @NgayHetHan)";

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
                        command.Parameters.AddWithValue("@NgaySanXuat", request.NgaySanXuat.HasValue 
                            ? (object)request.NgaySanXuat.Value 
                            : DBNull.Value);
                        command.Parameters.AddWithValue("@NgayHetHan", request.NgayHetHan.HasValue 
                            ? (object)request.NgayHetHan.Value 
                            : DBNull.Value);

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
                                    MaDanhMuc = reader.GetString(reader.GetOrdinal("MaDanhMuc")),
                                    NgaySanXuat = reader.IsDBNull(reader.GetOrdinal("NgaySanXuat")) 
                                        ? null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgaySanXuat")),
                                    NgayHetHan = reader.IsDBNull(reader.GetOrdinal("NgayHetHan")) 
                                        ? null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgayHetHan"))
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
                                 MaDanhMuc = @MaDanhMuc,
                                 NgaySanXuat = @NgaySanXuat,
                                 NgayHetHan = @NgayHetHan
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
                        command.Parameters.AddWithValue("@NgaySanXuat", request.NgaySanXuat.HasValue 
                            ? (object)request.NgaySanXuat.Value 
                            : DBNull.Value);
                        command.Parameters.AddWithValue("@NgayHetHan", request.NgayHetHan.HasValue 
                            ? (object)request.NgayHetHan.Value 
                            : DBNull.Value);

                        if (!string.IsNullOrEmpty(anhFileName))
                        {
                            command.Parameters.AddWithValue("@Anh", anhFileName);
                        }

                        int result = await command.ExecuteNonQueryAsync();

                        if (result == 0)
                            return NotFound(new { message = "Không tìm thấy sản phẩm để cập nhật" });
                    }

                    // Sau khi update, đọc lại sản phẩm vừa cập nhật
                    string selectQuery = "SELECT * FROM SanPham WHERE MaSanPham = @MaSanPham AND (IsDeleted = 0 OR IsDeleted IS NULL)";
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
                                    MaDanhMuc = reader["MaDanhMuc"].ToString(),
                                    NgaySanXuat = reader.IsDBNull(reader.GetOrdinal("NgaySanXuat")) 
                                        ? null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgaySanXuat")),
                                    NgayHetHan = reader.IsDBNull(reader.GetOrdinal("NgayHetHan")) 
                                        ? null 
                                        : reader.GetDateTime(reader.GetOrdinal("NgayHetHan"))
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

        // DELETE: api/Product/{id} - Soft delete (đẩy vào thùng rác)
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    
                    // Kiểm tra xem sản phẩm có tồn tại và chưa bị xóa không
                    string checkProductQuery = @"SELECT COUNT(*) FROM SanPham 
                                                 WHERE MaSanPham = @MaSanPham AND (IsDeleted = 0 OR IsDeleted IS NULL)";
                    using (var checkCommand = new SqlCommand(checkProductQuery, connection))
                    {
                        checkCommand.Parameters.AddWithValue("@MaSanPham", id);
                        var productCount = (int)await checkCommand.ExecuteScalarAsync();
                        
                        if (productCount == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy sản phẩm để xóa" });
                        }
                    }
                    
                    // Soft delete: đánh dấu là đã xóa và lưu thời gian xóa
                    string query = @"UPDATE SanPham 
                                     SET IsDeleted = 1, DeletedAt = GETDATE() 
                                     WHERE MaSanPham = @MaSanPham";
                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", id);
                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok(new { message = "Đã chuyển sản phẩm vào thùng rác" });
                        else
                            return NotFound(new { error = "Không tìm thấy sản phẩm để xóa" });
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Product/Trash - Lấy danh sách sản phẩm trong thùng rác
        [HttpGet("Trash")]
        public async Task<IActionResult> GetTrash()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var products = new List<object>();

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    
                    // Tự động xóa vĩnh viễn các sản phẩm đã xóa hơn 30 ngày
                    string autoDeleteQuery = @"DELETE FROM SanPham 
                                               WHERE IsDeleted = 1 
                                               AND DeletedAt IS NOT NULL 
                                               AND DATEDIFF(day, DeletedAt, GETDATE()) >= 30";
                    using (var autoDeleteCommand = new SqlCommand(autoDeleteQuery, connection))
                    {
                        var deletedCount = await autoDeleteCommand.ExecuteNonQueryAsync();
                        if (deletedCount > 0)
                        {
                            Console.WriteLine($"Đã tự động xóa vĩnh viễn {deletedCount} sản phẩm trong thùng rác (> 30 ngày)");
                        }
                    }
                    
                    // Lấy danh sách sản phẩm trong thùng rác (chưa quá 30 ngày)
                    string query = @"SELECT MaSanPham, TenSanPham, MoTa, GiaBan, Anh, SoLuongTon, XuatXu, DonViTinh, MaDanhMuc, NgaySanXuat, NgayHetHan, DeletedAt,
                                     DATEDIFF(day, DeletedAt, GETDATE()) as DaysInTrash
                                     FROM SanPham 
                                     WHERE IsDeleted = 1 AND DeletedAt IS NOT NULL
                                     ORDER BY DeletedAt DESC";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            var fileName = reader["Anh"]?.ToString();
                            DateTime? deletedAt = null;
                            if (!reader.IsDBNull(reader.GetOrdinal("DeletedAt")))
                            {
                                deletedAt = reader.GetDateTime(reader.GetOrdinal("DeletedAt"));
                            }
                            var daysInTrash = reader.IsDBNull(reader.GetOrdinal("DaysInTrash")) 
                                ? 0 
                                : reader.GetInt32(reader.GetOrdinal("DaysInTrash"));
                            
                            var product = new
                            {
                                MaSanPham = reader["MaSanPham"].ToString(),
                                TenSanPham = reader["TenSanPham"].ToString(),
                                MoTa = reader["MoTa"]?.ToString(),
                                XuatXu = reader["XuatXu"]?.ToString(),
                                DonViTinh = reader["DonViTinh"]?.ToString(),
                                GiaBan = Convert.ToDecimal(reader["GiaBan"]),
                                SoLuongTon = Convert.ToInt32(reader["SoLuongTon"]),
                                MaDanhMuc = reader["MaDanhMuc"].ToString(),
                                NgaySanXuat = reader.IsDBNull(reader.GetOrdinal("NgaySanXuat")) 
                                    ? (DateTime?)null 
                                    : reader.GetDateTime(reader.GetOrdinal("NgaySanXuat")),
                                NgayHetHan = reader.IsDBNull(reader.GetOrdinal("NgayHetHan")) 
                                    ? (DateTime?)null 
                                    : reader.GetDateTime(reader.GetOrdinal("NgayHetHan")),
                                Anh = string.IsNullOrEmpty(fileName) ? null :
                                      $"{Request.Scheme}://{Request.Host}/images/products/{fileName}",
                                DeletedAt = deletedAt,
                                DaysInTrash = daysInTrash,
                                DaysUntilPermanentDelete = 30 - daysInTrash
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

        // POST: api/Product/{id}/Restore - Khôi phục sản phẩm từ thùng rác
        [HttpPost("{id}/Restore")]
        public async Task<IActionResult> Restore(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    
                    // Khôi phục sản phẩm: xóa đánh dấu IsDeleted
                    string query = @"UPDATE SanPham 
                                     SET IsDeleted = 0, DeletedAt = NULL 
                                     WHERE MaSanPham = @MaSanPham AND IsDeleted = 1";
                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", id);
                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok(new { message = "Khôi phục sản phẩm thành công" });
                        else
                            return NotFound(new { error = "Không tìm thấy sản phẩm trong thùng rác để khôi phục" });
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Product/{id}/Permanent - Xóa vĩnh viễn sản phẩm từ thùng rác
        [HttpDelete("{id}/Permanent")]
        public async Task<IActionResult> PermanentDelete(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    await connection.OpenAsync();
                    
                    // Kiểm tra xem sản phẩm có trong thùng rác không
                    string checkQuery = @"SELECT COUNT(*) FROM SanPham 
                                         WHERE MaSanPham = @MaSanPham AND IsDeleted = 1";
                    using (var checkCommand = new SqlCommand(checkQuery, connection))
                    {
                        checkCommand.Parameters.AddWithValue("@MaSanPham", id);
                        var count = (int)await checkCommand.ExecuteScalarAsync();
                        
                        if (count == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy sản phẩm trong thùng rác để xóa vĩnh viễn" });
                        }
                    }
                    
                    // Xóa vĩnh viễn sản phẩm
                    string query = "DELETE FROM SanPham WHERE MaSanPham = @MaSanPham AND IsDeleted = 1";
                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaSanPham", id);
                        int result = await command.ExecuteNonQueryAsync();

                        if (result > 0)
                            return Ok(new { message = "Đã xóa vĩnh viễn sản phẩm" });
                        else
                            return NotFound(new { error = "Không tìm thấy sản phẩm trong thùng rác để xóa vĩnh viễn" });
                    }
                }
            }
            catch (Microsoft.Data.SqlClient.SqlException sqlEx)
            {
                // Xử lý lỗi foreign key constraint
                if (sqlEx.Number == 547) // Foreign key constraint violation
                {
                    return BadRequest(new { error = "Không thể xóa vĩnh viễn sản phẩm vì đang được sử dụng trong hệ thống (đơn hàng, giỏ hàng, đánh giá, v.v.)" });
                }
                return StatusCode(500, new { error = $"Lỗi database: {sqlEx.Message}" });
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

        /// <summary>
        /// Tính giá thực tế của sản phẩm (có Sale và giảm giá hết hạn)
        /// </summary>
        private decimal TinhGiaThucTe(string maSanPham, decimal giaBan, DateTime? ngayHetHan, SqlConnection connection)
        {
            decimal giaThucTe = giaBan;
            decimal giamGiaHetHan = 0;
            bool coGiamGiaHetHan = false;
            
            // Kiểm tra giảm giá hết hạn (30% nếu còn ≤ 7 ngày)
            if (ngayHetHan.HasValue)
            {
                var now = DateTime.Now;
                var daysUntilExpiry = (ngayHetHan.Value.Date - now.Date).Days;
                if (daysUntilExpiry >= 0 && daysUntilExpiry <= 7)
                {
                    giamGiaHetHan = giaBan * 0.3m;
                    coGiamGiaHetHan = true;
                }
            }
            
            // Kiểm tra Sale (khuyến mãi) - ưu tiên Sale hơn giảm giá hết hạn
            decimal? giaTriKhuyenMai = null;
            string? loaiGiaTri = null;
            try
            {
                string saleQuery = @"
                    SELECT TOP 1 GiaTriKhuyenMai, ISNULL(LoaiGiaTri, 'Amount') as LoaiGiaTri
                    FROM KhuyenMai
                    WHERE (MaSanPham = @MaSanPham OR MaSanPham = 'ALL')
                      AND TrangThai = 'Active'
                      AND NgayBatDau <= GETDATE()
                      AND NgayKetThuc >= GETDATE()
                    ORDER BY CASE WHEN MaSanPham = @MaSanPham THEN 0 ELSE 1 END";
                
                using (var saleCommand = new SqlCommand(saleQuery, connection))
                {
                    saleCommand.Parameters.AddWithValue("@MaSanPham", maSanPham);
                    
                    using (var saleReader = saleCommand.ExecuteReader())
                    {
                        if (saleReader.Read())
                        {
                            giaTriKhuyenMai = Convert.ToDecimal(saleReader["GiaTriKhuyenMai"]);
                            loaiGiaTri = saleReader["LoaiGiaTri"]?.ToString() ?? "Amount";
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                // Log lỗi nhưng vẫn tiếp tục
                Console.WriteLine($"[Product Price] Error getting sale for {maSanPham}: {ex.Message}");
            }
            
            // Áp dụng giảm giá: Ưu tiên Sale, sau đó mới đến giảm giá hết hạn
            if (giaTriKhuyenMai.HasValue && giaTriKhuyenMai.Value > 0)
            {
                // Có Sale -> tính giá theo loại (Amount hoặc Percent)
                if (loaiGiaTri == "Percent")
                {
                    // Giảm giá theo phần trăm: GiaThucTe = GiaBan * (1 - GiaTriKhuyenMai / 100)
                    // Ví dụ: GiaTriKhuyenMai = 30 -> giảm 30%
                    decimal phanTramGiam = giaTriKhuyenMai.Value / 100m;
                    decimal soTienGiam = giaBan * phanTramGiam;
                    giaThucTe = Math.Max(0, giaBan - soTienGiam);
                }
                else
                {
                    // Giảm giá theo số tiền: GiaThucTe = GiaBan - GiaTriKhuyenMai
                    giaThucTe = Math.Max(0, giaBan - giaTriKhuyenMai.Value);
                }
            }
            else if (coGiamGiaHetHan && giamGiaHetHan > 0)
            {
                // Không có Sale -> dùng giảm giá hết hạn
                giaThucTe = Math.Max(0, giaBan - giamGiaHetHan);
            }
            
            return Math.Max(0, giaThucTe);
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
        public DateTime? NgaySanXuat { get; set; } // Ngày sản xuất
        public DateTime? NgayHetHan { get; set; } // Ngày hết hạn
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
        public DateTime? NgaySanXuat { get; set; } // Ngày sản xuất
        public DateTime? NgayHetHan { get; set; } // Ngày hết hạn
    }
}