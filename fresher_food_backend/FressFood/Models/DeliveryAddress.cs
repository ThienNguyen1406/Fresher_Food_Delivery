namespace FressFood.Models
{
    /// <summary>
    /// Model địa chỉ giao hàng của người dùng
    /// </summary>
    public class DeliveryAddress
    {
        public string MaDiaChi { get; set; } = string.Empty;
        public string MaTaiKhoan { get; set; } = string.Empty;
        public string HoTen { get; set; } = string.Empty;
        public string SoDienThoai { get; set; } = string.Empty;
        public string DiaChi { get; set; } = string.Empty;
        public bool LaDiaChiMacDinh { get; set; } = false;
        public DateTime NgayTao { get; set; } = DateTime.Now;
        public DateTime? NgayCapNhat { get; set; }
    }

    /// <summary>
    /// Request model để tạo/cập nhật địa chỉ
    /// </summary>
    public class DeliveryAddressRequest
    {
        public string MaTaiKhoan { get; set; } = string.Empty;
        public string HoTen { get; set; } = string.Empty;
        public string SoDienThoai { get; set; } = string.Empty;
        public string DiaChi { get; set; } = string.Empty;
        public bool LaDiaChiMacDinh { get; set; } = false;
    }
}
