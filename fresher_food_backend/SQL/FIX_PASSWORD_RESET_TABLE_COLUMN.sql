-- Script để sửa kiểu dữ liệu của cột MaNguoiDung trong bảng PasswordResetRequest
-- Chạy script này nếu bảng đã tồn tại nhưng kiểu dữ liệu không khớp với MaTaiKhoan

-- Kiểm tra kiểu dữ liệu của MaTaiKhoan trong NguoiDung
DECLARE @MaTaiKhoanType NVARCHAR(50);
DECLARE @MaNguoiDungType NVARCHAR(50);
DECLARE @MaTaiKhoanMaxLength INT;
DECLARE @MaNguoiDungMaxLength INT;

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND type in (N'U'))
BEGIN
    SELECT 
        @MaTaiKhoanType = TYPE_NAME(system_type_id),
        @MaTaiKhoanMaxLength = max_length
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND name = 'MaTaiKhoan';
    
    SELECT 
        @MaNguoiDungType = TYPE_NAME(system_type_id),
        @MaNguoiDungMaxLength = max_length
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[PasswordResetRequest]') AND name = 'MaNguoiDung';
    
    PRINT 'Kiểu dữ liệu MaTaiKhoan trong NguoiDung: ' + ISNULL(@MaTaiKhoanType, 'KHÔNG TÌM THẤY');
    IF @MaTaiKhoanMaxLength > 0
        PRINT 'Độ dài MaTaiKhoan: ' + CAST(@MaTaiKhoanMaxLength AS NVARCHAR(10));
    PRINT 'Kiểu dữ liệu MaNguoiDung trong PasswordResetRequest: ' + ISNULL(@MaNguoiDungType, 'KHÔNG TÌM THẤY');
    IF @MaNguoiDungMaxLength > 0
        PRINT 'Độ dài MaNguoiDung: ' + CAST(@MaNguoiDungMaxLength AS NVARCHAR(10));
    
    -- Nếu kiểu dữ liệu không khớp và MaTaiKhoan là INT
    IF @MaTaiKhoanType = 'int' AND @MaNguoiDungType != 'int'
    BEGIN
        PRINT 'Đang sửa kiểu dữ liệu của MaNguoiDung từ ' + @MaNguoiDungType + ' sang INT...';
        
        -- Xóa foreign key nếu có
        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PasswordResetRequest_NguoiDung')
        BEGIN
            ALTER TABLE [dbo].[PasswordResetRequest]
            DROP CONSTRAINT [FK_PasswordResetRequest_NguoiDung];
            PRINT 'Đã xóa foreign key cũ';
        END
        
        -- Xóa dữ liệu cũ (vì không thể convert trực tiếp từ NVARCHAR sang INT nếu có dữ liệu không hợp lệ)
        -- Nếu bạn muốn giữ dữ liệu, hãy backup trước
        -- DELETE FROM [dbo].[PasswordResetRequest] WHERE MaNguoiDung IS NOT NULL;
        
        -- Sửa kiểu dữ liệu
        ALTER TABLE [dbo].[PasswordResetRequest]
        ALTER COLUMN [MaNguoiDung] INT NULL;
        
        PRINT 'Đã sửa kiểu dữ liệu MaNguoiDung sang INT';
        
        -- Thêm lại foreign key
        ALTER TABLE [dbo].[PasswordResetRequest]
        ADD CONSTRAINT [FK_PasswordResetRequest_NguoiDung] 
        FOREIGN KEY ([MaNguoiDung]) 
        REFERENCES [dbo].[NguoiDung]([MaTaiKhoan]) ON DELETE CASCADE;
        
        PRINT 'Đã thêm lại foreign key FK_PasswordResetRequest_NguoiDung';
    END
    ELSE IF @MaTaiKhoanType = 'int' AND @MaNguoiDungType = 'int'
    BEGIN
        PRINT 'Kiểu dữ liệu đã khớp (INT). Không cần sửa.';
        
        -- Thêm foreign key nếu chưa có
        IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PasswordResetRequest_NguoiDung')
        BEGIN
            ALTER TABLE [dbo].[PasswordResetRequest]
            ADD CONSTRAINT [FK_PasswordResetRequest_NguoiDung] 
            FOREIGN KEY ([MaNguoiDung]) 
            REFERENCES [dbo].[NguoiDung]([MaTaiKhoan]) ON DELETE CASCADE;
            
            PRINT 'Đã thêm foreign key FK_PasswordResetRequest_NguoiDung';
        END
        ELSE
        BEGIN
            PRINT 'Foreign key đã tồn tại.';
        END
    END
    -- Xử lý trường hợp VARCHAR vs NVARCHAR
    ELSE IF (@MaTaiKhoanType = 'varchar' AND @MaNguoiDungType = 'nvarchar') OR 
            (@MaTaiKhoanType = 'nvarchar' AND @MaNguoiDungType = 'varchar') OR
            (@MaTaiKhoanType != @MaNguoiDungType AND @MaTaiKhoanType != 'int')
    BEGIN
        PRINT 'Đang sửa kiểu dữ liệu của MaNguoiDung để khớp với MaTaiKhoan...';
        
        -- Xóa foreign key nếu có
        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PasswordResetRequest_NguoiDung')
        BEGIN
            ALTER TABLE [dbo].[PasswordResetRequest]
            DROP CONSTRAINT [FK_PasswordResetRequest_NguoiDung];
            PRINT 'Đã xóa foreign key cũ';
        END
        
        -- Xác định độ dài cho cột mới
        DECLARE @NewLength NVARCHAR(10) = '50';
        IF @MaTaiKhoanMaxLength > 0
        BEGIN
            IF @MaTaiKhoanType LIKE 'nvarchar%'
                SET @NewLength = CAST(@MaTaiKhoanMaxLength / 2 AS NVARCHAR(10)); -- NVARCHAR uses 2 bytes per char
            ELSE
                SET @NewLength = CAST(@MaTaiKhoanMaxLength AS NVARCHAR(10));
        END
        
        -- Sửa kiểu dữ liệu
        DECLARE @AlterSQL NVARCHAR(MAX);
        IF @MaTaiKhoanType = 'varchar'
        BEGIN
            SET @AlterSQL = N'ALTER TABLE [dbo].[PasswordResetRequest] ALTER COLUMN [MaNguoiDung] VARCHAR(' + @NewLength + ') NULL';
        END
        ELSE IF @MaTaiKhoanType = 'nvarchar'
        BEGIN
            SET @AlterSQL = N'ALTER TABLE [dbo].[PasswordResetRequest] ALTER COLUMN [MaNguoiDung] NVARCHAR(' + @NewLength + ') NULL';
        END
        ELSE
        BEGIN
            -- Giữ nguyên nếu không xác định được
            SET @AlterSQL = NULL;
        END
        
        IF @AlterSQL IS NOT NULL
        BEGIN
            EXEC sp_executesql @AlterSQL;
            PRINT 'Đã sửa kiểu dữ liệu MaNguoiDung sang ' + @MaTaiKhoanType + '(' + @NewLength + ')';
        END
        
        -- Thêm lại foreign key
        IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PasswordResetRequest_NguoiDung')
        BEGIN
            ALTER TABLE [dbo].[PasswordResetRequest]
            ADD CONSTRAINT [FK_PasswordResetRequest_NguoiDung] 
            FOREIGN KEY ([MaNguoiDung]) 
            REFERENCES [dbo].[NguoiDung]([MaTaiKhoan]) ON DELETE CASCADE;
            
            PRINT 'Đã thêm lại foreign key FK_PasswordResetRequest_NguoiDung';
        END
    END
    ELSE
    BEGIN
        PRINT 'Kiểu dữ liệu đã khớp: ' + ISNULL(@MaTaiKhoanType, 'UNKNOWN');
        
        -- Thêm foreign key nếu chưa có
        IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PasswordResetRequest_NguoiDung')
        BEGIN
            ALTER TABLE [dbo].[PasswordResetRequest]
            ADD CONSTRAINT [FK_PasswordResetRequest_NguoiDung] 
            FOREIGN KEY ([MaNguoiDung]) 
            REFERENCES [dbo].[NguoiDung]([MaTaiKhoan]) ON DELETE CASCADE;
            
            PRINT 'Đã thêm foreign key FK_PasswordResetRequest_NguoiDung';
        END
        ELSE
        BEGIN
            PRINT 'Foreign key đã tồn tại.';
        END
    END
END
ELSE
BEGIN
    PRINT 'Bảng NguoiDung không tồn tại. Không thể sửa.';
END
GO

