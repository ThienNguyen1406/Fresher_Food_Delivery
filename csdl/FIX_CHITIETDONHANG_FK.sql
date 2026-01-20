-- Script sửa Foreign Key cho ChiTietDonHang để cho phép xóa SanPham
-- Script này sẽ: Xóa FK -> Cho phép NULL -> Tạo lại FK với ON DELETE SET NULL

-- BƯỚC 1: Kiểm tra thông tin hiện tại
PRINT '=== KIỂM TRA THÔNG TIN ===';

-- Tìm Foreign Key
DECLARE @FKName NVARCHAR(128);
DECLARE @TableName NVARCHAR(128);
DECLARE @SchemaName NVARCHAR(128);
DECLARE @DataType NVARCHAR(50);

SELECT 
    @FKName = fk.name,
    @TableName = OBJECT_NAME(fk.parent_object_id),
    @SchemaName = SCHEMA_NAME(tp.schema_id)
FROM sys.foreign_keys AS fk
INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
WHERE (fk.referenced_object_id = OBJECT_ID('SanPham') OR fk.referenced_object_id = OBJECT_ID('dbo.SanPham'))
  AND OBJECT_NAME(fk.parent_object_id) LIKE '%ChiTiet%'
  AND OBJECT_NAME(fk.parent_object_id) LIKE '%DonHang%';

-- Lấy kiểu dữ liệu của cột MaSanPham
SELECT @DataType = TYPE_NAME(c.system_type_id) + 
    CASE 
        WHEN TYPE_NAME(c.system_type_id) IN ('nvarchar', 'varchar', 'char', 'nchar') 
        THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR) END + ')'
        ELSE ''
    END
FROM sys.columns c
INNER JOIN sys.tables t ON c.object_id = t.object_id
WHERE t.name = @TableName AND c.name = 'MaSanPham';

PRINT 'Tên Foreign Key: ' + ISNULL(@FKName, 'KHÔNG TÌM THẤY');
PRINT 'Tên bảng: ' + ISNULL(@TableName, 'KHÔNG TÌM THẤY');
PRINT 'Schema: ' + ISNULL(@SchemaName, 'KHÔNG TÌM THẤY');
PRINT 'Kiểu dữ liệu: ' + ISNULL(@DataType, 'KHÔNG TÌM THẤY');

-- BƯỚC 2: Thực hiện sửa đổi
IF @FKName IS NOT NULL AND @TableName IS NOT NULL
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 2.1: Xóa Foreign Key
        PRINT '';
        PRINT '=== BƯỚC 1: XÓA FOREIGN KEY ===';
        DECLARE @DropFKSQL NVARCHAR(MAX) = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] DROP CONSTRAINT [' + @FKName + ']';
        EXEC sp_executesql @DropFKSQL;
        PRINT 'Đã xóa Foreign Key: ' + @FKName;
        
        -- 2.2: Cho phép NULL cho cột MaSanPham
        PRINT '';
        PRINT '=== BƯỚC 2: CHO PHÉP NULL CHO CỘT ===';
        DECLARE @AlterColumnSQL NVARCHAR(MAX) = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] ALTER COLUMN MaSanPham ' + @DataType + ' NULL';
        EXEC sp_executesql @AlterColumnSQL;
        PRINT 'Đã cho phép NULL cho MaSanPham trong ' + @TableName;
        
        -- 2.3: Tạo lại Foreign Key với ON DELETE SET NULL
        PRINT '';
        PRINT '=== BƯỚC 3: TẠO LẠI FOREIGN KEY ===';
        DECLARE @AddFKSQL NVARCHAR(MAX) = 'ALTER TABLE [' + @SchemaName + '].[' + @TableName + '] 
        ADD CONSTRAINT FK_ChiTietDonHang_SanPham 
        FOREIGN KEY (MaSanPham) REFERENCES [' + @SchemaName + '].SanPham(MaSanPham)
        ON DELETE SET NULL';
        EXEC sp_executesql @AddFKSQL;
        PRINT 'Đã tạo lại Foreign Key với ON DELETE SET NULL';
        
        COMMIT TRANSACTION;
        PRINT '';
        PRINT '=== HOÀN THÀNH THÀNH CÔNG ===';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT '';
        PRINT '=== LỖI ===';
        PRINT 'Mã lỗi: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'Thông báo: ' + ERROR_MESSAGE();
        PRINT 'Dòng: ' + CAST(ERROR_LINE() AS VARCHAR);
    END CATCH
END
ELSE
BEGIN
    PRINT '';
    PRINT '=== LỖI ===';
    PRINT 'Không tìm thấy Foreign Key hoặc bảng ChiTietDonHang.';
    PRINT 'Vui lòng kiểm tra lại tên bảng trong database.';
END

