namespace FressFood.Models
{
    /// <summary>
    /// Model cho thông báo trong hệ thống
    /// </summary>
    public class Notification
    {
        public string MaThongBao { get; set; }
        public string LoaiThongBao { get; set; } // "NewOrder", "OrderStatusChanged", etc.
        public string? MaDonHang { get; set; } // Foreign key đến DonHang (nullable)
        public string MaNguoiNhan { get; set; } // Admin ID
        public string TieuDe { get; set; }
        public string? NoiDung { get; set; }
        public bool DaDoc { get; set; }
        public DateTime NgayTao { get; set; }
        public DateTime? NgayDoc { get; set; }
        
        // Navigation properties (optional)
        public Order? DonHang { get; set; }
        public User? NguoiNhan { get; set; }
    }

    /// <summary>
    /// Request để đánh dấu thông báo đã đọc
    /// </summary>
    public class MarkNotificationReadRequest
    {
        public string MaThongBao { get; set; }
    }
}

