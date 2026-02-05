# 🍽️ Fresher Food Delivery - Được lên ý tưởng về hệ thống cung cấp nguồn thực phẩm sạch tới tay người tiêu dùng trong hoàn cảnh hiện nay có rất nhiều thực phẩm không rõ nguồn gốc được đưa ra thị trường ảnh hưởng sức khỏe người tiêu dùng

Hệ thống giao đồ ăn tươi sống hoàn chỉnh với ứng dụng di động Flutter, backend ASP.NET Core, và tích hợp AI chatbot hỗ trợ khách hàng sử dụng RAG (Retrieval Augmented Generation).
---

## 🎯 Tổng quan

**Fresher Food Delivery** là một hệ thống giao đồ ăn tươi sống đầy đủ tính năng, bao gồm:

- 📱 **Ứng dụng di động Flutter** - Giao diện người dùng và quản trị viên
- 🔧 **Backend API ASP.NET Core** - Xử lý logic nghiệp vụ và quản lý dữ liệu
- 🤖 **Python RAG Service** - AI chatbot với khả năng tìm kiếm thông tin từ tài liệu
- 💾 **SQL Server Database** - Lưu trữ dữ liệu

### Điểm nổi bật
- ✅ Thanh toán online qua Stripe
- ✅ AI Chatbot với RAG - Upload tài liệu và hỏi đáp thông minh
- ✅ Quản lý đơn hàng real-time
- ✅ Dashboard thống kê cho admin

---

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│  (User & Admin interfaces, State Management, UI/UX)         │
└───────────────────────┬─────────────────────────────────────┘
                        │ HTTP/REST API
                        │
┌───────────────────────▼─────────────────────────────────────┐
│              ASP.NET Core Backend API                        │
│  (Controllers, Services, Business Logic, Database Access)   │
└───────┬───────────────────────────────┬─────────────────────┘
        │                               │
        │                               │
┌───────▼────────┐            ┌────────▼──────────┐
│  SQL Server    │            │  Python RAG       │
│  Database      │            │  Service          │
│  (csdl/)       │            │  (FastAPI)        │
└────────────────┘            └───────────────────┘
                                        │
                              ┌─────────▼──────────┐
                              │  Vector Store      │
                              │  (Chroma DB)       │
                              │  OpenAI Embeddings│
                              └────────────────────┘
