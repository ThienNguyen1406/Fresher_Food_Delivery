namespace FressFood.Models
{
    public class Coupon
    {
        public string Id_phieugiamgia { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
        public decimal GiaTri { get; set; }
        public string? MoTa { get; set; }
    }
}
