-- Script tạo bảng Chat và Message để hỗ trợ chat giữa user và admin
-- Chạy script này trên SQL Server để tạo bảng
-- Format khớp với database FressFood hiện tại
-- Lưu ý: MaTaiKhoan trong bảng NguoiDung là varchar(20), nên các foreign key phải khớp

USE FressFood;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Tạo bảng Chat (Conversation)
-- Lưu ý: Nếu bảng đã tồn tại từ script gốc, script này sẽ bỏ qua phần tạo bảng
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Chat]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Chat](
        [MaChat] [varchar](50) NOT NULL,
        [MaNguoiDung] [varchar](20) NOT NULL, -- User ID - khớp với NguoiDung.MaTaiKhoan (varchar(20))
        [MaAdmin] [varchar](20) NULL, -- Admin ID - khớp với NguoiDung.MaTaiKhoan (varchar(20))
        [TieuDe] [nvarchar](255) NULL, -- Tiêu đề cuộc trò chuyện
        [TrangThai] [nvarchar](50) NOT NULL, -- Open, Closed, Pending
        [NgayTao] [datetime] NOT NULL,
        [NgayCapNhat] [datetime] NULL,
        [TinNhanCuoi] [nvarchar](500) NULL, -- Tin nhắn cuối cùng để hiển thị preview
        [NgayTinNhanCuoi] [datetime] NULL,
        
        PRIMARY KEY CLUSTERED 
        (
            [MaChat] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY];

    -- Thêm default values (nếu chưa có)
    IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_Chat_TrangThai')
    BEGIN
        ALTER TABLE [dbo].[Chat] ADD DEFAULT (N'Open') FOR [TrangThai];
    END

    IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_Chat_NgayTao')
    BEGIN
        ALTER TABLE [dbo].[Chat] ADD DEFAULT (getdate()) FOR [NgayTao];
    END

    PRINT 'Bảng Chat đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng Chat đã tồn tại.';
    
    -- Sửa kiểu dữ liệu của các cột nếu chưa đúng (từ varchar(50) sang varchar(20))
    -- Kiểm tra và ALTER COLUMN nếu cần
    
    -- Kiểm tra và sửa MaNguoiDung
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'Chat' 
               AND COLUMN_NAME = 'MaNguoiDung' 
               AND CHARACTER_MAXIMUM_LENGTH = 50)
    BEGIN
        -- Xóa foreign key nếu tồn tại
        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Chat_NguoiDung')
        BEGIN
            ALTER TABLE [dbo].[Chat] DROP CONSTRAINT [FK_Chat_NguoiDung];
            PRINT 'Đã xóa Foreign Key FK_Chat_NguoiDung.';
        END
        
        -- Xóa index nếu tồn tại
        IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Chat_MaNguoiDung' AND object_id = OBJECT_ID('dbo.Chat'))
        BEGIN
            DROP INDEX [IX_Chat_MaNguoiDung] ON [dbo].[Chat];
            PRINT 'Đã xóa Index IX_Chat_MaNguoiDung.';
        END
        
        -- ALTER COLUMN
        ALTER TABLE [dbo].[Chat] ALTER COLUMN [MaNguoiDung] [varchar](20) NOT NULL;
        PRINT 'Đã sửa kiểu dữ liệu của cột MaNguoiDung từ varchar(50) sang varchar(20).';
    END
    
    -- Kiểm tra và sửa MaAdmin
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'Chat' 
               AND COLUMN_NAME = 'MaAdmin' 
               AND CHARACTER_MAXIMUM_LENGTH = 50)
    BEGIN
        -- Xóa index nếu tồn tại
        IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Chat_MaAdmin' AND object_id = OBJECT_ID('dbo.Chat'))
        BEGIN
            DROP INDEX [IX_Chat_MaAdmin] ON [dbo].[Chat];
            PRINT 'Đã xóa Index IX_Chat_MaAdmin.';
        END
        
        ALTER TABLE [dbo].[Chat] ALTER COLUMN [MaAdmin] [varchar](20) NULL;
        PRINT 'Đã sửa kiểu dữ liệu của cột MaAdmin từ varchar(50) sang varchar(20).';
    END
END
GO

-- Thêm Foreign Key và Index cho bảng Chat (nếu chưa có)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Chat_NguoiDung')
BEGIN
    ALTER TABLE [dbo].[Chat] WITH CHECK ADD CONSTRAINT [FK_Chat_NguoiDung] 
        FOREIGN KEY([MaNguoiDung])
        REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
        ON DELETE CASCADE;

    ALTER TABLE [dbo].[Chat] CHECK CONSTRAINT [FK_Chat_NguoiDung];
    PRINT 'Foreign Key FK_Chat_NguoiDung đã được tạo.';
END
ELSE
BEGIN
    PRINT 'Foreign Key FK_Chat_NguoiDung đã tồn tại.';
END
GO

-- Tạo Index cho bảng Chat (nếu chưa có)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Chat_MaNguoiDung' AND object_id = OBJECT_ID('dbo.Chat'))
BEGIN
    CREATE INDEX [IX_Chat_MaNguoiDung] ON [dbo].[Chat]([MaNguoiDung]);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Chat_MaAdmin' AND object_id = OBJECT_ID('dbo.Chat'))
BEGIN
    CREATE INDEX [IX_Chat_MaAdmin] ON [dbo].[Chat]([MaAdmin]);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Chat_TrangThai' AND object_id = OBJECT_ID('dbo.Chat'))
