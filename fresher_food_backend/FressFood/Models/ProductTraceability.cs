namespace FressFood.Models
{
    /// <summary>
    /// Model cho thông tin truy xuất nguồn gốc sản phẩm
    /// </summary>
    public class ProductTraceability
    {
        public string MaTruyXuat { get; set; } // Mã truy xuất duy nhất (QR Code ID)
        public string MaSanPham { get; set; } // Mã sản phẩm
        public string TenSanPham { get; set; }
        
        // Thông tin nguồn gốc
        public string NguonGoc { get; set; } // Nguồn gốc xuất xứ
        public string NhaSanXuat { get; set; } // Nhà sản xuất
        public string DiaChiSanXuat { get; set; } // Địa chỉ sản xuất
        public DateTime NgaySanXuat { get; set; } // Ngày sản xuất
        public DateTime? NgayHetHan { get; set; } // Ngày hết hạn
        
        // Thông tin vận chuyển
        public string? NhaCungCap { get; set; } // Nhà cung cấp
        public string? PhuongTienVanChuyen { get; set; } // Phương tiện vận chuyển
        public DateTime? NgayNhapKho { get; set; } // Ngày nhập kho
        
        // Thông tin chứng nhận
        public string? ChungNhanChatLuong { get; set; } // Chứng nhận chất lượng
        public string? SoChungNhan { get; set; } // Số chứng nhận
        public string? CoQuanChungNhan { get; set; } // Cơ quan chứng nhận
        
        // Thông tin blockchain
        public string? BlockchainHash { get; set; } // Hash trên blockchain
        public string? BlockchainTransactionId { get; set; } // Transaction ID trên blockchain
        public DateTime? NgayLuuBlockchain { get; set; } // Ngày lưu lên blockchain
        
        // Metadata
        public DateTime NgayTao { get; set; }
        public DateTime? NgayCapNhat { get; set; }
    }

    /// <summary>
    /// Response model khi quét QR code
    /// </summary>
    public class ProductTraceabilityResponse
    {
        public string MaTruyXuat { get; set; }
        public Product ProductInfo { get; set; }
        public ProductTraceability TraceabilityInfo { get; set; }
        public bool IsVerified { get; set; } // Đã được xác minh trên blockchain
        public string BlockchainVerificationUrl { get; set; } // Link để verify trên blockchain
    }

    /// <summary>
    /// Request model để tạo thông tin truy xuất
    /// </summary>
    public class CreateTraceabilityRequest
    {
        public string MaSanPham { get; set; }
        public string NguonGoc { get; set; }
        public string NhaSanXuat { get; set; }
        public string DiaChiSanXuat { get; set; }
        public DateTime NgaySanXuat { get; set; }
        public DateTime? NgayHetHan { get; set; }
        public string? NhaCungCap { get; set; }
        public string? PhuongTienVanChuyen { get; set; }
        public DateTime? NgayNhapKho { get; set; }
        public string? ChungNhanChatLuong { get; set; }
        public string? SoChungNhan { get; set; }
        public string? CoQuanChungNhan { get; set; }
    }
}