```

### Luồng dữ liệu chính

1. **User Flow**: Flutter App → ASP.NET API → SQL Server
2. **Chat Flow**: Flutter App → ASP.NET API → Python RAG Service → Vector Store → OpenAI
3. **Payment Flow**: Flutter App → ASP.NET API → Stripe API
4. **Notification Flow**: ASP.NET API → Firebase → Flutter App

---

## 📦 Các thành phần

### 1. Flutter Mobile App (`fresher_food/`)

**Công nghệ:**
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Provider (State Management)
- Firebase (Auth, Messaging, Analytics, Storage, Firestore)
- Stripe (Payment)

**Xem chi tiết:** [fresher_food/README.md](fresher_food/README.md)

### 2. ASP.NET Core Backend (`fresher_food_backend/`)

**Công nghệ:**
- .NET 8.0
- Entity Framework Core 9.0.9
- SQL Server
- Swagger/OpenAPI
- Stripe.NET
- Document processing (PDF, DOCX, XLSX)

**Xem chi tiết:** [fresher_food_backend/FressFood/HUONG_DAN_TICH_HOP_AI.md](fresher_food_backend/FressFood/HUONG_DAN_TICH_HOP_AI.md)

### 3. Python RAG Service (`rag_service/`)

**Công nghệ:**
- Python 3.8+
- FastAPI
- OpenAI API (Embeddings & LLM)
- ChromaDB (Vector Store)
- Sentence Transformers (Fallback)

### 4. Database (`csdl/`)

- SQL Server Database files (.mdf, .ldf)
- Schema cho toàn bộ hệ thống

---

## ✨ Tính năng

### 👤 Người dùng (User)

- 🏠 **Trang chủ**: Xem sản phẩm, danh mục, tìm kiếm, lọc
- 🛒 **Giỏ hàng**: Thêm/xóa sản phẩm, áp dụng mã giảm giá, tính toán tổng tiền
- ❤️ **Yêu thích**: Lưu và quản lý sản phẩm yêu thích
- 💬 **Chat hỗ trợ**: 
  - Trò chuyện với AI chatbot
  - Upload tài liệu (PDF, DOCX, TXT, XLSX) để AI trả lời dựa trên nội dung
  - Function calling - AI có thể truy vấn database real-time
- 🎫 **Mã giảm giá**: Xem và áp dụng voucher
- 📦 **Đơn hàng**: 
  - Đặt hàng, theo dõi trạng thái
  - Xem lịch sử đơn hàng
  - Theo dõi truy xuất nguồn gốc sản phẩm (Blockchain)
- 👤 **Tài khoản**: 
  - Quản lý thông tin cá nhân
  - Quản lý địa chỉ giao hàng
  - Đánh giá sản phẩm
  - Cài đặt (Theme, Ngôn ngữ)

### 👨‍💼 Quản trị viên (Admin)

- 📊 **Dashboard**: 
  - Thống kê doanh thu theo thời gian
  - Thống kê đơn hàng, sản phẩm, người dùng
  - Biểu đồ và báo cáo
- 📦 **Quản lý sản phẩm**: 
  - CRUD sản phẩm
  - Upload hình ảnh
  - Quản lý giá, mô tả, danh mục
- 📁 **Quản lý danh mục**: Tạo và quản lý categories
- 📋 **Quản lý đơn hàng**: 
  - Xem danh sách đơn hàng
  - Cập nhật trạng thái đơn hàng
  - Xuất hóa đơn
- 👥 **Quản lý người dùng**: Xem và quản lý tài khoản khách hàng
- 🎫 **Quản lý mã giảm giá**: Tạo và quản lý voucher, khuyến mãi
- 💬 **Quản lý chat**: Trả lời tin nhắn từ khách hàng
- 🎁 **Quản lý khuyến mãi**: Tạo chương trình khuyến mãi
- 🤖 **Quản lý RAG**: 
  - Upload tài liệu cho AI
  - Xem danh sách tài liệu đã upload
  - Xóa tài liệu

---

## 💻 Yêu cầu hệ thống

### Development Environment

- **Flutter**: SDK >= 3.0.0
- **Dart**: SDK >= 3.0.0
- **.NET**: SDK 8.0+
- **Python**: 3.8+
- **SQL Server**: 2019+ hoặc SQL Server Express
- **Node.js**: (cho Firebase CLI, nếu cần)

### Tools

- **IDE**: 
  - Android Studio / VS Code (cho Flutter)
  - Visual Studio / VS Code (cho .NET)
  - PyCharm / VS Code (cho Python)
- **Database Management**: SQL Server Management Studio (SSMS)
- **API Testing**: Postman / Swagger UI

### Services & APIs

- **Firebase Account**: Cho authentication, messaging, analytics
- **Stripe Account**: Cho thanh toán online
- **OpenAI API Key**: (Tùy chọn) Cho embeddings nhanh trong RAG service

---

## 🚀 Cài đặt và Cấu hình

### Bước 1: Clone Repository

```bash
git clone <repository-url>
cd Fresher_Food_Delivery
```

### Bước 2: Cấu hình Database

1. **Khôi phục SQL Server Database:**
   - Mở SQL Server Management Studio
   - Attach database từ thư mục `csdl/`:
     - `FressFood.mdf`
     - `FressFood_log.ldf`

2. **Cấu hình Connection String:**
   - Mở `fresher_food_backend/FressFood/appsettings.json`
   - Cập nhật connection string:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Server=localhost;Database=FressFood;Trusted_Connection=True;TrustServerCertificate=True;"
     }
   }
   ```

### Bước 3: Cấu hình Backend (ASP.NET Core)

1. **Cài đặt dependencies:**
   ```bash
   cd fresher_food_backend/FressFood
   dotnet restore
   ```

2. **Cấu hình appsettings.json:**
   - Copy `appsettings.example.json` thành `appsettings.json` (nếu chưa có)
   - Cập nhật các cấu hình cần thiết:
     - Connection Strings
     - Stripe Keys
     - OpenAI API Key (cho AI service)
     - RAG Service URL (mặc định: `http://localhost:8000`)

3. **Chạy migrations (nếu cần):**
   ```bash
   dotnet ef migrations add InitialCreate
   dotnet ef database update
   ```

### Bước 4: Cấu hình Python RAG Service

1. **Cài đặt Python dependencies:**
   ```bash
   cd rag_service
   
   # Tạo virtual environment (khuyến nghị)
   python -m venv venv
   
   # Activate virtual environment
   # Windows:
   .\venv\Scripts\activate
   # Linux/Mac:
   source venv/bin/activate
   
   # Cài đặt packages
   pip install -r requirements.txt
   ```

