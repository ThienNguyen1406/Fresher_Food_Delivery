-- =============================================
-- Script cập nhật ngày sản xuất và ngày hết hạn cho tất cả sản phẩm
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

PRINT 'Bắt đầu cập nhật ngày sản xuất và ngày hết hạn cho tất cả sản phẩm...';
PRINT 'Lưu ý: Script này sẽ cập nhật TẤT CẢ sản phẩm (kể cả đã có ngày).';
PRINT 'Ngày sản xuất: ' + CONVERT(VARCHAR(10), GETDATE(), 103);
PRINT 'Ngày hết hạn: ' + CONVERT(VARCHAR(10), DATEADD(DAY, 30, GETDATE()), 103);
PRINT '';

-- Cập nhật ngày sản xuất = ngày hiện tại, ngày hết hạn = ngày sản xuất + 30 ngày
-- Cập nhật TẤT CẢ sản phẩm (kể cả đã có ngày)
UPDATE [dbo].[SanPham]
SET 
    [NgaySanXuat] = GETDATE(), -- Ngày sản xuất = ngày hiện tại
    [NgayHetHan] = DATEADD(DAY, 30, GETDATE()) -- Ngày hết hạn = ngày hiện tại + 30 ngày
-- Nếu chỉ muốn cập nhật sản phẩm chưa có ngày, bỏ comment dòng WHERE bên dưới:
-- WHERE [NgaySanXuat] IS NULL OR [NgayHetHan] IS NULL;

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
PRINT 'Tất cả sản phẩm đã có:';
PRINT '- Ngày sản xuất: ' + CONVERT(VARCHAR(10), GETDATE(), 103);
PRINT '- Ngày hết hạn: ' + CONVERT(VARCHAR(10), DATEADD(DAY, 30, GETDATE()), 103);
PRINT '=============================================';
GO
