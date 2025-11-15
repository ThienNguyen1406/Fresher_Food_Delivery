using FressFood.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace FoodShop.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoryController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _environment;

        public CategoryController(IConfiguration configuration, IWebHostEnvironment environment)
        {
            _configuration = configuration;
            _environment = environment;
        }

        // GET: api/Category/{categoryId}/products
        [HttpGet("{categoryId}/products")]
        public IActionResult GetProductsByCategory(string categoryId)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var products = new List<Product>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"
                SELECT 
                    sp.MaSanPham,
                    sp.TenSanPham,
                    sp.MoTa,
                    sp.GiaBan,
                    sp.SoLuongTon,
                    sp.DonViTinh,
                    sp.XuatXu,
                    sp.Anh,
                    sp.MaDanhMuc
                FROM SanPham sp
                INNER JOIN DanhMuc dm ON sp.MaDanhMuc = dm.MaDanhMuc
                WHERE sp.MaDanhMuc = @MaDanhMuc
                ORDER BY sp.TenSanPham";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaDanhMuc", categoryId);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var imagePath = reader["Anh"] as string;

                                // XỬ LÝ ẢNH: Nếu ảnh rỗng hoặc null, gán giá trị mặc định
                                string fullImageUrl;
                                if (string.IsNullOrEmpty(imagePath))
                                {
                                    fullImageUrl = "https://picsum.photos/200"; // Ảnh mặc định
                                }
                                else
                                {
                                    fullImageUrl = GetFullImageUrl(imagePath);
                                }

                                var product = new Product
                                {
                                    MaSanPham = reader["MaSanPham"].ToString(),
                                    TenSanPham = reader["TenSanPham"].ToString() ?? "",
                                    MoTa = reader["MoTa"] as string ?? "",
                                    GiaBan = reader["GiaBan"] != DBNull.Value ? Convert.ToDecimal(reader["GiaBan"]) : 0,
                                    SoLuongTon = reader["SoLuongTon"] != DBNull.Value ? Convert.ToInt32(reader["SoLuongTon"]) : 0,
                                    DonViTinh = reader["DonViTinh"] as string ?? "",
                                    XuatXu = reader["XuatXu"] as string ?? "",
                                    Anh = fullImageUrl, // SỬ DỤNG URL ĐÃ XỬ LÝ
                                    MaDanhMuc = reader["MaDanhMuc"].ToString(),
                                };
                                products.Add(product);
                            }
                        }
                    }
                }

                Console.WriteLine($"Found {products.Count} products for category {categoryId}");

                // Trả về danh sách sản phẩm với định dạng JSON có dấu ngoặc vuông
                return Ok(products);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error in GetProductsByCategory: {ex.Message}");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Category
        [HttpGet]
        public IActionResult Get()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var categories = new List<Category>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = "SELECT MaDanhMuc, TenDanhMuc, Icon FROM DanhMuc";

                    using (var command = new SqlCommand(query, connection))
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var iconPath = reader["Icon"] as string;
                            var category = new Category
                            {
                                MaDanhMuc = reader["MaDanhMuc"].ToString(),
                                TenDanhMuc = reader["TenDanhMuc"].ToString() ?? "",
                                Icon = !string.IsNullOrEmpty(iconPath) ? GetFullImageUrl(iconPath) : null
                            };
                            categories.Add(category);
                        }
                    }
                }
                return Ok(categories);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Category/{id}
        [HttpGet("{id}")]
        public IActionResult GetById(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                Category category = null;

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = "SELECT MaDanhMuc, TenDanhMuc, Icon FROM DanhMuc WHERE MaDanhMuc = @MaDanhMuc";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaDanhMuc", id);

                        using (var reader = command.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                var iconPath = reader["Icon"] as string;
                                category = new Category
                                {
                                    MaDanhMuc = reader["MaDanhMuc"].ToString() ?? "",
                                    TenDanhMuc = reader["TenDanhMuc"].ToString() ?? "",
                                    Icon = !string.IsNullOrEmpty(iconPath) ? GetFullImageUrl(iconPath) : null
                                };
                            }
                        }
                    }
                }

                if (category == null)
                    return NotFound(new { error = "Không tìm thấy danh mục" });

                return Ok(category);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Category/search/{name}
        [HttpGet("search/{name}")]
        public IActionResult SearchByName(string name)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var categories = new List<Category>();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"SELECT MaDanhMuc, TenDanhMuc, Icon 
                                   FROM DanhMuc 
                                   WHERE TenDanhMuc LIKE '%' + @Name + '%'";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@Name", name);

                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var iconPath = reader["Icon"] as string;
                                var category = new Category
                                {
                                    MaDanhMuc = reader["MaDanhMuc"].ToString(),
                                    TenDanhMuc = reader["TenDanhMuc"].ToString() ?? "",
                                    Icon = !string.IsNullOrEmpty(iconPath) ? GetFullImageUrl(iconPath) : null
                                };
                                categories.Add(category);
                            }
                        }
                    }
                }
                return Ok(categories);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Category
        [HttpPost]
        public async Task<IActionResult> Post([FromForm] CategoryCreateModel model)
        {
            try
            {
                string iconPath = null;

                // Xử lý upload ảnh
                if (model.IconFile != null && model.IconFile.Length > 0)
                {
                    iconPath = await SaveImageAsync(model.IconFile);
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                var category = new Category();

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    string query = @"INSERT INTO DanhMuc (TenDanhMuc, Icon) 
                           OUTPUT INSERTED.MaDanhMuc
                           VALUES (@TenDanhMuc, @Icon);";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@TenDanhMuc", model.TenDanhMuc);
                        command.Parameters.AddWithValue("@Icon", iconPath ?? (object)DBNull.Value);

                        var newId = command.ExecuteScalar()?.ToString();
                        category.MaDanhMuc = newId;
                        category.TenDanhMuc = model.TenDanhMuc;
                        category.Icon = !string.IsNullOrEmpty(iconPath) ? GetFullImageUrl(iconPath) : null;
                    }
                }

                return Ok(new { message = "Thêm danh mục thành công", category });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Category/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> Put(string id, [FromForm] CategoryUpdateModel model)
        {
            try
            {
                string iconPath = model.CurrentIconPath;

                // Xử lý upload ảnh mới nếu có
                if (model.IconFile != null && model.IconFile.Length > 0)
                {
                    // Xóa ảnh cũ nếu có
                    if (!string.IsNullOrEmpty(model.CurrentIconPath))
                    {
                        DeleteImage(model.CurrentIconPath);
                    }
                    iconPath = await SaveImageAsync(model.IconFile);
                }

                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    string query = @"UPDATE DanhMuc 
                                   SET TenDanhMuc = @TenDanhMuc, 
                                       Icon = @Icon
                                   WHERE MaDanhMuc = @MaDanhMuc";

                    using (var command = new SqlCommand(query, connection))
                    {
                        command.Parameters.AddWithValue("@MaDanhMuc", id);
                        command.Parameters.AddWithValue("@TenDanhMuc", model.TenDanhMuc);
                        command.Parameters.AddWithValue("@Icon", iconPath ?? (object)DBNull.Value);

                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy danh mục" });
                        }
                    }
                }

                // Trả về URL đầy đủ sau khi cập nhật
                var fullIconUrl = !string.IsNullOrEmpty(iconPath) ? GetFullImageUrl(iconPath) : null;
                return Ok(new { message = "Cập nhật danh mục thành công", iconUrl = fullIconUrl });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // DELETE: api/Category/{id}
        [HttpDelete("{id}")]
        public IActionResult Delete(string id)
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();

                    // Lấy đường dẫn ảnh để xóa
                    string getIconQuery = "SELECT Icon FROM DanhMuc WHERE MaDanhMuc = @MaDanhMuc";
                    string iconPath = null;

                    using (var getCommand = new SqlCommand(getIconQuery, connection))
                    {
                        getCommand.Parameters.AddWithValue("@MaDanhMuc", id);
                        var result = getCommand.ExecuteScalar();
                        iconPath = result?.ToString();
                    }

                    // Kiểm tra xem danh mục có sản phẩm không trước khi xóa
                    string checkQuery = "SELECT COUNT(*) FROM SanPham WHERE MaDanhMuc = @MaDanhMuc";
                    using (var checkCommand = new SqlCommand(checkQuery, connection))
                    {
                        checkCommand.Parameters.AddWithValue("@MaDanhMuc", id);
                        int productCount = Convert.ToInt32(checkCommand.ExecuteScalar());

                        if (productCount > 0)
                        {
                            return BadRequest(new { error = "Không thể xóa danh mục vì có sản phẩm thuộc danh mục này" });
                        }
                    }

                    string deleteQuery = "DELETE FROM DanhMuc WHERE MaDanhMuc = @MaDanhMuc";
                    using (var command = new SqlCommand(deleteQuery, connection))
                    {
                        command.Parameters.AddWithValue("@MaDanhMuc", id);

                        int affectedRows = command.ExecuteNonQuery();
                        if (affectedRows == 0)
                        {
                            return NotFound(new { error = "Không tìm thấy danh mục" });
                        }
                    }

                    // Xóa ảnh sau khi xóa danh mục thành công
                    if (!string.IsNullOrEmpty(iconPath))
                    {
                        DeleteImage(iconPath);
                    }
                }
                return Ok(new { message = "Xóa danh mục thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // Phương thức hỗ trợ: Lưu ảnh
        private async Task<string> SaveImageAsync(IFormFile imageFile)
        {
            if (imageFile == null || imageFile.Length == 0)
                return null;

            // Tạo thư mục images/products nếu chưa tồn tại
            var uploadsFolder = Path.Combine(_environment.WebRootPath, "images", "products");
            if (!Directory.Exists(uploadsFolder))
            {
                Directory.CreateDirectory(uploadsFolder);
            }

            // Tạo tên file unique với timestamp
            var fileName = $"{DateTime.Now.Ticks}{Path.GetExtension(imageFile.FileName)}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await imageFile.CopyToAsync(stream);
            }

            // Trả về đường dẫn đầy đủ theo định dạng mong muốn
            return $"images/products/{fileName}";
        }

        // Phương thức hỗ trợ: Xóa ảnh
        private void DeleteImage(string imagePath)
        {
            if (string.IsNullOrEmpty(imagePath))
                return;

            try
            {
                // Nếu là URL đầy đủ, chuyển về đường dẫn tương đối
                if (imagePath.StartsWith("http"))
                {
                    var uri = new Uri(imagePath);
                    imagePath = uri.AbsolutePath.TrimStart('/');
                }

                var fullPath = Path.Combine(_environment.WebRootPath, imagePath);
                if (System.IO.File.Exists(fullPath))
                {
                    System.IO.File.Delete(fullPath);
                }
            }
            catch (Exception ex)
            {
                // Log lỗi nhưng không throw để không ảnh hưởng đến flow chính
                Console.WriteLine($"Lỗi khi xóa ảnh: {ex.Message}");
            }
        }

        // Phương thức hỗ trợ: Tạo URL đầy đủ cho ảnh - ĐÃ SỬA HOÀN TOÀN
        private string GetFullImageUrl(string relativePath)
        {
            if (string.IsNullOrEmpty(relativePath))
                return "https://picsum.photos/200"; // Trả về ảnh mặc định

            // Nếu đường dẫn đã là URL đầy đủ thì trả về luôn
            if (relativePath.StartsWith("http"))
                return relativePath;

            // Chuẩn hóa đường dẫn - loại bỏ "wwwroot/" nếu có
            var cleanPath = relativePath.Replace("wwwroot/", "").TrimStart('/');

            // Nếu đường dẫn không bắt đầu bằng "images/", thêm prefix
            if (!cleanPath.StartsWith("images/"))
            {
                cleanPath = $"images/products/{cleanPath}";
            }

            // Sử dụng localhost:7240 như yêu cầu
            var baseUrl = "https://localhost:7240";
            return $"{baseUrl}/{cleanPath}";
        }
    }

    // Model cho việc tạo mới danh mục
    public class CategoryCreateModel
    {
        public string TenDanhMuc { get; set; }
        public IFormFile IconFile { get; set; }
    }

    // Model cho việc cập nhật danh mục
    public class CategoryUpdateModel
    {
        public string TenDanhMuc { get; set; }
        public IFormFile IconFile { get; set; }
        public string CurrentIconPath { get; set; }
    }
}