BEGIN
    CREATE INDEX [IX_Chat_TrangThai] ON [dbo].[Chat]([TrangThai]);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Chat_NgayTinNhanCuoi' AND object_id = OBJECT_ID('dbo.Chat'))
BEGIN
    CREATE INDEX [IX_Chat_NgayTinNhanCuoi] ON [dbo].[Chat]([NgayTinNhanCuoi] DESC);
END
GO

-- Tạo bảng Message (Tin nhắn)
-- Lưu ý: Nếu bảng đã tồn tại từ script gốc, script này sẽ bỏ qua phần tạo bảng
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Message]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Message](
        [MaTinNhan] [varchar](50) NOT NULL,
        [MaChat] [varchar](50) NOT NULL,
        [MaNguoiGui] [varchar](20) NOT NULL, -- ID người gửi - khớp với NguoiDung.MaTaiKhoan (varchar(20))
        [LoaiNguoiGui] [nvarchar](20) NOT NULL, -- 'User' hoặc 'Admin'
        [NoiDung] [nvarchar](max) NOT NULL,
        [DaDoc] [bit] NOT NULL, -- Đã đọc chưa
        [NgayGui] [datetime] NOT NULL,
        [NgayDoc] [datetime] NULL, -- Ngày đọc tin nhắn
        
        PRIMARY KEY CLUSTERED 
        (
            [MaTinNhan] ASC
        )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

    -- Thêm default values (nếu chưa có)
    IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_Message_DaDoc')
    BEGIN
        ALTER TABLE [dbo].[Message] ADD DEFAULT ((0)) FOR [DaDoc];
    END

    IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_Message_NgayGui')
    BEGIN
        ALTER TABLE [dbo].[Message] ADD DEFAULT (getdate()) FOR [NgayGui];
    END

    PRINT 'Bảng Message đã được tạo thành công!';
END
ELSE
BEGIN
    PRINT 'Bảng Message đã tồn tại.';
    
    -- Sửa kiểu dữ liệu của cột MaNguoiGui nếu chưa đúng (từ varchar(50) sang varchar(20))
    IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'Message' 
               AND COLUMN_NAME = 'MaNguoiGui' 
               AND CHARACTER_MAXIMUM_LENGTH = 50)
    BEGIN
        -- Xóa foreign key nếu tồn tại
        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Message_NguoiDung')
        BEGIN
            ALTER TABLE [dbo].[Message] DROP CONSTRAINT [FK_Message_NguoiDung];
            PRINT 'Đã xóa Foreign Key FK_Message_NguoiDung.';
        END
        
        -- Xóa index nếu tồn tại
        IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Message_MaNguoiGui' AND object_id = OBJECT_ID('dbo.Message'))
        BEGIN
            DROP INDEX [IX_Message_MaNguoiGui] ON [dbo].[Message];
            PRINT 'Đã xóa Index IX_Message_MaNguoiGui.';
        END
        
        -- ALTER COLUMN
        ALTER TABLE [dbo].[Message] ALTER COLUMN [MaNguoiGui] [varchar](20) NOT NULL;
        PRINT 'Đã sửa kiểu dữ liệu của cột MaNguoiGui từ varchar(50) sang varchar(20).';
    END
END
GO

-- Thêm Foreign Key cho bảng Message (nếu chưa có)
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Message_Chat')
BEGIN
    ALTER TABLE [dbo].[Message] WITH CHECK ADD CONSTRAINT [FK_Message_Chat] 
        FOREIGN KEY([MaChat])
        REFERENCES [dbo].[Chat] ([MaChat])
        ON DELETE CASCADE;

    ALTER TABLE [dbo].[Message] CHECK CONSTRAINT [FK_Message_Chat];
    PRINT 'Foreign Key FK_Message_Chat đã được tạo.';
END
ELSE
BEGIN
    PRINT 'Foreign Key FK_Message_Chat đã tồn tại.';
END
GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Message_NguoiDung')
BEGIN
    ALTER TABLE [dbo].[Message] WITH CHECK ADD CONSTRAINT [FK_Message_NguoiDung] 
        FOREIGN KEY([MaNguoiGui])
        REFERENCES [dbo].[NguoiDung] ([MaTaiKhoan])
        ON DELETE NO ACTION;

    ALTER TABLE [dbo].[Message] CHECK CONSTRAINT [FK_Message_NguoiDung];
    PRINT 'Foreign Key FK_Message_NguoiDung đã được tạo.';
END
ELSE
BEGIN
    PRINT 'Foreign Key FK_Message_NguoiDung đã tồn tại.';
END
GO

-- Tạo Index cho bảng Message (nếu chưa có)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Message_MaChat' AND object_id = OBJECT_ID('dbo.Message'))
BEGIN
    CREATE INDEX [IX_Message_MaChat] ON [dbo].[Message]([MaChat]);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Message_MaNguoiGui' AND object_id = OBJECT_ID('dbo.Message'))
BEGIN
    CREATE INDEX [IX_Message_MaNguoiGui] ON [dbo].[Message]([MaNguoiGui]);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Message_NgayGui' AND object_id = OBJECT_ID('dbo.Message'))
BEGIN
    CREATE INDEX [IX_Message_NgayGui] ON [dbo].[Message]([NgayGui] DESC);
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Message_DaDoc' AND object_id = OBJECT_ID('dbo.Message'))
BEGIN
    CREATE INDEX [IX_Message_DaDoc] ON [dbo].[Message]([DaDoc]);
END
GO

PRINT 'Script hoàn tất!';
GO

