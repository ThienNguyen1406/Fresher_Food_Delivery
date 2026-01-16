-- Cập nhật số lượng sản phẩm trong giỏ hàng
-- Cú pháp: UPDATE số lượng của sản phẩm trong giỏ hàng của một user

-- Ví dụ 1: Cập nhật số lượng sản phẩm cụ thể trong giỏ hàng của user
UPDATE SanPham_GioHang
SET SoLuong = 5  -- Số lượng mới
WHERE MaGioHang IN (
    SELECT MaGioHang 
    FROM GioHang 
    WHERE MaTaiKhoan = 'USER_ID_HERE'  -- Thay bằng mã tài khoản thực tế
)
AND MaSanPham = 'SP007252';  -- Thay bằng mã sản phẩm thực tế

-- Ví dụ 2: Cập nhật số lượng cho tất cả sản phẩm trong giỏ hàng của user
UPDATE SanPham_GioHang
SET SoLuong = 3  -- Số lượng mới
WHERE MaGioHang IN (
    SELECT MaGioHang 
    FROM GioHang 
    WHERE MaTaiKhoan = 'USER_ID_HERE'  -- Thay bằng mã tài khoản thực tế
);

-- Ví dụ 3: Cập nhật số lượng cho nhiều sản phẩm cùng lúc
UPDATE SanPham_GioHang
SET SoLuong = CASE 
    WHEN MaSanPham = 'SP007252' THEN 2
    WHEN MaSanPham = 'SP035953' THEN 3
    ELSE SoLuong
END
WHERE MaGioHang IN (
    SELECT MaGioHang 
    FROM GioHang 
    WHERE MaTaiKhoan = 'USER_ID_HERE'  -- Thay bằng mã tài khoản thực tế
)
AND MaSanPham IN ('SP007252', 'SP035953');

-- Ví dụ 4: Tăng số lượng thêm 1
UPDATE SanPham_GioHang
SET SoLuong = SoLuong + 1
WHERE MaGioHang IN (
    SELECT MaGioHang 
    FROM GioHang 
    WHERE MaTaiKhoan = 'USER_ID_HERE'
)
AND MaSanPham = 'SP007252';

-- Ví dụ 5: Giảm số lượng đi 1 (chỉ khi số lượng > 1)
UPDATE SanPham_GioHang
SET SoLuong = SoLuong - 1
WHERE MaGioHang IN (
    SELECT MaGioHang 
    FROM GioHang 
    WHERE MaTaiKhoan = 'USER_ID_HERE'
)
AND MaSanPham = 'SP007252'
AND SoLuong > 1;

-- Kiểm tra kết quả sau khi update
SELECT 
    gh.MaTaiKhoan,
    spgh.MaSanPham,
    sp.TenSanPham,
    spgh.SoLuong,
    sp.GiaBan
FROM SanPham_GioHang spgh
INNER JOIN GioHang gh ON spgh.MaGioHang = gh.MaGioHang
INNER JOIN SanPham sp ON spgh.MaSanPham = sp.MaSanPham
WHERE gh.MaTaiKhoan = 'USER_ID_HERE';  -- Thay bằng mã tài khoản thực tế
