namespace FressFood.Models
{
    public class Product
    {
        public string MaSanPham { get; set; }
        public string TenSanPham { get; set; } = string.Empty;
        public string? MoTa { get; set; }
        public decimal GiaBan { get; set; }
        public string? Anh { get; set; }
        public int SoLuongTon { get; set; }
        public string DonViTinh { get; set; }
        public string XuatXu { get; set; }
        public string MaDanhMuc { get; set; }
        public string? TenDanhMuc { get; set; }

    }
}