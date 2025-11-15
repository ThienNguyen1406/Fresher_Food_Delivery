namespace FressFood.Models
{
    public class Order
    {
        public string MaDonHang { get; set; } = string.Empty;
        public string MaTaiKhoan { get; set; } = string.Empty;
        public DateTime NgayDat { get; set; } = DateTime.Now;
        public string TrangThai { get; set; } = "Chờ xác nhận";
        public string? DiaChiGiaoHang { get; set; }
        public string? SoDienThoai { get; set; }
        public string? GhiChu { get; set; }
        public string? PhuongThucThanhToan { get; set; }
        public string TrangThaiThanhToan { get; set; } = "Chưa thanh toán";
        public string id_phieugiamgia { get; set; } = string.Empty;
        public string id_Pay { get; set; } = string.Empty;
    }
}
