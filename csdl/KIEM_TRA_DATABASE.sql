-- Script kiểm tra database FoodOrder sau khi attach
-- Chạy script này để xem cấu trúc database

USE FoodOrder;
GO

-- 1. Kiểm tra tất cả các bảng
PRINT '=== DANH SÁCH CÁC BẢNG ===';
SELECT 
    TABLE_SCHEMA AS [Schema],
    TABLE_NAME AS [Table Name],
    (SELECT COUNT(*) 
     FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_NAME = t.TABLE_NAME 
       AND TABLE_SCHEMA = t.TABLE_SCHEMA) AS [Column Count]
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO

-- 2. Kiểm tra bảng NguoiDung (quan trọng cho login)
PRINT '';
PRINT '=== CẤU TRÚC BẢNG NguoiDung ===';
SELECT 
    COLUMN_NAME AS [Column Name],
    DATA_TYPE AS [Data Type],
    CHARACTER_MAXIMUM_LENGTH AS [Max Length],
    IS_NULLABLE AS [Nullable]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'NguoiDung'
ORDER BY ORDINAL_POSITION;
GO

-- 3. Kiểm tra số lượng user trong bảng NguoiDung
PRINT '';
PRINT '=== SỐ LƯỢNG USER ===';
SELECT COUNT(*) AS [Total Users] FROM NguoiDung;
GO

-- 4. Kiểm tra các bảng khác (nếu có)
PRINT '';
PRINT '=== KIỂM TRA CÁC BẢNG KHÁC ===';

-- Kiểm tra bảng SanPham
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SanPham')
BEGIN
    SELECT COUNT(*) AS [Total Products] FROM SanPham;
END

-- Kiểm tra bảng DonHang
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DonHang')
BEGIN
    SELECT COUNT(*) AS [Total Orders] FROM DonHang;
END

-- Kiểm tra bảng GioHang
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'GioHang')
BEGIN
    SELECT COUNT(*) AS [Total Cart Items] FROM GioHang;
END
GO

PRINT '';
PRINT '=== KIỂM TRA HOÀN TẤT ===';

