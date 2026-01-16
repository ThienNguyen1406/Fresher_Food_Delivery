-- =============================================
-- Script tạo lại toàn bộ database FressFood
-- Tạo ngày: 2025-01-11
-- =============================================

USE master;
GO

-- Tạo database nếu chưa tồn tại
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'FressFood')
BEGIN
    CREATE DATABASE FressFood;
    PRINT 'Database FressFood đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Database FressFood đã tồn tại.';
END
GO

USE FressFood;
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- 1. BẢNG NguoiDung (User)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[NguoiDung](
        [MaTaiKhoan] [varchar](20) NOT NULL,
        [TenNguoiDung] [nvarchar](100) NOT NULL,
        [MatKhau] [nvarchar](255) NOT NULL,
        [Email] [nvarchar](255) NULL,
        [HoTen] [nvarchar](255) NULL,
        [Sdt] [varchar](20) NULL,
        [DiaChi] [nvarchar](500) NULL,
        [VaiTro] [nvarchar](50) NOT NULL DEFAULT ('User'),
        [Avatar] [nvarchar](500) NULL,
        
        CONSTRAINT [PK_NguoiDung] PRIMARY KEY CLUSTERED ([MaTaiKhoan] ASC)
    ) ON [PRIMARY];
    
    PRINT 'Bảng NguoiDung đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng NguoiDung đã tồn tại.';
    
    -- Thêm cột Avatar nếu chưa có
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_NAME = 'NguoiDung' AND COLUMN_NAME = 'Avatar')
    BEGIN
        ALTER TABLE [dbo].[NguoiDung] ADD [Avatar] [nvarchar](500) NULL;
        PRINT 'Đã thêm cột Avatar vào bảng NguoiDung.';
    END
END
GO

-- =============================================
-- 2. BẢNG DanhMuc (Category)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DanhMuc]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DanhMuc](
        [MaDanhMuc] [varchar](20) NOT NULL,
        [TenDanhMuc] [nvarchar](255) NOT NULL,
        [Icon] [nvarchar](500) NULL,
        
        CONSTRAINT [PK_DanhMuc] PRIMARY KEY CLUSTERED ([MaDanhMuc] ASC)
    ) ON [PRIMARY];
    
    PRINT 'Bảng DanhMuc đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng DanhMuc đã tồn tại.';
END
GO

-- =============================================
-- 3. BẢNG SanPham (Product)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SanPham]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[SanPham](
        [MaSanPham] [varchar](20) NOT NULL,
        [TenSanPham] [nvarchar](255) NOT NULL,
        [MoTa] [nvarchar](max) NULL,
        [GiaBan] [decimal](18, 2) NOT NULL,
        [Anh] [nvarchar](500) NULL,
        [SoLuongTon] [int] NOT NULL DEFAULT (0),
        [DonViTinh] [nvarchar](50) NOT NULL,
        [XuatXu] [nvarchar](255) NULL,
        [MaDanhMuc] [varchar](20) NOT NULL,
        [NgaySanXuat] [datetime] NULL,
        [NgayHetHan] [datetime] NULL,
        
        CONSTRAINT [PK_SanPham] PRIMARY KEY CLUSTERED ([MaSanPham] ASC),
        CONSTRAINT [FK_SanPham_DanhMuc] FOREIGN KEY([MaDanhMuc])
            REFERENCES [dbo].[DanhMuc] ([MaDanhMuc])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
    
    PRINT 'Bảng SanPham đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng SanPham đã tồn tại.';
    
    -- Thêm cột NgaySanXuat nếu chưa có
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_NAME = 'SanPham' AND COLUMN_NAME = 'NgaySanXuat')
    BEGIN
        ALTER TABLE [dbo].[SanPham] ADD [NgaySanXuat] [datetime] NULL;
        PRINT 'Đã thêm cột NgaySanXuat vào bảng SanPham.';
    END
    
    -- Thêm cột NgayHetHan nếu chưa có
    IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_NAME = 'SanPham' AND COLUMN_NAME = 'NgayHetHan')
    BEGIN
        ALTER TABLE [dbo].[SanPham] ADD [NgayHetHan] [datetime] NULL;
        PRINT 'Đã thêm cột NgayHetHan vào bảng SanPham.';
    END
    
    -- Thêm Foreign Key nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_SanPham_DanhMuc')
    BEGIN
        ALTER TABLE [dbo].[SanPham] WITH CHECK ADD CONSTRAINT [FK_SanPham_DanhMuc] 
            FOREIGN KEY([MaDanhMuc])
            REFERENCES [dbo].[DanhMuc] ([MaDanhMuc])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_SanPham_DanhMuc.';
    END
