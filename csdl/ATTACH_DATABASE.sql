-- Script để attach database FressFood.mdf vào SQL Server
-- Chạy script này trong SQL Server Management Studio (SSMS)

USE master;
GO

-- Kiểm tra xem database đã tồn tại chưa
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'FoodOrder')
BEGIN
    -- Nếu database đã tồn tại, có thể drop hoặc đổi tên
    -- DROP DATABASE FoodOrder;
    -- Hoặc đổi tên database hiện tại
    PRINT 'Database FoodOrder đã tồn tại. Vui lòng drop hoặc đổi tên trước khi attach.';
END
ELSE
BEGIN
    -- Attach database từ file .mdf
    -- Sử dụng ATTACH_REBUILD_LOG để tự động tạo file .ldf nếu không có
    CREATE DATABASE FoodOrder
    ON (FILENAME = 'D:\Fresher_Food_Delivery\csdl\FressFood.mdf')
    FOR ATTACH_REBUILD_LOG;
    
    PRINT 'Database FoodOrder đã được attach thành công!';
END
GO

-- Kiểm tra database đã được attach
USE FoodOrder;
GO

-- Kiểm tra các bảng trong database
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO

