-- Tạo bảng PasswordResetRequest để lưu yêu cầu đặt lại mật khẩu
-- Script này tự động phát hiện kiểu dữ liệu của MaTaiKhoan trong bảng NguoiDung

-- Bước 1: Kiểm tra và lấy kiểu dữ liệu của MaTaiKhoan trong NguoiDung
DECLARE @MaTaiKhoanType NVARCHAR(50);
DECLARE @MaTaiKhoanMaxLength INT;

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND type in (N'U'))
BEGIN
    SELECT 
        @MaTaiKhoanType = TYPE_NAME(system_type_id),
        @MaTaiKhoanMaxLength = max_length
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND name = 'MaTaiKhoan';
    
    PRINT 'Kiểu dữ liệu MaTaiKhoan trong NguoiDung: ' + ISNULL(@MaTaiKhoanType, 'KHÔNG TÌM THẤY');
    IF @MaTaiKhoanMaxLength > 0
        PRINT 'Độ dài tối đa: ' + CAST(@MaTaiKhoanMaxLength AS NVARCHAR(10));
END
ELSE
BEGIN
    PRINT 'Warning: Table NguoiDung does not exist. Using default NVARCHAR(50) for MaNguoiDung.';
    SET @MaTaiKhoanType = NULL;
END

-- Bước 2: Tạo bảng với kiểu dữ liệu phù hợp
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PasswordResetRequest]') AND type in (N'U'))
BEGIN
    -- Xác định kiểu dữ liệu cho MaNguoiDung
    IF @MaTaiKhoanType = 'int' OR @MaTaiKhoanType = 'INT'
    BEGIN
        CREATE TABLE [dbo].[PasswordResetRequest] (
            [MaYeuCau] NVARCHAR(50) PRIMARY KEY,
            [Email] NVARCHAR(255) NOT NULL,
            [MaNguoiDung] INT NULL,
            [TenNguoiDung] NVARCHAR(255) NULL,
            [TrangThai] NVARCHAR(20) NOT NULL DEFAULT 'Pending',
            [NgayTao] DATETIME NOT NULL DEFAULT GETDATE(),
            [NgayXuLy] DATETIME NULL,
            [MaAdminXuLy] NVARCHAR(50) NULL,
            [MatKhauMoi] NVARCHAR(255) NULL
        );
        PRINT 'Table PasswordResetRequest created with MaNguoiDung as INT';
    END
    ELSE IF @MaTaiKhoanType LIKE 'nvarchar%' OR @MaTaiKhoanType LIKE 'varchar%'
    BEGIN
        -- Xác định độ dài
        DECLARE @Length NVARCHAR(10) = '50';
        IF @MaTaiKhoanMaxLength > 0 AND @MaTaiKhoanMaxLength < 4000
            SET @Length = CAST(@MaTaiKhoanMaxLength / 2 AS NVARCHAR(10)); -- NVARCHAR uses 2 bytes per char
        
        DECLARE @CreateTableSQL NVARCHAR(MAX) = N'
        CREATE TABLE [dbo].[PasswordResetRequest] (
            [MaYeuCau] NVARCHAR(50) PRIMARY KEY,
            [Email] NVARCHAR(255) NOT NULL,
            [MaNguoiDung] NVARCHAR(' + @Length + ') NULL,
            [TenNguoiDung] NVARCHAR(255) NULL,
            [TrangThai] NVARCHAR(20) NOT NULL DEFAULT ''Pending'',
            [NgayTao] DATETIME NOT NULL DEFAULT GETDATE(),
            [NgayXuLy] DATETIME NULL,
            [MaAdminXuLy] NVARCHAR(50) NULL,
            [MatKhauMoi] NVARCHAR(255) NULL
        );';
        
        EXEC sp_executesql @CreateTableSQL;
        PRINT 'Table PasswordResetRequest created with MaNguoiDung as NVARCHAR(' + @Length + ')';
    END
    ELSE
    BEGIN
        -- Mặc định dùng NVARCHAR(50) nếu không xác định được
        CREATE TABLE [dbo].[PasswordResetRequest] (
            [MaYeuCau] NVARCHAR(50) PRIMARY KEY,
            [Email] NVARCHAR(255) NOT NULL,
            [MaNguoiDung] NVARCHAR(50) NULL,
            [TenNguoiDung] NVARCHAR(255) NULL,
            [TrangThai] NVARCHAR(20) NOT NULL DEFAULT 'Pending',
            [NgayTao] DATETIME NOT NULL DEFAULT GETDATE(),
            [NgayXuLy] DATETIME NULL,
            [MaAdminXuLy] NVARCHAR(50) NULL,
            [MatKhauMoi] NVARCHAR(255) NULL
        );
        PRINT 'Table PasswordResetRequest created with MaNguoiDung as NVARCHAR(50) (default)';
    END

    -- Tạo index để tìm kiếm nhanh
    CREATE INDEX [IX_PasswordResetRequest_Email] ON [dbo].[PasswordResetRequest]([Email]);
    CREATE INDEX [IX_PasswordResetRequest_TrangThai] ON [dbo].[PasswordResetRequest]([TrangThai]);
    CREATE INDEX [IX_PasswordResetRequest_NgayTao] ON [dbo].[PasswordResetRequest]([NgayTao] DESC);

    -- Thêm foreign key nếu bảng NguoiDung tồn tại và kiểu dữ liệu khớp
    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND type in (N'U'))
    BEGIN
        IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND name = 'MaTaiKhoan')
        BEGIN
            IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PasswordResetRequest_NguoiDung')
            BEGIN
                ALTER TABLE [dbo].[PasswordResetRequest]
                ADD CONSTRAINT [FK_PasswordResetRequest_NguoiDung] 
                FOREIGN KEY ([MaNguoiDung]) 
                REFERENCES [dbo].[NguoiDung]([MaTaiKhoan]) ON DELETE CASCADE;
                
                PRINT 'Foreign key FK_PasswordResetRequest_NguoiDung created successfully';
            END
            ELSE
            BEGIN
                PRINT 'Foreign key FK_PasswordResetRequest_NguoiDung already exists';
            END
        END
    END
