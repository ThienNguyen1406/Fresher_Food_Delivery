-- Script để attach database FressFood.mdf với file .ldf (nếu có)
-- Nếu không có file .ldf, SQL Server sẽ tự tạo file mới

USE master;
GO

-- Kiểm tra xem database đã tồn tại chưa
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'FoodOrder')
BEGIN
    PRINT 'Database FoodOrder đã tồn tại.';
    PRINT 'Nếu muốn attach lại, hãy drop database trước:';
    PRINT 'DROP DATABASE FoodOrder;';
END
ELSE
BEGIN
    -- Attach database với cả file .mdf và .ldf (nếu có)
    -- Nếu không có .ldf, SQL Server sẽ tự tạo
    
    -- Kiểm tra xem có file .ldf không
    DECLARE @mdfPath NVARCHAR(500) = 'D:\Fresher_Food_Delivery\csdl\FressFood.mdf';
    DECLARE @ldfPath NVARCHAR(500) = 'D:\Fresher_Food_Delivery\csdl\FressFood_log.ldf';
    
    IF EXISTS (SELECT 1 FROM sys.dm_os_file_exists(@ldfPath))
    BEGIN
        -- Attach với cả 2 file
        CREATE DATABASE FoodOrder
        ON (FILENAME = @mdfPath),
           (FILENAME = @ldfPath)
        FOR ATTACH;
    END
    ELSE
    BEGIN
        -- Chỉ attach file .mdf, SQL Server sẽ tự tạo .ldf
        CREATE DATABASE FoodOrder
        ON (FILENAME = @mdfPath)
        FOR ATTACH_REBUILD_LOG;
    END
    
    PRINT 'Database FoodOrder đã được attach thành công!';
END
GO

-- Kiểm tra database
USE FoodOrder;
GO

-- Liệt kê tất cả các bảng
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    (SELECT COUNT(*) 
     FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_NAME = t.TABLE_NAME) AS ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO

