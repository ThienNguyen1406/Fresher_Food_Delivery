# Hệ thống Truy xuất Nguồn gốc Sản phẩm với QR Code và Blockchain

## 📋 Tổng quan

Hệ thống này cho phép người dùng quét QR code trên sản phẩm để xem thông tin chi tiết về nguồn gốc xuất xứ, được lưu trữ an toàn trên blockchain.

## 🏗️ Kiến trúc hệ thống

### Backend (ASP.NET Core)

1. **Models**:
   - `ProductTraceability.cs`: Model lưu thông tin truy xuất nguồn gốc
   - `BlockchainRecord.cs`: Model cho blockchain record

2. **Services**:
   - `BlockchainService.cs`: Service để tương tác với blockchain
     - `SaveToBlockchainAsync()`: Lưu thông tin lên blockchain
     - `VerifyOnBlockchainAsync()`: Xác minh thông tin trên blockchain
     - `GetFromBlockchainAsync()`: Lấy thông tin từ blockchain

3. **Controllers**:
   - `TraceabilityController.cs`: API endpoints
     - `POST /api/Traceability`: Tạo thông tin truy xuất
     - `GET /api/Traceability/qr/{maTruyXuat}`: Quét QR code (trả về HTML)
     - `GET /api/Traceability/{maTruyXuat}`: Lấy thông tin truy xuất (JSON)
     - `GET /api/Traceability/verify/{transactionId}`: Verify trên blockchain

### Frontend (Flutter)

1. **Models**:
   - `ProductTraceability.dart`: Model cho thông tin truy xuất
   - `ProductTraceabilityResponse.dart`: Response model

2. **Services**:
   - `TraceabilityApi.dart`: API service để gọi backend

3. **Screens**:
   - `qr_scanner_page.dart`: Màn hình quét QR code
   - `traceability_detail_page.dart`: Màn hình hiển thị thông tin truy xuất

## 🗄️ Database

### Bảng ProductTraceability

Chạy script SQL: `csdl/CREATE_PRODUCT_TRACEABILITY_TABLE.sql`

Các trường chính:
- `MaTruyXuat`: Mã truy xuất duy nhất (QR Code ID)
- `MaSanPham`: Mã sản phẩm (Foreign Key)
- `NguonGoc`, `NhaSanXuat`, `DiaChiSanXuat`: Thông tin nguồn gốc
- `NgaySanXuat`, `NgayHetHan`: Thông tin ngày tháng
- `BlockchainHash`, `BlockchainTransactionId`: Thông tin blockchain

## 🚀 Cách sử dụng

### 1. Setup Database

```sql
-- Chạy script tạo bảng
USE FressFood;
-- Chạy file: csdl/CREATE_PRODUCT_TRACEABILITY_TABLE.sql
```

### 2. Tạo thông tin truy xuất cho sản phẩm

**API Request:**
```http
POST /api/Traceability
Content-Type: application/json

{
  "maSanPham": "SP001",
  "nguonGoc": "Việt Nam",
  "nhaSanXuat": "Công ty TNHH Gạo ST",
  "diaChiSanXuat": "Đồng Tháp, Việt Nam",
  "ngaySanXuat": "2024-01-01T00:00:00",
  "ngayHetHan": "2025-01-01T00:00:00",
  "nhaCungCap": "Nhà cung cấp ABC",
  "chungNhanChatLuong": "ISO 22000",
  "soChungNhan": "CN-2024-001"
}
```

**Response:**
```json
{
  "message": "Tạo thông tin truy xuất thành công",
  "maTruyXuat": "TX202401011200001",
  "qrCodeUrl": "https://api.example.com/api/Traceability/qr/TX202401011200001",
  "traceability": { ... }
}
```

### 3. Quét QR Code

**Cách 1: Qua Mobile App (Flutter)**
1. Mở app, vào màn hình quét QR
2. Quét QR code trên sản phẩm
3. Xem thông tin truy xuất chi tiết

**Cách 2: Qua Web Browser**
1. Quét QR code bằng camera điện thoại
2. Mở link trong browser
3. Xem thông tin truy xuất dạng HTML

