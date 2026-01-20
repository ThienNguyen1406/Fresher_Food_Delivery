# Hướng dẫn tích hợp RAG vào Frontend

## Đã hoàn thành

### 1. RAG API Service
- File: `lib/services/api/rag_api.dart`
- Các chức năng:
  - `uploadDocument()` - Upload file lên RAG service
  - `retrieveContext()` - Lấy context từ RAG
  - `askWithDocument()` - Hỏi đáp với document qua backend
  - `getDocuments()` - Lấy danh sách documents
  - `deleteDocument()` - Xóa document

### 2. Cập nhật Chat Detail Page
- File: `lib/roles/user/page/chat/chat_detail_page.dart`
- Tính năng mới:
  - ✅ Nút upload file trong AppBar
  - ✅ Nút attach file trong message input
  - ✅ Tự động hỏi đáp với RAG khi có file đã upload
  - ✅ Hiển thị trạng thái file đã chọn

### 3. Cấu hình
- File: `lib/utils/config.dart`
- Thêm `ragServiceUrl` để cấu hình RAG service URL

## Cài đặt

### 1. Cài đặt dependencies

```bash
cd fresher_food
flutter pub get
```

Package mới được thêm:
- `file_picker: ^8.0.0` - Để chọn file từ device

### 2. Cấu hình RAG Service URL

Trong file `lib/utils/config.dart`, cấu hình URL phù hợp:

```dart
// Android Emulator
static const String devRagServiceUrl = "http://10.0.2.2:8000";

// iOS Simulator hoặc Web
// static const String devRagServiceUrl = "http://localhost:8000";

// Physical Device (thay bằng IP máy tính của bạn)
// static const String devRagServiceUrl = "http://192.168.1.100:8000";
```

### 3. Chạy RAG Service

Đảm bảo Python RAG service đang chạy:

```bash
cd rag_service
python main.py
```

Service sẽ chạy tại `http://localhost:8000`

## Cách sử dụng

### 1. Upload File
1. Mở chat detail page
2. Nhấn nút 📎 (attach file) trong AppBar hoặc message input
3. Chọn file (PDF, DOCX, TXT, XLSX)
4. File sẽ được upload và xử lý tự động

### 2. Hỏi đáp với File
1. Sau khi upload file thành công, bạn sẽ thấy icon 📄 màu xanh
2. Gõ câu hỏi về nội dung file
3. Bot sẽ tự động trả lời dựa trên nội dung file đã upload

### 3. Bỏ chọn File
- Nhấn vào icon 📄 màu xanh trong AppBar để bỏ chọn file
- Sau đó chat sẽ hoạt động bình thường (không dùng RAG)

## API Endpoints được sử dụng

### Frontend → Python RAG Service
- `POST /api/documents/upload` - Upload file
- `POST /api/query/retrieve` - Retrieve context
- `GET /api/documents` - List documents
- `DELETE /api/documents/{file_id}` - Delete document

### Frontend → ASP.NET Backend
- `POST /api/Chat/ask-with-document` - Hỏi đáp với document (backend gọi RAG service)

## Lưu ý

1. **Android Emulator**: Sử dụng `10.0.2.2` thay vì `localhost`
2. **Physical Device**: Cần dùng IP máy tính (ví dụ: `192.168.1.100`)
3. **File Size**: Giới hạn 50MB
4. **File Types**: Chỉ hỗ trợ PDF, DOCX, TXT, XLSX

## Troubleshooting

### Lỗi "Cannot connect to RAG service"
- Kiểm tra RAG service có đang chạy không
- Kiểm tra URL trong `config.dart` có đúng không
- Kiểm tra firewall có chặn port 8000 không

### Lỗi "File upload failed"
- Kiểm tra file size (< 50MB)
- Kiểm tra file type (chỉ PDF, DOCX, TXT, XLSX)
- Kiểm tra kết nối mạng

### Lỗi import file_picker
- Chạy `flutter pub get`
- Restart IDE/editor
- Clean build: `flutter clean && flutter pub get`

