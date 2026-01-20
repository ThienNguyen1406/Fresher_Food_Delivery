-- Script để sửa Foreign Key Constraints cho phép xóa sản phẩm
-- Chạy script này nếu gặp lỗi foreign key constraint khi xóa sản phẩm

-- BƯỚC 1: Kiểm tra các Foreign Key hiện tại
PRINT '=== KIỂM TRA FOREIGN KEYS ===';
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(fc.parent_object_id, fc.parent_column_id) AS ColumnName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTableName,
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS ReferencedColumnName,
    fk.delete_referential_action_desc AS DeleteAction
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fc ON fk.object_id = fc.constraint_object_id
WHERE fk.referenced_object_id = OBJECT_ID('SanPham')
ORDER BY TableName, ColumnName;

-- BƯỚC 2: Xóa và tạo lại Foreign Keys với ON DELETE CASCADE hoặc ON DELETE SET NULL
-- Lưu ý: Chỉ chạy nếu cần thiết và đã backup database

-- 2.1. Sửa Foreign Key cho ChiTietDonHang (nếu có)
-- Nếu muốn tự động xóa ChiTietDonHang khi xóa SanPham:
/*
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ChiTietDonHang_SanPham')
BEGIN
    ALTER TABLE ChiTietDonHang
    DROP CONSTRAINT FK_ChiTietDonHang_SanPham;
    
    ALTER TABLE ChiTietDonHang
    ADD CONSTRAINT FK_ChiTietDonHang_SanPham 
    FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
    ON DELETE CASCADE;
    
    PRINT 'Đã sửa Foreign Key cho ChiTietDonHang';
END
*/

-- 2.2. Sửa Foreign Key cho DanhGia (nếu có)
/*
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DanhGia_SanPham')
BEGIN
    ALTER TABLE DanhGia
    DROP CONSTRAINT FK_DanhGia_SanPham;
    
    ALTER TABLE DanhGia
    ADD CONSTRAINT FK_DanhGia_SanPham 
    FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
    ON DELETE CASCADE;
    
    PRINT 'Đã sửa Foreign Key cho DanhGia';
END
*/

-- 2.3. Sửa Foreign Key cho GioHang (nếu có)
/*
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_GioHang_SanPham')
BEGIN
    ALTER TABLE GioHang
    DROP CONSTRAINT FK_GioHang_SanPham;
    
    ALTER TABLE GioHang
    ADD CONSTRAINT FK_GioHang_SanPham 
    FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
    ON DELETE CASCADE;
    
    PRINT 'Đã sửa Foreign Key cho GioHang';
END
*/

-- 2.4. Sửa Foreign Key cho YeuThich (nếu có)
/*
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_YeuThich_SanPham')
BEGIN
    ALTER TABLE YeuThich
    DROP CONSTRAINT FK_YeuThich_SanPham;
    
    ALTER TABLE YeuThich
    ADD CONSTRAINT FK_YeuThich_SanPham 
    FOREIGN KEY (MaSanPham) REFERENCES SanPham(MaSanPham)
    ON DELETE CASCADE;
    
    PRINT 'Đã sửa Foreign Key cho YeuThich';
END
*/

-- BƯỚC 3: Tìm tên chính xác của Foreign Keys (nếu không biết tên)
PRINT '=== TÌM TÊN FOREIGN KEYS ===';
SELECT 
    fk.name AS ForeignKeyName,
    'ALTER TABLE ' + OBJECT_NAME(fk.parent_object_id) + ' DROP CONSTRAINT ' + fk.name + ';' AS DropCommand,
    'ALTER TABLE ' + OBJECT_NAME(fk.parent_object_id) + 
    ' ADD CONSTRAINT ' + fk.name + 
    ' FOREIGN KEY (' + COL_NAME(fc.parent_object_id, fc.parent_column_id) + ')' +
    ' REFERENCES ' + OBJECT_NAME(fk.referenced_object_id) + 
    '(' + COL_NAME(fc.referenced_object_id, fc.referenced_column_id) + ')' +
    ' ON DELETE CASCADE;' AS AddCommand
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fc ON fk.object_id = fc.constraint_object_id
WHERE fk.referenced_object_id = OBJECT_ID('SanPham')
ORDER BY OBJECT_NAME(fk.parent_object_id);

PRINT '=== HOÀN THÀNH ===';
PRINT 'Lưu ý: Chỉ chạy các lệnh ALTER TABLE sau khi đã kiểm tra và backup database!';