### 4. Verify trên Blockchain

```http
GET /api/Traceability/verify/{transactionId}
```

## 🔗 Blockchain Integration

### Hiện tại (Simulation)

Service hiện tại mô phỏng việc lưu trữ blockchain:
- Tạo hash SHA256 từ dữ liệu
- Tạo transaction ID giả lập
- Lưu vào database

### Production (Đề xuất)

Để tích hợp blockchain thực tế, bạn có thể:

1. **Ethereum Smart Contract**:
   - Sử dụng Web3.js hoặc Ethers.js
   - Deploy smart contract để lưu trữ hash
   - Verify qua Etherscan API

2. **Hyperledger Fabric**:
   - Setup Hyperledger Fabric network
   - Tạo chaincode để lưu trữ dữ liệu
   - Query qua REST API

3. **IPFS (InterPlanetary File System)**:
   - Lưu trữ dữ liệu trên IPFS
   - Lưu IPFS hash trên blockchain
   - Verify qua IPFS gateway

4. **AWS Managed Blockchain**:
   - Sử dụng Amazon Managed Blockchain
   - Tích hợp với Lambda functions
   - Query qua API Gateway

## 📱 Flutter Setup

### Thêm dependencies

```yaml
dependencies:
  mobile_scanner: ^5.2.1  # Để quét QR code
  intl: ^0.19.0          # Để format ngày tháng
```

### Permissions (Android)

Thêm vào `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### Permissions (iOS)

Thêm vào `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>App cần quyền camera để quét QR code</string>
```

## 🎨 UI/UX Features

1. **QR Scanner Page**:
   - Camera preview với overlay hướng dẫn
   - Auto-detect QR code
   - Loading indicator khi xử lý

2. **Traceability Detail Page**:
   - Hiển thị thông tin sản phẩm
   - Thông tin nguồn gốc xuất xứ
   - Thông tin vận chuyển (nếu có)
   - Chứng nhận chất lượng (nếu có)
   - Badge "Đã xác minh trên Blockchain" nếu verified
   - Thông tin blockchain (Transaction ID, Hash)

## 🔒 Bảo mật

1. **Hash Verification**: Dữ liệu được hash SHA256 trước khi lưu blockchain
2. **Immutable Records**: Một khi đã lưu blockchain, không thể sửa đổi
3. **Transaction ID**: Mỗi record có transaction ID duy nhất để verify

## 📊 Flow Diagram

```
[Admin tạo sản phẩm] 
    ↓
[Tạo thông tin truy xuất] 
    ↓
[Lưu vào Database]
    ↓
[Lưu hash lên Blockchain]
    ↓
[Tạo QR Code với MaTruyXuat]
    ↓
[In QR Code lên sản phẩm]
    ↓
[User quét QR Code]
    ↓
[Lấy thông tin từ API]
    ↓
[Verify trên Blockchain]
    ↓
[Hiển thị thông tin]
```

## 🧪 Testing

### Test API với Postman/Swagger

1. Tạo traceability record
2. Lấy thông tin qua QR code
3. Verify blockchain transaction

### Test Flutter App

1. Tạo QR code test với mã truy xuất
2. Quét QR code
3. Kiểm tra hiển thị thông tin

## 📝 Notes

- **Blockchain Service**: Hiện tại là simulation, cần tích hợp blockchain network thực tế cho production
- **QR Code Format**: QR code chứa URL: `{baseUrl}/api/Traceability/qr/{maTruyXuat}`
- **Performance**: Cân nhắc cache blockchain verification results
- **Scalability**: Có thể sử dụng Redis để cache thông tin truy xuất thường dùng

## 🔮 Future Enhancements

1. Tích hợp blockchain network thực tế (Ethereum/Hyperledger)
2. Thêm tính năng upload ảnh chứng nhận
3. Thêm tính năng tracking lịch sử vận chuyển
4. Thêm notification khi có cập nhật thông tin
5. Thêm analytics để theo dõi số lần quét QR code

