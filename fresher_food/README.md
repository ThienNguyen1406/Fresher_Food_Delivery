# 🍽️ Fresher Food - Ứng dụng Giao Đồ Ăn

Ứng dụng di động Flutter cho dịch vụ giao đồ ăn tươi sống với tích hợp AI chatbot hỗ trợ khách hàng.

## 📱 Tính năng chính

### 👤 Người dùng (User)
- 🏠 **Trang chủ**: Xem sản phẩm, danh mục, tìm kiếm
- 🛒 **Giỏ hàng**: Quản lý sản phẩm, áp dụng mã giảm giá
- ❤️ **Yêu thích**: Lưu sản phẩm yêu thích
- 💬 **Chat hỗ trợ**: Trò chuyện với AI chatbot, upload tài liệu để hỏi đáp
- 🎫 **Mã giảm giá**: Xem và sử dụng voucher
- 👤 **Tài khoản**: Quản lý thông tin cá nhân, đơn hàng

### 👨‍💼 Quản trị viên (Admin)
- 📊 **Dashboard**: Thống kê doanh thu, đơn hàng
- 📦 **Quản lý sản phẩm**: CRUD sản phẩm, upload hình ảnh
- 📁 **Quản lý danh mục**: Quản lý categories
- 📋 **Quản lý đơn hàng**: Xem và cập nhật trạng thái đơn hàng
- 👥 **Quản lý người dùng**: Quản lý tài khoản khách hàng
- 🎫 **Quản lý mã giảm giá**: Tạo và quản lý voucher
- 💬 **Quản lý chat**: Trả lời tin nhắn từ khách hàng
- 🎁 **Quản lý khuyến mãi**: Tạo chương trình khuyến mãi
- 🤖 **Quản lý RAG**: Upload và quản lý tài liệu cho AI

## 🛠️ Công nghệ sử dụng

### Core
- **Flutter**: `>=3.0.0 <4.0.0`
- **Dart**: SDK 3.0.0+

### State Management
- **Provider**: `^6.0.5` - Quản lý state toàn ứng dụng

### Backend Integration
- **HTTP**: `^1.1.0` - API calls
- **SharedPreferences**: `^2.1.0` - Local storage

### Firebase
- **Firebase Core**: `^3.15.2`
- **Firebase Messaging**: `^15.1.3` - Push notifications
- **Firebase Analytics**: `^11.3.3`
- **Firebase Auth**: `^5.3.1`
- **Cloud Firestore**: `^5.4.3`
- **Firebase Storage**: `^12.3.4`

### Payment
- **Flutter Stripe**: `^11.1.0` - Thanh toán online

### UI/UX
- **Iconsax**: `0.0.8` - Icon pack
- **Lottie**: `^3.3.2` - Animations
- **FL Chart**: `^0.70.0` - Charts & graphs
- **QR Flutter**: `^4.1.0` - QR code generation
- **Mobile Scanner**: `^5.2.1` - QR code scanning

### Utilities
- **Image Picker**: `^1.0.4` - Chọn ảnh từ gallery/camera
- **File Picker**: `^8.0.0` - Chọn file (PDF, DOCX, TXT, XLSX)
- **Intl**: `^0.20.2` - Internationalization
- **Diacritic**: `^0.1.3` - Xử lý dấu tiếng Việt
- **WebView Flutter**: `^4.4.2` - Hiển thị web content

## 📋 Yêu cầu hệ thống

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code với Flutter extension
- iOS: Xcode 14+ (cho macOS)
- Android: Android Studio với Android SDK

## 🚀 Cài đặt và Chạy

### 1. Clone repository
```bash
git clone <repository-url>
cd Fresher_Food_Delivery/fresher_food
```

### 2. Cài đặt dependencies
```bash
flutter pub get
```

### 3. Cấu hình Firebase

#### Android
1. Tải file `google-services.json` từ Firebase Console
2. Đặt vào `android/app/google-services.json`