2. **Cấu hình Environment Variables:**
   ```bash
   # Tạo file .env
   cp .env.example .env
   
   # Thêm OpenAI API Key (khuyến nghị để embeddings nhanh)
   OPENAI_API_KEY=sk-your-openai-api-key-here
   
   # Cấu hình RAG Service URL (nếu khác mặc định)
   RAG_SERVICE_URL=http://localhost:8000
   ```

3. **Kiểm tra cấu hình:**
   ```bash
   python check_config.py
   ```

### Bước 5: Cấu hình Flutter App

1. **Cài đặt Flutter dependencies:**
   ```bash
   cd fresher_food
   flutter pub get
   ```

2. **Cấu hình Firebase:**
   
   **Android:**
   - Tải `google-services.json` từ Firebase Console
   - Đặt vào `android/app/google-services.json`
   
   **iOS:**
   - Tải `GoogleService-Info.plist` từ Firebase Console
   - Đặt vào `ios/Runner/GoogleService-Info.plist`

3. **Cấu hình API Base URL:**
   - Mở `lib/utils/constant.dart`
   - Cập nhật base URL:
   ```dart
   String get baseUrl => 'https://your-api-url.com';
   // Hoặc cho local development:
   String get baseUrl => 'http://10.0.2.2:5000'; // Android emulator
   String get baseUrl => 'http://localhost:5000'; // iOS simulator
   ```

4. **Cấu hình Stripe:**
   - Stripe publishable key sẽ được fetch tự động từ backend API
   - Đảm bảo backend đã cấu hình Stripe keys trong `appsettings.json`

---

## ▶️ Chạy dự án

### Thứ tự khởi động

1. **SQL Server Database** (phải chạy trước)
2. **Python RAG Service** (port 8000)
3. **ASP.NET Core Backend** (port 5000 hoặc 5001)
4. **Flutter Mobile App**

### 1. Khởi động Python RAG Service

```bash
cd rag_service

# Activate virtual environment
.\venv\Scripts\activate  # Windows
# hoặc
source venv/bin/activate  # Linux/Mac

# Chạy service
python main.py
# hoặc
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Service sẽ chạy tại: `http://localhost:8000`

**Kiểm tra:** Mở browser và truy cập `http://localhost:8000/docs` để xem Swagger UI

### 2. Khởi động ASP.NET Core Backend

```bash
cd fresher_food_backend/FressFood
dotnet run
```

Backend sẽ chạy tại:
- HTTP: `http://localhost:5000`
- HTTPS: `https://localhost:5001`

**Kiểm tra:** 
- Swagger UI: `https://localhost:5001/swagger`
- API Health: `https://localhost:5001/api/health`

### 3. Khởi động Flutter App

```bash
cd fresher_food

# Chạy trên Android
flutter run

# Chạy trên iOS (macOS only)
flutter run -d ios

# Chạy trên specific device
flutter devices  # Xem danh sách devices
flutter run -d <device-id>
```

### 4. Build Release

**Flutter App:**
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

**Backend:**
```bash
cd fresher_food_backend/FressFood
dotnet publish -c Release -o ./publish
```

---

## 📁 Cấu trúc dự án

```
Fresher_Food_Delivery/
│
├── fresher_food/                    # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart               # Entry point
│   │   ├── models/                 # Data models
│   │   ├── services/               # API services
│   │   ├── roles/
│   │   │   ├── user/              # User features
│   │   │   └── admin/             # Admin features
│   │   ├── providers/             # State management
│   │   ├── utils/                 # Utilities
│   │   └── widgets/               # Shared widgets
│   ├── android/                    # Android configuration
│   ├── ios/                        # iOS configuration
│   ├── pubspec.yaml               # Dependencies
│   └── README.md                  # Flutter app docs
│
├── fresher_food_backend/           # ASP.NET Core Backend
│   └── FressFood/
│       ├── Controllers/            # API Controllers
│       ├── Models/                 # Data models
│       ├── Services/               # Business logic services
│       ├── Program.cs             # Entry point
│       ├── appsettings.json       # Configuration
│       └── HUONG_DAN_TICH_HOP_AI.md
│
├── rag_service/                    # Python RAG Service
│   ├── app/
│   │   ├── main.py                # FastAPI app
│   │   ├── api/                   # API routes
│   │   ├── core/                  # Business logic
│   │   ├── domain/                # Domain entities
│   │   ├── services/              # Application services
│   │   └── infrastructure/        # External systems
│   ├── data/                      # Vector store data
│   ├── requirements.txt           # Python dependencies
│   ├── README.md                  # RAG service docs
│   ├── ARCHITECTURE.md            # Architecture docs
│   └── SETUP.md                   # Setup guide
│
├── csdl/                          # SQL Server Database
│   ├── FressFood.mdf              # Database file
│   └── FressFood_log.ldf          # Log file
│
└── README.md                      # This file
```

