namespace FressFood.Models
{
    /// <summary>
    /// Request model để tạo VietQR code
    /// </summary>
    public class VietQRRequest
    {
        public string MaDonHang { get; set; } = string.Empty;
        public decimal SoTien { get; set; }
        public string? NoiDung { get; set; }
    }

    /// <summary>
    /// Response model cho VietQR code
    /// </summary>
    public class VietQRResponse
    {
        public string QrData { get; set; } = string.Empty;
        public string SoTaiKhoan { get; set; } = string.Empty;
        public string TenChuTaiKhoan { get; set; } = string.Empty;
        public string TenNganHang { get; set; } = string.Empty;
        public string MaNganHang { get; set; } = string.Empty;
        public decimal SoTien { get; set; }
        public string NoiDung { get; set; } = string.Empty;
    }
}
