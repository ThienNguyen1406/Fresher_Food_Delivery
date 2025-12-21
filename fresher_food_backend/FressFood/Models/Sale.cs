namespace FressFood.Models
{
    public class Sale
    {
        public string Id_sale { get; set; } = string.Empty;
        public decimal GiaTriKhuyenMai { get; set; }
        public string LoaiGiaTri { get; set; } = "Amount"; // "Amount" hoặc "Percent"
        public string? MoTaChuongTrinh { get; set; }
        public DateTime NgayBatDau { get; set; }
        public DateTime NgayKetThuc { get; set; }
        public string? TrangThai { get; set; }
        public string MaSanPham { get; set; } = string.Empty; // "ALL" để áp dụng cho toàn bộ sản phẩm
    }
}