#### iOS
1. Tải file `GoogleService-Info.plist` từ Firebase Console
2. Đặt vào `ios/Runner/GoogleService-Info.plist`

### 4. Cấu hình API Base URL

Cập nhật base URL trong file `lib/utils/constant.dart`:
```dart
String get baseUrl => 'https://your-api-url.com';
```

### 5. Cấu hình Stripe

Thêm Stripe publishable key vào backend API endpoint:
- Endpoint: `/api/Stripe/publishable-key`
- App sẽ tự động fetch key khi khởi động

### 6. Chạy ứng dụng

#### Debug mode
```bash
flutter run
```

#### Release mode
```bash
flutter run --release
```

#### Build APK (Android)
```bash
flutter build apk --release
```

#### Build IPA (iOS)
```bash
flutter build ios --release
```

## 📁 Cấu trúc dự án

```
lib/
├── main.dart                 # Entry point
├── models/                   # Data models
│   ├── Product.dart
│   ├── Cart.dart
│   ├── Order.dart
│   └── Chat.dart
├── services/                 # API services
│   └── api/
│       ├── product_api.dart
│       ├── cart_api.dart
│       ├── order_api.dart
│       ├── chat_api.dart
│       └── rag_api.dart
├── roles/
│   ├── user/                 # User features
│   │   ├── home/
│   │   ├── page/
│   │   │   ├── cart/
│   │   │   ├── favorite/
│   │   │   ├── chat/
│   │   │   ├── voucher/
│   │   │   └── account/
│   │   └── widgets/
│   └── admin/                # Admin features
│       ├── dashboard/
│       └── page/
│           ├── product_manager/
│           ├── category_manager/
│           ├── order_manager/
│           ├── user_manager/
│           ├── coupon_manager/
│           ├── chat_manager/
│           └── rag_manager/
├── providers/                # State providers
│   ├── theme_provider.dart
│   └── language_provider.dart
├── utils/                     # Utilities
│   ├── constant.dart
│   └── app_localizations.dart
└── widgets/                   # Shared widgets
    └── quick_chatbot_dialog.dart
```

## 🔧 Cấu hình

### Environment Variables

Tạo file `.env` (nếu cần) hoặc cập nhật trực tiếp trong code:
- API Base URL
- Firebase configuration
- Stripe keys (managed by backend)

### Localization

Ứng dụng hỗ trợ đa ngôn ngữ (Tiếng Việt/Tiếng Anh):
- File localization: `lib/utils/app_localizations.dart`
- Thêm ngôn ngữ mới trong `AppLocalizations` class

## 🎨 Theme & Customization

- **Theme Provider**: Quản lý Light/Dark mode
- **Language Provider**: Quản lý ngôn ngữ
- Custom colors và styles trong `lib/utils/constant.dart`

## 📱 Tính năng nổi bật

### AI Chatbot với RAG
- Chat trực tiếp với AI hỗ trợ khách hàng
- Upload tài liệu (PDF, DOCX, TXT, XLSX) để AI trả lời dựa trên nội dung
- Tích hợp với RAG service (Python backend)

### Thanh toán
- Stripe integration cho thanh toán online
- COD (Cash on Delivery)
- QR code thanh toán

### Push Notifications
- Firebase Cloud Messaging
- Thông báo đơn hàng, khuyến mãi

## 🐛 Debugging

### Enable debug logging
```dart
// Trong main.dart
void main() {
  runApp(MyApp());
  // Enable debug prints
}
```

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## 📦 Build & Deploy

### Android
1. Cập nhật version trong `pubspec.yaml`
2. Cập nhật `android/app/build.gradle`
3. Tạo keystore (nếu chưa có):
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
4. Build APK:
   ```bash
   flutter build apk --release
   ```
5. Build App Bundle:
   ```bash
   flutter build appbundle --release
   ```

### iOS
1. Cập nhật version trong `pubspec.yaml`
2. Cập nhật `ios/Runner/Info.plist`
3. Build:
   ```bash
   flutter build ios --release
   ```


