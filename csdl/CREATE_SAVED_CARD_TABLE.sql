-- =============================================
-- Script tạo bảng SavedCard để lưu thông tin thẻ đã thanh toán
-- =============================================

USE FressFood;
GO

-- Tạo bảng SavedCard nếu chưa tồn tại
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SavedCard]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[SavedCard](
        [Id] [varchar](50) NOT NULL,
        [MaTaiKhoan] [varchar](20) NOT NULL,
        [PaymentMethodId] [varchar](255) NOT NULL,
        [Last4] [varchar](4) NOT NULL,
        [Brand] [varchar](50) NOT NULL,
        [ExpMonth] [int] NOT NULL,
        [ExpYear] [int] NOT NULL,
        [CardholderName] [nvarchar](255) NULL,
        [NgayTao] [datetime] NOT NULL DEFAULT GETDATE(),
        [IsDefault] [bit] NOT NULL DEFAULT 0,
        
        CONSTRAINT [PK_SavedCard] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_SavedCard_NguoiDung] FOREIGN KEY([MaTaiKhoan])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE CASCADE
            ON UPDATE NO ACTION
    ) ON [PRIMARY];
    
    PRINT 'Bảng SavedCard đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng SavedCard đã tồn tại.';
    
    -- Thêm Foreign Key nếu chưa có
    IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_SavedCard_NguoiDung')
    BEGIN
        ALTER TABLE [dbo].[SavedCard] WITH CHECK ADD CONSTRAINT [FK_SavedCard_NguoiDung] 
            FOREIGN KEY([MaTaiKhoan])
            REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
            ON DELETE CASCADE
            ON UPDATE NO ACTION;
        PRINT 'Đã thêm Foreign Key FK_SavedCard_NguoiDung.';
    END
END
GO

