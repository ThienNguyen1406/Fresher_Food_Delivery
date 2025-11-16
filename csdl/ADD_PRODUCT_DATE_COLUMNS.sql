-- Script thêm cột NgaySanXuat và NgayHetHan vào bảng SanPham
-- Chạy script này trên SQL Server để thêm 2 cột mới

USE FressFood;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Kiểm tra và thêm cột NgaySanXuat
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'SanPham' 
               AND COLUMN_NAME = 'NgaySanXuat')
BEGIN
    ALTER TABLE [dbo].[SanPham]
    ADD [NgaySanXuat] [datetime] NULL;
    
    PRINT 'Đã thêm cột NgaySanXuat vào bảng SanPham.';
END
ELSE
BEGIN
    PRINT 'Cột NgaySanXuat đã tồn tại trong bảng SanPham.';
END
GO

-- Kiểm tra và thêm cột NgayHetHan
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'SanPham' 
               AND COLUMN_NAME = 'NgayHetHan')
BEGIN
    ALTER TABLE [dbo].[SanPham]
    ADD [NgayHetHan] [datetime] NULL;
    
    PRINT 'Đã thêm cột NgayHetHan vào bảng SanPham.';
END
ELSE
BEGIN
    PRINT 'Cột NgayHetHan đã tồn tại trong bảng SanPham.';
END
GO

PRINT 'Script hoàn tất!';
GO

