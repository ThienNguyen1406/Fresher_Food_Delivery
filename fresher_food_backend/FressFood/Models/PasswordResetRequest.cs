namespace FressFood.Models
{
    /// <summary>
    /// Model cho yêu cầu đặt lại mật khẩu
    /// </summary>
    public class PasswordResetRequest
    {
        public string MaYeuCau { get; set; }
        public string Email { get; set; }
        public string? MaNguoiDung { get; set; }
        public string? TenNguoiDung { get; set; }
        public string TrangThai { get; set; } // "Pending", "Approved", "Rejected"
        public DateTime NgayTao { get; set; }
        public DateTime? NgayXuLy { get; set; }
        public string? MaAdminXuLy { get; set; }
        public string? MatKhauMoi { get; set; } // Lưu tạm để gửi email, sau đó xóa
    }

    /// <summary>
    /// Request để tạo yêu cầu đặt lại mật khẩu
    /// </summary>
    public class CreatePasswordResetRequest
    {
        public string Email { get; set; } = string.Empty;
    }

    /// <summary>
    /// Request để admin xử lý yêu cầu
    /// </summary>
    public class ProcessPasswordResetRequest
    {
        public string MaYeuCau { get; set; } = string.Empty;
        public string Action { get; set; } = string.Empty; // "Approve" or "Reject"
        public string? MaAdmin { get; set; }
    }
}