END
GO

-- =============================================
-- 4. BẢNG ThanhToan (Pay)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ThanhToan]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ThanhToan](
        [Id_Pay] [varchar](50) NOT NULL,
        [Pay_name] [nvarchar](255) NOT NULL,
        
        CONSTRAINT [PK_ThanhToan] PRIMARY KEY CLUSTERED ([Id_Pay] ASC)
    ) ON [PRIMARY];
    
    PRINT 'Bảng ThanhToan đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng ThanhToan đã tồn tại.';
END
GO

-- =============================================
-- 5. BẢNG PhieuGiamGia (Coupon)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PhieuGiamGia]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[PhieuGiamGia](
        [Id_phieugiamgia] [varchar](50) NOT NULL,
        [Code] [nvarchar](50) NOT NULL,
        [GiaTri] [decimal](18, 2) NOT NULL,
        [MoTa] [nvarchar](500) NULL,
        
        CONSTRAINT [PK_PhieuGiamGia] PRIMARY KEY CLUSTERED ([Id_phieugiamgia] ASC)
    ) ON [PRIMARY];
    
    PRINT 'Bảng PhieuGiamGia đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng PhieuGiamGia đã tồn tại.';
END
GO

-- =============================================
-- 6. BẢNG DonHang (Order)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DonHang]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DonHang](
        [MaDonHang] [varchar](50) NOT NULL,
        [MaTaiKhoan] [varchar](20) NOT NULL,
        [NgayDat] [datetime] NOT NULL DEFAULT (getdate()),
        [TrangThai] [nvarchar](50) NOT NULL DEFAULT (N'Chờ xác nhận'),
        [DiaChiGiaoHang] [nvarchar](500) NULL,
        [SoDienThoai] [varchar](20) NULL,
        [GhiChu] [nvarchar](1000) NULL,
        [PhuongThucThanhToan] [nvarchar](100) NULL,
        [TrangThaiThanhToan] [nvarchar](50) NOT NULL DEFAULT (N'Chưa thanh toán'),
        [id_phieugiamgia] [varchar](50) NULL,
        [id_Pay] [varchar](50) NULL,
        
        CONSTRAINT [PK_DonHang] PRIMARY KEY CLUSTERED ([MaDonHang] ASC),
        CONSTRAINT [FK_DonHang_NguoiDung] FOREIGN KEY([MaTaiKhoan])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,
        CONSTRAINT [FK_DonHang_PhieuGiamGia] FOREIGN KEY([id_phieugiamgia])
            REFERENCES [dbo].[PhieuGiamGia] ([Id_phieugiamgia])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,
        CONSTRAINT [FK_DonHang_ThanhToan] FOREIGN KEY([id_Pay])
            REFERENCES [dbo].[ThanhToan] ([Id_Pay])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
    ) ON [PRIMARY];
    
    PRINT 'Bảng DonHang đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng DonHang đã tồn tại.';
    
    -- Thêm Foreign Keys nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DonHang_NguoiDung')
    BEGIN
        ALTER TABLE [dbo].[DonHang] WITH CHECK ADD CONSTRAINT [FK_DonHang_NguoiDung] 
            FOREIGN KEY([MaTaiKhoan])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_DonHang_NguoiDung.';
    END
    
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DonHang_PhieuGiamGia')
    BEGIN
        ALTER TABLE [dbo].[DonHang] WITH CHECK ADD CONSTRAINT [FK_DonHang_PhieuGiamGia] 
            FOREIGN KEY([id_phieugiamgia])
            REFERENCES [dbo].[PhieuGiamGia] ([Id_phieugiamgia])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_DonHang_PhieuGiamGia.';
    END
    
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DonHang_ThanhToan')
    BEGIN
        ALTER TABLE [dbo].[DonHang] WITH CHECK ADD CONSTRAINT [FK_DonHang_ThanhToan] 
            FOREIGN KEY([id_Pay])
            REFERENCES [dbo].[ThanhToan] ([Id_Pay])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_DonHang_ThanhToan.';
    END
