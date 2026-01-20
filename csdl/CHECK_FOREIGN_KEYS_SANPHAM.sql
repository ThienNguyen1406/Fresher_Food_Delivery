-- Script kiểm tra tất cả các Foreign Key liên quan đến bảng SanPham
-- Chạy script này để xem các bảng nào đang tham chiếu đến SanPham

-- 1. Tìm tất cả các Foreign Key tham chiếu đến SanPham
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

-- 2. Kiểm tra các bảng có thể chứa MaSanPham (ngay cả khi không có foreign key)
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.name LIKE '%SanPham%' OR c.name LIKE '%MaSanPham%'
ORDER BY t.name, c.name;

-- 3. Kiểm tra số lượng bản ghi trong các bảng liên quan (thay @MaSanPham bằng mã sản phẩm thực tế)
-- Ví dụ: SELECT COUNT(*) FROM ChiTietDonHang WHERE MaSanPham = 'SP001'
-- Ví dụ: SELECT COUNT(*) FROM GioHang WHERE MaSanPham = 'SP001'
-- Ví dụ: SELECT COUNT(*) FROM YeuThich WHERE MaSanPham = 'SP001'
-- Ví dụ: SELECT COUNT(*) FROM DanhGia WHERE MaSanPham = 'SP001'