---

## 📚 API Documentation

### Backend API (ASP.NET Core)

**Swagger UI:** `https://localhost:5001/swagger`

**Các Controllers chính:**
- `UserController` - Quản lý người dùng
- `ProductController` - Quản lý sản phẩm
- `CategoryController` - Quản lý danh mục
- `CartsController` - Quản lý giỏ hàng
- `OrdersController` - Quản lý đơn hàng
- `ChatController` - Chat với AI
- `CouponController` - Quản lý mã giảm giá
- `StripeController` - Thanh toán Stripe
- `StatisticsController` - Thống kê
- `TraceabilityController` - Truy xuất nguồn gốc

### RAG Service API (Python FastAPI)

**Swagger UI:** `http://localhost:8000/docs`

**Các Endpoints chính:**
- `POST /api/documents/upload` - Upload tài liệu
- `POST /api/query/retrieve` - Tìm kiếm semantic
- `GET /api/documents` - Lấy danh sách tài liệu
- `DELETE /api/documents/{file_id}` - Xóa tài liệu
- `POST /api/functions/call` - Function calling
- `GET /api/health` - Health check

**Xem chi tiết:** [rag_service/README.md](rag_service/README.md)

---

## 🔧 Troubleshooting

### Lỗi kết nối Database

**Vấn đề:** Backend không kết nối được SQL Server

**Giải pháp:**
1. Kiểm tra SQL Server đang chạy
2. Kiểm tra connection string trong `appsettings.json`
3. Đảm bảo database đã được attach
4. Kiểm tra firewall và network

### RAG Service không khả dụng

**Vấn đề:** Backend không kết nối được Python RAG Service

**Giải pháp:**
1. Đảm bảo Python service đang chạy tại `http://localhost:8000`
2. Kiểm tra RAG Service URL trong `appsettings.json`
3. Kiểm tra firewall và CORS settings
4. Xem logs của Python service để debug

### Flutter App không kết nối được Backend

**Vấn đề:** App không gọi được API

**Giải pháp:**
1. Kiểm tra base URL trong `lib/utils/constant.dart`
2. Đối với Android emulator, dùng `http://10.0.2.2:5000`
3. Đối với iOS simulator, dùng `http://localhost:5000`
4. Đối với thiết bị thật, dùng IP máy tính: `http://192.168.x.x:5000`
5. Kiểm tra CORS settings trong backend

### Firebase không hoạt động

**Vấn đề:** Firebase features không hoạt động

**Giải pháp:**
1. Kiểm tra `google-services.json` (Android) hoặc `GoogleService-Info.plist` (iOS) đã được thêm chưa
2. Đảm bảo Firebase project đã được cấu hình đúng
3. Kiểm tra Firebase dependencies trong `pubspec.yaml`
4. Xem logs trong console để debug

### Stripe Payment không hoạt động

**Vấn đề:** Thanh toán Stripe thất bại

**Giải pháp:**
1. Kiểm tra Stripe keys trong backend `appsettings.json`
2. Đảm bảo publishable key được fetch thành công từ backend
3. Kiểm tra Stripe account và API keys
4. Xem logs trong backend và Flutter app

### OpenAI Embeddings chậm hoặc lỗi

**Vấn đề:** RAG service chậm hoặc không hoạt động

**Giải pháp:**
1. Kiểm tra OpenAI API Key trong `.env` file
2. Nếu không có API key, service sẽ dùng Sentence Transformer (chậm hơn)
3. Kiểm tra internet connection
4. Xem logs của Python service

---

### Coding Standards

- **Flutter/Dart**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **C#**: Follow [C# Coding Conventions](https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- **Python**: Follow [PEP 8](https://pep8.org/)

---

## 📄 License

Dự án này được phát triển cho mục đích học tập và nghiên cứu.

---

## 📞 Liên hệ

Nếu có câu hỏi hoặc vấn đề, vui lòng tạo issue trên repository.
Contact nhận db qua email nvt1406nvt@gmail.com

---

## 📖 Tài liệu tham khảo

- [Flutter Documentation](https://flutter.dev/docs)
- [ASP.NET Core Documentation](https://docs.microsoft.com/en-us/aspnet/core/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Stripe Documentation](https://stripe.com/docs)
- [OpenAI API Documentation](https://platform.openai.com/docs)

---

**Chúc bạn phát triển thành công! 🚀**

