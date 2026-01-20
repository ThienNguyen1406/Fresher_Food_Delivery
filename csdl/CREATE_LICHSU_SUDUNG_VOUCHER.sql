-- Tạo bảng lưu lịch sử sử dụng voucher của user
-- Mỗi user chỉ có thể sử dụng mỗi voucher 1 lần

-- Bước 1: Kiểm tra và tạo bảng không có foreign key trước
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'LichSuSuDungVoucher') AND type in (N'U'))
BEGIN
    -- Kiểm tra kiểu dữ liệu của MaTaiKhoan trong bảng NguoiDung
    DECLARE @MaTaiKhoanType NVARCHAR(50);
    SELECT @MaTaiKhoanType = TYPE_NAME(system_type_id) 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID(N'NguoiDung') AND name = 'MaTaiKhoan';
    
    PRINT 'Kiểu dữ liệu MaTaiKhoan trong NguoiDung: ' + ISNULL(@MaTaiKhoanType, 'KHÔNG TÌM THẤY');
    
    -- Tạo bảng với kiểu dữ liệu phù hợp
    IF @MaTaiKhoanType = 'int' OR @MaTaiKhoanType = 'INT'
    BEGIN
        CREATE TABLE LichSuSuDungVoucher (
            MaLichSu INT IDENTITY(1,1) PRIMARY KEY,
            MaTaiKhoan INT NOT NULL,
            Id_phieugiamgia NVARCHAR(50) NOT NULL,
            NgaySuDung DATETIME DEFAULT GETDATE(),
            MaDonHang NVARCHAR(50) NULL
        );
        PRINT 'Đã tạo bảng LichSuSuDungVoucher với MaTaiKhoan là INT';
    END
    ELSE IF @MaTaiKhoanType IS NOT NULL
    BEGIN
        CREATE TABLE LichSuSuDungVoucher (
            MaLichSu INT IDENTITY(1,1) PRIMARY KEY,
            MaTaiKhoan NVARCHAR(50) NOT NULL,
            Id_phieugiamgia NVARCHAR(50) NOT NULL,
            NgaySuDung DATETIME DEFAULT GETDATE(),
            MaDonHang NVARCHAR(50) NULL
        );
        PRINT 'Đã tạo bảng LichSuSuDungVoucher với MaTaiKhoan là NVARCHAR(50)';
    END
    ELSE
    BEGIN
        -- Nếu không tìm thấy, mặc định dùng NVARCHAR
        CREATE TABLE LichSuSuDungVoucher (
            MaLichSu INT IDENTITY(1,1) PRIMARY KEY,
            MaTaiKhoan NVARCHAR(50) NOT NULL,
            Id_phieugiamgia NVARCHAR(50) NOT NULL,
            NgaySuDung DATETIME DEFAULT GETDATE(),
            MaDonHang NVARCHAR(50) NULL
        );
        PRINT 'Đã tạo bảng LichSuSuDungVoucher với MaTaiKhoan là NVARCHAR(50) (mặc định)';
    END
END
ELSE
BEGIN
    PRINT 'Bảng LichSuSuDungVoucher đã tồn tại';
END
GO

-- Bước 2: Thêm constraint UNIQUE
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'LichSuSuDungVoucher') AND type in (N'U'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_User_Voucher' AND object_id = OBJECT_ID(N'LichSuSuDungVoucher'))
    BEGIN
        ALTER TABLE LichSuSuDungVoucher
        ADD CONSTRAINT UQ_User_Voucher UNIQUE (MaTaiKhoan, Id_phieugiamgia);
        PRINT 'Đã thêm constraint UNIQUE (MaTaiKhoan, Id_phieugiamgia)';
    END
    ELSE
    BEGIN
        PRINT 'Constraint UQ_User_Voucher đã tồn tại';
    END
END
GO

-- Bước 3: Thêm Foreign Keys (thêm riêng biệt với try-catch)
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'LichSuSuDungVoucher') AND type in (N'U'))
BEGIN
    -- Foreign key đến NguoiDung
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_LichSu_NguoiDung')
    BEGIN
        BEGIN TRY
            ALTER TABLE LichSuSuDungVoucher
            ADD CONSTRAINT FK_LichSu_NguoiDung FOREIGN KEY (MaTaiKhoan) REFERENCES NguoiDung(MaTaiKhoan);
            PRINT 'Đã thêm foreign key FK_LichSu_NguoiDung';
        END TRY
        BEGIN CATCH
            PRINT 'Lỗi khi thêm foreign key FK_LichSu_NguoiDung: ' + ERROR_MESSAGE();
        END CATCH
    END
    ELSE
    BEGIN
        PRINT 'Foreign key FK_LichSu_NguoiDung đã tồn tại';
    END
    
    -- Foreign key đến PhieuGiamGia
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_LichSu_PhieuGiamGia')
    BEGIN
        BEGIN TRY
            ALTER TABLE LichSuSuDungVoucher
            ADD CONSTRAINT FK_LichSu_PhieuGiamGia FOREIGN KEY (Id_phieugiamgia) REFERENCES PhieuGiamGia(Id_phieugiamgia);
            PRINT 'Đã thêm foreign key FK_LichSu_PhieuGiamGia';
        END TRY
        BEGIN CATCH
            PRINT 'Lỗi khi thêm foreign key FK_LichSu_PhieuGiamGia: ' + ERROR_MESSAGE();
        END CATCH
    END
    ELSE
    BEGIN
        PRINT 'Foreign key FK_LichSu_PhieuGiamGia đã tồn tại';
    END
    
    -- Foreign key đến DonHang (nullable)
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_LichSu_DonHang')
    BEGIN
        BEGIN TRY
            ALTER TABLE LichSuSuDungVoucher
            ADD CONSTRAINT FK_LichSu_DonHang FOREIGN KEY (MaDonHang) REFERENCES DonHang(MaDonHang);
            PRINT 'Đã thêm foreign key FK_LichSu_DonHang';
        END TRY
        BEGIN CATCH
            PRINT 'Lỗi khi thêm foreign key FK_LichSu_DonHang: ' + ERROR_MESSAGE();
        END CATCH
    END
    ELSE
    BEGIN
        PRINT 'Foreign key FK_LichSu_DonHang đã tồn tại';
    END
END
GO

-- Bước 4: Tạo index để tăng tốc độ truy vấn
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'LichSuSuDungVoucher') AND type in (N'U'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_LichSu_MaTaiKhoan' AND object_id = OBJECT_ID(N'LichSuSuDungVoucher'))
    BEGIN
        CREATE INDEX IX_LichSu_MaTaiKhoan ON LichSuSuDungVoucher(MaTaiKhoan);
        PRINT 'Đã tạo index IX_LichSu_MaTaiKhoan';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_LichSu_MaTaiKhoan đã tồn tại';
    END
    
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_LichSu_IdPhieuGiamGia' AND object_id = OBJECT_ID(N'LichSuSuDungVoucher'))
    BEGIN
        CREATE INDEX IX_LichSu_IdPhieuGiamGia ON LichSuSuDungVoucher(Id_phieugiamgia);
        PRINT 'Đã tạo index IX_LichSu_IdPhieuGiamGia';
    END
    ELSE
    BEGIN
        PRINT 'Index IX_LichSu_IdPhieuGiamGia đã tồn tại';
    END
END
GO

PRINT 'Hoàn thành tạo bảng LichSuSuDungVoucher';