END
ELSE
BEGIN
    PRINT 'Table PasswordResetRequest already exists';
    
    -- Nếu bảng đã tồn tại nhưng chưa có foreign key, thử thêm
    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND type in (N'U'))
    BEGIN
        IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND name = 'MaTaiKhoan')
        BEGIN
            IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_PasswordResetRequest_NguoiDung')
            BEGIN
                -- Kiểm tra kiểu dữ liệu có khớp không trước khi thêm foreign key
                DECLARE @ColumnTypeMatch BIT = 0;
                
                SELECT @ColumnTypeMatch = CASE 
                    WHEN (SELECT TYPE_NAME(system_type_id) FROM sys.columns 
                          WHERE object_id = OBJECT_ID(N'[dbo].[PasswordResetRequest]') AND name = 'MaNguoiDung') = 
                         (SELECT TYPE_NAME(system_type_id) FROM sys.columns 
                          WHERE object_id = OBJECT_ID(N'[dbo].[NguoiDung]') AND name = 'MaTaiKhoan')
                    THEN 1 
                    ELSE 0 
                END;
                
                IF @ColumnTypeMatch = 1
                BEGIN
                    ALTER TABLE [dbo].[PasswordResetRequest]
                    ADD CONSTRAINT [FK_PasswordResetRequest_NguoiDung] 
                    FOREIGN KEY ([MaNguoiDung]) 
                    REFERENCES [dbo].[NguoiDung]([MaTaiKhoan]) ON DELETE CASCADE;
                    
                    PRINT 'Foreign key FK_PasswordResetRequest_NguoiDung added successfully';
                END
                ELSE
                BEGIN
                    PRINT 'Warning: Data type mismatch. Cannot add foreign key.';
                    PRINT 'Please check and update MaNguoiDung column type to match MaTaiKhoan.';
                END
            END
        END
    END
END
GO

