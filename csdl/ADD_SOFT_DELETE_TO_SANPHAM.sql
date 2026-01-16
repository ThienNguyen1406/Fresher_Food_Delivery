-- =============================================
-- THÊM SOFT DELETE CHO BẢNG SanPham
-- =============================================
-- Thêm cột IsDeleted và DeletedAt để hỗ trợ soft delete
-- Sản phẩm bị xóa sẽ được đánh dấu thay vì xóa vĩnh viễn
-- Sau 30 ngày sẽ tự động xóa vĩnh viễn

-- Thêm cột IsDeleted (bit, default 0)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'SanPham' AND COLUMN_NAME = 'IsDeleted')
BEGIN
    ALTER TABLE [dbo].[SanPham] 
    ADD [IsDeleted] [bit] NOT NULL DEFAULT (0);
    PRINT 'Đã thêm cột IsDeleted vào bảng SanPham.';
END
ELSE
BEGIN
    PRINT 'Cột IsDeleted đã tồn tại trong bảng SanPham.';
END
GO

-- Thêm cột DeletedAt (datetime, nullable)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'SanPham' AND COLUMN_NAME = 'DeletedAt')
BEGIN
    ALTER TABLE [dbo].[SanPham] 
    ADD [DeletedAt] [datetime] NULL;
    PRINT 'Đã thêm cột DeletedAt vào bảng SanPham.';
END
ELSE
BEGIN
    PRINT 'Cột DeletedAt đã tồn tại trong bảng SanPham.';
END
GO

-- Tạo index để tối ưu query
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SanPham_IsDeleted' AND object_id = OBJECT_ID('dbo.SanPham'))
BEGIN
    CREATE INDEX [IX_SanPham_IsDeleted] ON [dbo].[SanPham]([IsDeleted]);
    PRINT 'Đã tạo Index IX_SanPham_IsDeleted.';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SanPham_DeletedAt' AND object_id = OBJECT_ID('dbo.SanPham'))
BEGIN
    CREATE INDEX [IX_SanPham_DeletedAt] ON [dbo].[SanPham]([DeletedAt]);
    PRINT 'Đã tạo Index IX_SanPham_DeletedAt.';
END
GO

-- Cập nhật tất cả sản phẩm hiện tại là chưa xóa (nếu cần)
UPDATE [dbo].[SanPham] 
SET [IsDeleted] = 0, [DeletedAt] = NULL
WHERE [IsDeleted] IS NULL OR ([IsDeleted] = 1 AND [DeletedAt] IS NULL);
GO

PRINT 'Hoàn thành thêm soft delete cho bảng SanPham!';
GO