END
GO

-- =============================================
-- 7. BẢNG ChiTietDonHang (OrderDetail)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ChiTietDonHang]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ChiTietDonHang](
        [MaDonHang] [varchar](50) NOT NULL,
        [MaSanPham] [varchar](20) NOT NULL,
        [GiaBan] [decimal](18, 2) NOT NULL,
        [SoLuong] [int] NOT NULL,
        
        CONSTRAINT [PK_ChiTietDonHang] PRIMARY KEY CLUSTERED ([MaDonHang] ASC, [MaSanPham] ASC),
        CONSTRAINT [FK_ChiTietDonHang_DonHang] FOREIGN KEY([MaDonHang])
            REFERENCES [dbo].[DonHang] ([MaDonHang])
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
        CONSTRAINT [FK_ChiTietDonHang_SanPham] FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
    ) ON [PRIMARY];
    
    PRINT 'Bảng ChiTietDonHang đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng ChiTietDonHang đã tồn tại.';
    
    -- Thêm Foreign Keys nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ChiTietDonHang_DonHang')
    BEGIN
        ALTER TABLE [dbo].[ChiTietDonHang] WITH CHECK ADD CONSTRAINT [FK_ChiTietDonHang_DonHang] 
            FOREIGN KEY([MaDonHang])
            REFERENCES [dbo].[DonHang] ([MaDonHang])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_ChiTietDonHang_DonHang.';
    END
    
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ChiTietDonHang_SanPham')
    BEGIN
        ALTER TABLE [dbo].[ChiTietDonHang] WITH CHECK ADD CONSTRAINT [FK_ChiTietDonHang_SanPham] 
            FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_ChiTietDonHang_SanPham.';
    END
END
GO

-- =============================================
-- 8. BẢNG GioHang (Cart)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GioHang]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[GioHang](
        [MaGioHang] [varchar](50) NOT NULL,
        [MaTaiKhoan] [varchar](20) NOT NULL,
        
        CONSTRAINT [PK_GioHang] PRIMARY KEY CLUSTERED ([MaGioHang] ASC),
        CONSTRAINT [FK_GioHang_NguoiDung] FOREIGN KEY([MaTaiKhoan])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    ) ON [PRIMARY];
    
    PRINT 'Bảng GioHang đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng GioHang đã tồn tại.';
    
    -- Thêm Foreign Key nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_GioHang_NguoiDung')
    BEGIN
        ALTER TABLE [dbo].[GioHang] WITH CHECK ADD CONSTRAINT [FK_GioHang_NguoiDung] 
            FOREIGN KEY([MaTaiKhoan])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_GioHang_NguoiDung.';
    END
END
GO

-- =============================================
-- 9. BẢNG SanPham_GioHang (CartItem)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SanPham_GioHang]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[SanPham_GioHang](
        [MaGioHang] [varchar](50) NOT NULL,
        [MaSanPham] [varchar](20) NOT NULL,
        [SoLuong] [int] NOT NULL DEFAULT (1),
        
        CONSTRAINT [PK_SanPham_GioHang] PRIMARY KEY CLUSTERED ([MaGioHang] ASC, [MaSanPham] ASC),
        CONSTRAINT [FK_SanPham_GioHang_GioHang] FOREIGN KEY([MaGioHang])
            REFERENCES [dbo].[GioHang] ([MaGioHang])
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
        CONSTRAINT [FK_SanPham_GioHang_SanPham] FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    ) ON [PRIMARY];
    
    PRINT 'Bảng SanPham_GioHang đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng SanPham_GioHang đã tồn tại.';
    
    -- Thêm Foreign Keys nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_SanPham_GioHang_GioHang')
    BEGIN
        ALTER TABLE [dbo].[SanPham_GioHang] WITH CHECK ADD CONSTRAINT [FK_SanPham_GioHang_GioHang] 
            FOREIGN KEY([MaGioHang])
            REFERENCES [dbo].[GioHang] ([MaGioHang])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_SanPham_GioHang_GioHang.';
    END
    
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_SanPham_GioHang_SanPham')
    BEGIN
        ALTER TABLE [dbo].[SanPham_GioHang] WITH CHECK ADD CONSTRAINT [FK_SanPham_GioHang_SanPham] 
            FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_SanPham_GioHang_SanPham.';
    END
END
GO

-- =============================================
-- 10. BẢNG DanhGia (Rating)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DanhGia]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DanhGia](
        [MaSanPham] [varchar](20) NOT NULL,
        [MaTaiKhoan] [varchar](20) NOT NULL,
        [NoiDung] [nvarchar](max) NULL,
        [SoSao] [int] NOT NULL DEFAULT (5),
        
        CONSTRAINT [PK_DanhGia] PRIMARY KEY CLUSTERED ([MaSanPham] ASC, [MaTaiKhoan] ASC),
        CONSTRAINT [FK_DanhGia_SanPham] FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
        CONSTRAINT [FK_DanhGia_NguoiDung] FOREIGN KEY([MaTaiKhoan])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
        CONSTRAINT [CK_DanhGia_SoSao] CHECK ([SoSao] >= 1 AND [SoSao] <= 5)
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
    
    PRINT 'Bảng DanhGia đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng DanhGia đã tồn tại.';
    
    -- Thêm Foreign Keys nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DanhGia_SanPham')
    BEGIN
        ALTER TABLE [dbo].[DanhGia] WITH CHECK ADD CONSTRAINT [FK_DanhGia_SanPham] 
            FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_DanhGia_SanPham.';
    END
    
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DanhGia_NguoiDung')
    BEGIN
        ALTER TABLE [dbo].[DanhGia] WITH CHECK ADD CONSTRAINT [FK_DanhGia_NguoiDung] 
            FOREIGN KEY([MaTaiKhoan])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_DanhGia_NguoiDung.';
    END
END
GO

-- =============================================
-- 11. BẢNG YeuThich (Favorite)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[YeuThich]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[YeuThich](
        [Id] [varchar](50) NOT NULL,
        [MaTaiKhoan] [varchar](20) NOT NULL,
        [MaSanPham] [varchar](20) NOT NULL,
        
        CONSTRAINT [PK_YeuThich] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_YeuThich_NguoiDung] FOREIGN KEY([MaTaiKhoan])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
        CONSTRAINT [FK_YeuThich_SanPham] FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    ) ON [PRIMARY];
    
    PRINT 'Bảng YeuThich đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng YeuThich đã tồn tại.';
    
    -- Thêm Foreign Keys nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_YeuThich_NguoiDung')
    BEGIN
        ALTER TABLE [dbo].[YeuThich] WITH CHECK ADD CONSTRAINT [FK_YeuThich_NguoiDung] 
            FOREIGN KEY([MaTaiKhoan])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_YeuThich_NguoiDung.';
    END
    
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_YeuThich_SanPham')
    BEGIN
        ALTER TABLE [dbo].[YeuThich] WITH CHECK ADD CONSTRAINT [FK_YeuThich_SanPham] 
            FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_YeuThich_SanPham.';
    END
END
GO

-- =============================================
-- 12. BẢNG KhuyenMai (Sale)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[KhuyenMai]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[KhuyenMai](
        [Id_sale] [varchar](50) NOT NULL,
        [GiaTriKhuyenMai] [decimal](18, 2) NOT NULL,
        [MoTaChuongTrinh] [nvarchar](500) NULL,
        [NgayBatDau] [datetime] NOT NULL,
        [NgayKetThuc] [datetime] NOT NULL,
        [TrangThai] [nvarchar](50) NULL DEFAULT (N'Active'),
        [MaSanPham] [varchar](20) NOT NULL,
        
        CONSTRAINT [PK_KhuyenMai] PRIMARY KEY CLUSTERED ([Id_sale] ASC),
        CONSTRAINT [FK_KhuyenMai_SanPham] FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    ) ON [PRIMARY];
    
    PRINT 'Bảng KhuyenMai đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng KhuyenMai đã tồn tại.';
    
    -- Thêm Foreign Key nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_KhuyenMai_SanPham')
    BEGIN
        ALTER TABLE [dbo].[KhuyenMai] WITH CHECK ADD CONSTRAINT [FK_KhuyenMai_SanPham] 
            FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_KhuyenMai_SanPham.';
    END
