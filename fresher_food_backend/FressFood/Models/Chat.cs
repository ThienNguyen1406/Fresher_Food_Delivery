namespace FressFood.Models
{
    public class Chat
    {
        public string MaChat { get; set; }
        public string MaNguoiDung { get; set; }
        public string? MaAdmin { get; set; }
        public string? TieuDe { get; set; }
        public string TrangThai { get; set; } // Open, Closed, Pending
        public DateTime NgayTao { get; set; }
        public DateTime? NgayCapNhat { get; set; }
        public string? TinNhanCuoi { get; set; }
        public DateTime? NgayTinNhanCuoi { get; set; }
        public int? SoTinNhanChuaDoc { get; set; } // Số tin nhắn chưa đọc
        
        // Navigation properties (optional, for joins)
        public User? NguoiDung { get; set; }
        public User? Admin { get; set; }
        public List<Message>? Messages { get; set; }
    }

    public class Message
    {
        public string MaTinNhan { get; set; }
        public string MaChat { get; set; }
        public string MaNguoiGui { get; set; }
        public string LoaiNguoiGui { get; set; } // "User" or "Admin"
        public string NoiDung { get; set; }
        public bool DaDoc { get; set; }
        public DateTime NgayGui { get; set; }
        public DateTime? NgayDoc { get; set; }
        
        // Navigation properties (optional)
        public Chat? Chat { get; set; }
        public User? NguoiGui { get; set; }
    }

    public class CreateChatRequest
    {
        public string MaNguoiDung { get; set; }
        public string? TieuDe { get; set; }
        public string? NoiDungTinNhanDau { get; set; }
    }

    public class SendMessageRequest
    {
        public string MaChat { get; set; }
        public string MaNguoiGui { get; set; }
        public string LoaiNguoiGui { get; set; } // "User" or "Admin"
        public string NoiDung { get; set; }
    }

    public class ChatWithMessagesResponse
    {
        public Chat Chat { get; set; }
        public List<Message> Messages { get; set; }
        public int SoTinNhanChuaDoc { get; set; }
    }
}

