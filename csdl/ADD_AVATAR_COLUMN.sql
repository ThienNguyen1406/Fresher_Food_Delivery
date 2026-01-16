-- Script để thêm cột Avatar vào bảng NguoiDung
USE [FressFood]
GO

-- Kiểm tra xem cột Avatar đã tồn tại chưa
IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'NguoiDung' 
    AND COLUMN_NAME = 'Avatar'
)
BEGIN
    -- Thêm cột Avatar
    ALTER TABLE [dbo].[NguoiDung]
    ADD [Avatar] [nvarchar](500) NULL;
    
    PRINT 'Đã thêm cột Avatar vào bảng NguoiDung';
END
ELSE
BEGIN
    PRINT 'Cột Avatar đã tồn tại trong bảng NguoiDung';
END
GO