END
GO

-- =============================================
-- 13. BẢNG Chat
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Chat]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Chat](
        [MaChat] [varchar](50) NOT NULL,
        [MaNguoiDung] [varchar](20) NOT NULL,
        [MaAdmin] [varchar](20) NULL,
        [TieuDe] [nvarchar](255) NULL,
        [TrangThai] [nvarchar](50) NOT NULL DEFAULT (N'Open'),
        [NgayTao] [datetime] NOT NULL DEFAULT (getdate()),
        [NgayCapNhat] [datetime] NULL,
        [TinNhanCuoi] [nvarchar](500) NULL,
        [NgayTinNhanCuoi] [datetime] NULL,
        
        CONSTRAINT [PK_Chat] PRIMARY KEY CLUSTERED ([MaChat] ASC),
        CONSTRAINT [FK_Chat_NguoiDung] FOREIGN KEY([MaNguoiDung])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    ) ON [PRIMARY];
    
    -- Tạo Index
    CREATE INDEX [IX_Chat_MaNguoiDung] ON [dbo].[Chat]([MaNguoiDung]);
    CREATE INDEX [IX_Chat_MaAdmin] ON [dbo].[Chat]([MaAdmin]);
    CREATE INDEX [IX_Chat_TrangThai] ON [dbo].[Chat]([TrangThai]);
    CREATE INDEX [IX_Chat_NgayTinNhanCuoi] ON [dbo].[Chat]([NgayTinNhanCuoi] DESC);
    
    PRINT 'Bảng Chat đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng Chat đã tồn tại.';
    
    -- Thêm Foreign Key nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Chat_NguoiDung')
    BEGIN
        ALTER TABLE [dbo].[Chat] WITH CHECK ADD CONSTRAINT [FK_Chat_NguoiDung] 
            FOREIGN KEY([MaNguoiDung])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_Chat_NguoiDung.';
    END
END
GO

-- =============================================
-- 14. BẢNG Message
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Message]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Message](
        [MaTinNhan] [varchar](50) NOT NULL,
        [MaChat] [varchar](50) NOT NULL,
        [MaNguoiGui] [varchar](20) NOT NULL,
        [LoaiNguoiGui] [nvarchar](20) NOT NULL,
        [NoiDung] [nvarchar](max) NOT NULL,
        [DaDoc] [bit] NOT NULL DEFAULT (0),
        [NgayGui] [datetime] NOT NULL DEFAULT (getdate()),
        [NgayDoc] [datetime] NULL,
        
        CONSTRAINT [PK_Message] PRIMARY KEY CLUSTERED ([MaTinNhan] ASC),
        CONSTRAINT [FK_Message_Chat] FOREIGN KEY([MaChat])
            REFERENCES [dbo].[Chat] ([MaChat])
            ON DELETE CASCADE
            ON UPDATE NO ACTION,
        CONSTRAINT [FK_Message_NguoiDung] FOREIGN KEY([MaNguoiGui])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
    
    -- Tạo Index
    CREATE INDEX [IX_Message_MaChat] ON [dbo].[Message]([MaChat]);
    CREATE INDEX [IX_Message_MaNguoiGui] ON [dbo].[Message]([MaNguoiGui]);
    CREATE INDEX [IX_Message_NgayGui] ON [dbo].[Message]([NgayGui] DESC);
    CREATE INDEX [IX_Message_DaDoc] ON [dbo].[Message]([DaDoc]);
    
    PRINT 'Bảng Message đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng Message đã tồn tại.';
    
    -- Thêm Foreign Keys nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Message_Chat')
    BEGIN
        ALTER TABLE [dbo].[Message] WITH CHECK ADD CONSTRAINT [FK_Message_Chat] 
            FOREIGN KEY([MaChat])
            REFERENCES [dbo].[Chat] ([MaChat])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_Message_Chat.';
    END
    
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Message_NguoiDung')
    BEGIN
        ALTER TABLE [dbo].[Message] WITH CHECK ADD CONSTRAINT [FK_Message_NguoiDung] 
            FOREIGN KEY([MaNguoiGui])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE NO ACTION
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_Message_NguoiDung.';
    END
END
GO

-- =============================================
-- 15. BẢNG ProductTraceability
-- =============================================
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
        [NgayTao] [datetime] NOT NULL DEFAULT (getdate()),
        [NgayCapNhat] [datetime] NULL,
        
        CONSTRAINT [PK_ProductTraceability] PRIMARY KEY CLUSTERED ([MaTruyXuat] ASC),
        CONSTRAINT [FK_ProductTraceability_SanPham] FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    ) ON [PRIMARY];
    
    -- Tạo Index
    CREATE INDEX [IX_ProductTraceability_MaSanPham] ON [dbo].[ProductTraceability]([MaSanPham]);
    CREATE INDEX [IX_ProductTraceability_BlockchainTransactionId] ON [dbo].[ProductTraceability]([BlockchainTransactionId]);
    
    PRINT 'Bảng ProductTraceability đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng ProductTraceability đã tồn tại.';
    
    -- Thêm Foreign Key nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProductTraceability_SanPham')
    BEGIN
        ALTER TABLE [dbo].[ProductTraceability] WITH CHECK ADD CONSTRAINT [FK_ProductTraceability_SanPham] 
            FOREIGN KEY([MaSanPham])
            REFERENCES [dbo].[SanPham] ([MaSanPham])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_ProductTraceability_SanPham.';
    END
