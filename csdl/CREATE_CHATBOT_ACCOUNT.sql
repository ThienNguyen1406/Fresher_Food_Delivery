-- =============================================
-- Script tạo tài khoản Chatbot tự động
-- Ngày tạo: 2025-01-11
-- =============================================

USE FressFood;
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Kiểm tra và tạo tài khoản Chatbot
IF NOT EXISTS (SELECT * FROM NguoiDung WHERE MaTaiKhoan = 'BOT')
BEGIN
    INSERT INTO NguoiDung (MaTaiKhoan, TenNguoiDung, MatKhau, Email, HoTen, VaiTro)
    VALUES (
        'BOT',
        'Chatbot',
        'BOT_PASSWORD_NOT_USED', -- Mật khẩu không được sử dụng
        'bot@fresherfood.com',
        N'Trợ lý tự động',
        'Admin' -- Vai trò Admin để hiển thị như admin
    );
    
    PRINT 'Đã tạo tài khoản Chatbot thành công!';
END
ELSE
BEGIN
    PRINT 'Tài khoản Chatbot đã tồn tại.';
END
GO

-- Kiểm tra kết quả
SELECT 
    MaTaiKhoan,
    TenNguoiDung,
    HoTen,
    VaiTro,
    Email
FROM NguoiDung
WHERE MaTaiKhoan = 'BOT';
GO

PRINT '';
PRINT '=============================================';
PRINT 'Hoàn tất tạo tài khoản Chatbot!';
PRINT 'Mã tài khoản: BOT';
PRINT 'Tên: Trợ lý tự động';
PRINT '=============================================';
GO
