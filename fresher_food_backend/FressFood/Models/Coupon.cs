namespace FressFood.Models
{
    public class Coupon
    {
        public string Id_phieugiamgia { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
        public decimal GiaTri { get; set; }
        public string? MoTa { get; set; }
        public string LoaiGiaTri { get; set; } = "Amount"; // "Amount" hoặc "Percent"
        public int? SoLuongToiDa { get; set; } // Số lượng tối đa có thể sử dụng (NULL = không giới hạn)
        public int SoLuongDaSuDung { get; set; } = 0; // Số lượng đã sử dụng
    }
}