END
GO

-- =============================================
-- TẠO INDEX BỔ SUNG ĐỂ TỐI ƯU HIỆU SUẤT
-- =============================================

-- Index cho bảng NguoiDung
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_NguoiDung_Email' AND object_id = OBJECT_ID('dbo.NguoiDung'))
BEGIN
    CREATE INDEX [IX_NguoiDung_Email] ON [dbo].[NguoiDung]([Email]);
    PRINT 'Đã tạo Index IX_NguoiDung_Email.';
END

-- Index cho bảng SanPham
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SanPham_MaDanhMuc' AND object_id = OBJECT_ID('dbo.SanPham'))
BEGIN
    CREATE INDEX [IX_SanPham_MaDanhMuc] ON [dbo].[SanPham]([MaDanhMuc]);
    PRINT 'Đã tạo Index IX_SanPham_MaDanhMuc.';
END

-- Index cho bảng DonHang
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DonHang_MaTaiKhoan' AND object_id = OBJECT_ID('dbo.DonHang'))
BEGIN
    CREATE INDEX [IX_DonHang_MaTaiKhoan] ON [dbo].[DonHang]([MaTaiKhoan]);
    PRINT 'Đã tạo Index IX_DonHang_MaTaiKhoan.';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DonHang_NgayDat' AND object_id = OBJECT_ID('dbo.DonHang'))
BEGIN
    CREATE INDEX [IX_DonHang_NgayDat] ON [dbo].[DonHang]([NgayDat] DESC);
    PRINT 'Đã tạo Index IX_DonHang_NgayDat.';
END

-- Index cho bảng GioHang
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_GioHang_MaTaiKhoan' AND object_id = OBJECT_ID('dbo.GioHang'))
BEGIN
    CREATE INDEX [IX_GioHang_MaTaiKhoan] ON [dbo].[GioHang]([MaTaiKhoan]);
    PRINT 'Đã tạo Index IX_GioHang_MaTaiKhoan.';
END

GO

-- =============================================
-- HOÀN TẤT
-- =============================================
PRINT '';
PRINT '=============================================';
PRINT 'HOÀN TẤT TẠO DATABASE FRESSFOOD';
PRINT '=============================================';
PRINT '';
PRINT 'Đã tạo các bảng sau:';
PRINT '1. NguoiDung (User)';
PRINT '2. DanhMuc (Category)';
PRINT '3. SanPham (Product)';
PRINT '4. ThanhToan (Pay)';
PRINT '5. PhieuGiamGia (Coupon)';
PRINT '6. DonHang (Order)';
PRINT '7. ChiTietDonHang (OrderDetail)';
PRINT '8. GioHang (Cart)';
PRINT '9. SanPham_GioHang (CartItem)';
PRINT '10. DanhGia (Rating)';
PRINT '11. YeuThich (Favorite)';
PRINT '12. KhuyenMai (Sale)';
PRINT '13. Chat';
PRINT '14. Message';
PRINT '15. ProductTraceability';
PRINT '';
PRINT 'Database đã sẵn sàng sử dụng!';
GO






