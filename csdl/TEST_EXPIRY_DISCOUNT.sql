-- =============================================
-- Script test giảm giá 30% khi gần hết hạn
-- Cập nhật ngày hết hạn cho khoai tây và cà rốt
-- Ngày hết hạn = hôm nay + 5 ngày (để trigger giảm giá)
-- =============================================

USE FressFood;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

PRINT 'Bắt đầu cập nhật ngày hết hạn cho khoai tây và cà rốt để test giảm giá 30%...';
PRINT '';

-- Cập nhật cho khoai tây (tìm theo tên chứa "khoai" hoặc "potato")
UPDATE [dbo].[SanPham]
SET 
    [NgaySanXuat] = DATEADD(DAY, -25, GETDATE()), -- Sản xuất 25 ngày trước
    [NgayHetHan] = DATEADD(DAY, 5, GETDATE()) -- Hết hạn sau 5 ngày (gần hết hạn)
WHERE 
    LOWER([TenSanPham]) LIKE '%khoai%' 
    OR LOWER([TenSanPham]) LIKE '%potato%'
    OR LOWER([TenSanPham]) LIKE '%khoai tây%';

DECLARE @KhoaiTayCount INT;
SET @KhoaiTayCount = @@ROWCOUNT;

-- Cập nhật cho cà rốt (tìm theo tên chứa "cà rốt" hoặc "carrot")
UPDATE [dbo].[SanPham]
SET 
    [NgaySanXuat] = DATEADD(DAY, -25, GETDATE()), -- Sản xuất 25 ngày trước
    [NgayHetHan] = DATEADD(DAY, 5, GETDATE()) -- Hết hạn sau 5 ngày (gần hết hạn)
WHERE 
    LOWER([TenSanPham]) LIKE '%cà rốt%' 
    OR LOWER([TenSanPham]) LIKE '%carrot%'
    OR LOWER([TenSanPham]) LIKE '%carot%';

DECLARE @CaRotCount INT;
SET @CaRotCount = @@ROWCOUNT;

PRINT 'Đã cập nhật ' + CAST(@KhoaiTayCount AS VARCHAR(10)) + ' sản phẩm khoai tây.';
PRINT 'Đã cập nhật ' + CAST(@CaRotCount AS VARCHAR(10)) + ' sản phẩm cà rốt.';
PRINT '';

-- Hiển thị kết quả
PRINT 'Danh sách sản phẩm đã cập nhật:';
SELECT 
    [MaSanPham],
    [TenSanPham],
    [GiaBan] AS GiaGoc,
    [GiaBan] * 0.7 AS GiaSauGiam30,
    [NgaySanXuat],
    [NgayHetHan],
    DATEDIFF(DAY, GETDATE(), [NgayHetHan]) AS SoNgayConLai
FROM [dbo].[SanPham]
WHERE 
    (LOWER([TenSanPham]) LIKE '%khoai%' 
     OR LOWER([TenSanPham]) LIKE '%potato%'
     OR LOWER([TenSanPham]) LIKE '%khoai tây%'
     OR LOWER([TenSanPham]) LIKE '%cà rốt%' 
     OR LOWER([TenSanPham]) LIKE '%carrot%'
     OR LOWER([TenSanPham]) LIKE '%carot%')
    AND [NgayHetHan] IS NOT NULL
ORDER BY [TenSanPham];
GO

PRINT '';
PRINT '=============================================';
PRINT 'Hoàn tất test!';
PRINT 'Các sản phẩm trên sẽ tự động giảm giá 30%';
PRINT 'vì còn ≤ 7 ngày đến ngày hết hạn.';
PRINT '=============================================';
GO
