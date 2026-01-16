-- =============================================
-- Script cập nhật ngày sản xuất và ngày hết hạn cho tất cả sản phẩm
-- Với ngày sản xuất và ngày hết hạn tùy chỉnh
-- Ngày hết hạn = Ngày sản xuất + 30 ngày
-- Ngày tạo: 2025-01-11
-- =============================================

USE FressFood;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Kiểm tra xem các cột đã tồn tại chưa
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'SanPham' AND COLUMN_NAME = 'NgaySanXuat')
BEGIN
    PRINT 'Lỗi: Cột NgaySanXuat chưa tồn tại. Vui lòng chạy script ADD_PRODUCT_DATE_COLUMNS.sql trước.';
    RETURN;
END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'SanPham' AND COLUMN_NAME = 'NgayHetHan')
BEGIN
    PRINT 'Lỗi: Cột NgayHetHan chưa tồn tại. Vui lòng chạy script ADD_PRODUCT_DATE_COLUMNS.sql trước.';
    RETURN;
END

-- =============================================
-- TÙY CHỈNH: Thay đổi ngày sản xuất bắt đầu ở đây
-- =============================================
DECLARE @NgaySanXuat DATETIME;
SET @NgaySanXuat = '2024-01-01'; -- Thay đổi ngày này theo nhu cầu
-- Ví dụ: SET @NgaySanXuat = GETDATE(); -- Dùng ngày hiện tại
-- Ví dụ: SET @NgaySanXuat = '2024-06-01'; -- Dùng ngày cụ thể
-- =============================================

DECLARE @NgayHetHan DATETIME;
SET @NgayHetHan = DATEADD(DAY, 30, @NgaySanXuat); -- Tự động tính ngày hết hạn = ngày sản xuất + 30 ngày

PRINT 'Bắt đầu cập nhật ngày sản xuất và ngày hết hạn cho tất cả sản phẩm...';
PRINT 'Ngày sản xuất: ' + CONVERT(VARCHAR(10), @NgaySanXuat, 103);
PRINT 'Ngày hết hạn: ' + CONVERT(VARCHAR(10), @NgayHetHan, 103);
PRINT '';

-- Cập nhật tất cả sản phẩm
UPDATE [dbo].[SanPham]
SET 
    [NgaySanXuat] = @NgaySanXuat,
    [NgayHetHan] = @NgayHetHan;

DECLARE @UpdatedCount INT;
SET @UpdatedCount = @@ROWCOUNT;

PRINT 'Đã cập nhật ' + CAST(@UpdatedCount AS VARCHAR(10)) + ' sản phẩm.';
PRINT '';

-- Hiển thị kết quả
SELECT 
    [MaSanPham],
    [TenSanPham],
    [NgaySanXuat],
    [NgayHetHan],
    DATEDIFF(DAY, [NgaySanXuat], [NgayHetHan]) AS SoNgayCachNhau
FROM [dbo].[SanPham]
WHERE [NgaySanXuat] IS NOT NULL 
    AND [NgayHetHan] IS NOT NULL
ORDER BY [MaSanPham];
GO

PRINT '';
PRINT '=============================================';
PRINT 'Hoàn tất cập nhật!';
PRINT '=============================================';
GO
