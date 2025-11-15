# Hướng dẫn Attach Database FressFood.mdf

## Bước 1: Kiểm tra file database
- File database: `D:\Fresher_Food_Delivery\csdl\FressFood.mdf`
- Đảm bảo SQL Server service account có quyền đọc file này

## Bước 2: Mở SQL Server Management Studio (SSMS)
1. Kết nối đến server: `THIENNGUYEN\SQLEXPRESS`
2. Đăng nhập với user `sa` hoặc Windows Authentication

## Bước 3: Chạy script attach database

### Cách 1: Sử dụng script đơn giản
Mở file `ATTACH_DATABASE.sql` và chạy trong SSMS

### Cách 2: Sử dụng script với .ldf (nếu có)
Mở file `ATTACH_DATABASE_WITH_LDF.sql` và chạy trong SSMS

### Cách 3: Attach thủ công qua SSMS
1. Right-click vào "Databases" → "Attach..."
2. Click "Add..." và chọn file: `D:\Fresher_Food_Delivery\csdl\FressFood.mdf`
3. Đổi tên database thành "FoodOrder" (nếu cần)
4. Click "OK"

## Bước 4: Kiểm tra database đã attach thành công
```sql
USE FoodOrder;
GO

-- Xem danh sách các bảng
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';
GO
```

## Lưu ý quan trọng:
1. **Nếu database "FoodOrder" đã tồn tại**: 
   - Có thể drop database cũ trước: `DROP DATABASE FoodOrder;`
   - Hoặc đổi tên database khi attach

2. **Quyền truy cập file**:
   - SQL Server service account cần có quyền đọc file `.mdf`
   - Nếu lỗi quyền, right-click file → Properties → Security → Add SQL Server service account

3. **Sau khi attach**:
   - Kiểm tra connection string trong `appsettings.json` đã đúng
   - Restart backend để áp dụng thay đổi

## Kiểm tra kết nối:
Sau khi attach, test connection bằng cách:
```sql
USE FoodOrder;
SELECT COUNT(*) FROM NguoiDung; -- Kiểm tra bảng NguoiDung
```

