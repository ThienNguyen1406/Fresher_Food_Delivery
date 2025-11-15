namespace FressFood.Models
{
    public class Sale
    {
        public string Id_sale { get; set; } = string.Empty;
        public decimal GiaTriKhuyenMai { get; set; }
        public string? MoTaChuongTrinh { get; set; }
        public DateTime NgayBatDau { get; set; }
        public DateTime NgayKetThuc { get; set; }
        public string? TrangThai { get; set; }
        public string MaSanPham { get; set; } = string.Empty;
    }
}
