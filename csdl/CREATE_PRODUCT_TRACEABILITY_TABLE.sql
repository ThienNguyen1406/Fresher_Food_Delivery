-- Script tạo bảng ProductTraceability để lưu thông tin truy xuất nguồn gốc sản phẩm
-- Chạy script này trên SQL Server để tạo bảng
-- Format khớp với database FressFood hiện tại

USE FressFood;
GO

/****** Object:  Table [dbo].[ProductTraceability]    Script Date: 11/15/2025 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Tạo bảng ProductTraceability
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductTraceability]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ProductTraceability](
        [MaTruyXuat] [varchar](50) NOT NULL,
        [MaSanPham] [varchar](20) NOT NULL,
        [TenSanPham] [nvarchar](255) NOT NULL,
        
        -- Thông tin nguồn gốc
        [NguonGoc] [nvarchar](255) NOT NULL,
        [NhaSanXuat] [nvarchar](255) NOT NULL,
        [DiaChiSanXuat] [nvarchar](500) NOT NULL,
        [NgaySanXuat] [datetime] NOT NULL,
        [NgayHetHan] [datetime] NULL,
        
        -- Thông tin vận chuyển
        [NhaCungCap] [nvarchar](255) NULL,
        [PhuongTienVanChuyen] [nvarchar](100) NULL,
        [NgayNhapKho] [datetime] NULL,
        
        -- Thông tin chứng nhận
        [ChungNhanChatLuong] [nvarchar](255) NULL,
        [SoChungNhan] [nvarchar](100) NULL,
        [CoQuanChungNhan] [nvarchar](255) NULL,
        
        -- Thông tin blockchain
        [BlockchainHash] [nvarchar](255) NULL,
        [BlockchainTransactionId] [nvarchar](255) NULL,
        [NgayLuuBlockchain] [datetime] NULL,
        
        -- Metadata
        [NgayTao] [datetime] NOT NULL,
        [NgayCapNhat] [datetime] NULL,
        
        PRIMARY KEY CLUSTERED 
        (
            [MaTruyXuat] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY]
    
    -- Tạo index để tìm kiếm nhanh
    CREATE INDEX [IX_ProductTraceability_MaSanPham] ON [dbo].[ProductTraceability]([MaSanPham])
    CREATE INDEX [IX_ProductTraceability_BlockchainTransactionId] ON [dbo].[ProductTraceability]([BlockchainTransactionId])
    
    PRINT 'Bảng ProductTraceability đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng ProductTraceability đã tồn tại.';
END
GO

-- Thêm default cho NgayTao
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductTraceability]') AND type in (N'U'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID(N'[dbo].[ProductTraceability]') AND name = N'DF_ProductTraceability_NgayTao')
    BEGIN
        ALTER TABLE [dbo].[ProductTraceability] ADD DEFAULT (getdate()) FOR [NgayTao]
        PRINT 'Đã thêm default cho NgayTao';
    END
END
GO

-- Tạo Foreign Key constraint
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProductTraceability]') AND type in (N'U'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = N'FK_ProductTraceability_SanPham')
    BEGIN
        ALTER TABLE [dbo].[ProductTraceability] WITH CHECK ADD FOREIGN KEY([MaSanPham])
        REFERENCES [dbo].[SanPham] ([MaSanPham]) ON DELETE CASCADE
        PRINT 'Đã tạo Foreign Key FK_ProductTraceability_SanPham';
    END
    ELSE
    BEGIN
        PRINT 'Foreign Key FK_ProductTraceability_SanPham đã tồn tại.';
    END
END
GO

-- Thêm dữ liệu mẫu (tùy chọn - comment out)
/*
INSERT INTO [dbo].[ProductTraceability] 
([MaTruyXuat], [MaSanPham], [TenSanPham], [NguonGoc], [NhaSanXuat], [DiaChiSanXuat], [NgaySanXuat], [NgayTao])
VALUES 
('TX202401011200001', 'SP001', N'Gạo ST25', N'Việt Nam', N'Công ty TNHH Gạo ST', N'Đồng Tháp, Việt Nam', '2024-01-01', GETDATE());
GO
*/

PRINT 'Script hoàn tất!';
GO
