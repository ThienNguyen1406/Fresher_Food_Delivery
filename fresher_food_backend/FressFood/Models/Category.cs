namespace FressFood.Models
{
    public class Category
    {
        public string MaDanhMuc { get; set; } = string.Empty;
        public string TenDanhMuc { get; set; } = string.Empty;
        public string? Icon { get; set; } // Lưu đường dẫn ảnh
    }

    public class CategoryCreateModel
    {
        public string TenDanhMuc { get; set; } = string.Empty;
        public IFormFile? IconFile { get; set; }
    }

    public class CategoryUpdateModel
    {
        public string TenDanhMuc { get; set; } = string.Empty;
        public IFormFile? IconFile { get; set; }
        public string? CurrentIconPath { get; set; } // Giữ lại ảnh cũ nếu không upload ảnh mới
    }
}