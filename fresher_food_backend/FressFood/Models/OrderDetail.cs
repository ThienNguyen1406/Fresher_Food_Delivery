namespace FressFood.Models
{
    public class OrderDetail
    {
        public string MaDonHang { get; set; } = string.Empty;
        public string MaSanPham { get; set; } = string.Empty;
        public string? TenSanPham { get; set; }
        public decimal GiaBan { get; set; }
        public int SoLuong { get; set; }
    }
}
