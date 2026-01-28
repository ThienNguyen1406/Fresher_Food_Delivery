# Image Embedding Pipeline Guide

## Tổng quan

Pipeline xử lý ảnh thành embedding vector và lưu vào Vector Database:

```
Image → Image Encoder (AI model) → Embedding Vector (mảng số) → Vector Database
```

## Kiến trúc

### 1. Image Embedding Service
- **File**: `app/services/image/image_embedding_service.py`
- **Chức năng**: Chuyển đổi ảnh thành embedding vector
- **Models hỗ trợ**:
  - CLIP (ViT-B/32) - Miễn phí, chạy local
  - OpenAI Vision API - Cần API key (tùy chọn)

### 2. Image Ingest Pipeline
- **File**: `app/core/image_ingest_pipeline.py`
- **Chức năng**: Xử lý ảnh và lưu vào vector store
- **Quy trình**:
  1. Nhận ảnh (bytes)
  2. Tạo embedding vector bằng Image Embedding Service
  3. Lưu embedding vào Vector Database

### 3. API Endpoints
- **File**: `app/api/routes/image.py`
- **Endpoints**:
  - `POST /api/images/upload` - Upload ảnh và tạo embedding
  - `POST /api/images/upload/batch` - Upload nhiều ảnh cùng lúc
  - `POST /api/images/search` - Tìm kiếm ảnh tương tự
  - `GET /api/images` - Lấy danh sách ảnh đã upload
  - `GET /api/images/{image_id}` - Lấy thông tin ảnh
  - `DELETE /api/images/{image_id}` - Xóa ảnh

## Cài đặt

### 1. Cài đặt dependencies

```bash
cd rag_service
pip install -r requirements.txt
```

**Lưu ý**: CLIP model cần cài từ GitHub:
```bash
pip install git+https://github.com/openai/CLIP.git
```

### 2. Cấu hình

File `.env` hoặc environment variables:
```env
# OpenAI (tùy chọn)
OPENAI_API_KEY=your-api-key-here
USE_OPENAI_EMBEDDINGS=true

# Vector Store
VECTOR_STORE=chroma
CHROMA_COLLECTION=documents
CHROMA_PERSIST_DIR=./data/vector_store/chroma_db
```

## Sử dụng

### 1. Upload ảnh (Python/API)

```python
import requests

# Upload ảnh
with open('image.jpg', 'rb') as f:
    files = {'file': f}
    response = requests.post(
        'http://localhost:8000/api/images/upload',
        files=files
    )
    result = response.json()
    print(f"Image ID: {result['image_id']}")
    print(f"Embedding dimension: {result['embedding_dimension']}")
```

### 2. Tìm kiếm ảnh tương tự (Python/API)

```python
import requests

# Tìm kiếm ảnh tương tự
with open('query_image.jpg', 'rb') as f:
    files = {'file': f}
    response = requests.post(
        'http://localhost:8000/api/images/search?top_k=5',
        files=files
    )
    results = response.json()
    print(f"Found {len(results['results'])} similar images")
    for result in results['results']:
        print(f"- {result['file_name']} (similarity: {result['similarity']})")
```

### 3. Sử dụng trong Flutter

```dart
import 'package:fresher_food/services/api/image_api.dart';
import 'dart:io';

// Upload ảnh
final imageApi = ImageApi();
final imageFile = File('/path/to/image.jpg');
final result = await imageApi.uploadImage(imageFile);

if (result != null) {
  print('Image ID: ${result['image_id']}');
  print('Embedding dimension: ${result['embedding_dimension']}');
}

// Tìm kiếm ảnh tương tự
final queryImage = File('/path/to/query_image.jpg');
final searchResults = await imageApi.searchSimilarImages(
  queryImage,
  topK: 5,
);

if (searchResults != null) {
  final results = searchResults['results'] as List;
  print('Found ${results.length} similar images');
  for (var result in results) {
    print('- ${result['file_name']} (similarity: ${result['similarity']})');
  }
}
```

## Workflow

### Upload và lưu ảnh

```
1. Client upload ảnh → POST /api/images/upload
2. Image Embedding Service tạo embedding vector
3. Lưu embedding vào Vector Database (Chroma)
4. Trả về image_id và embedding_dimension
```

### Tìm kiếm ảnh tương tự

```
1. Client upload ảnh query → POST /api/images/search
2. Image Embedding Service tạo embedding từ ảnh query
3. Vector Database tìm kiếm các embedding tương tự (cosine similarity)
4. Trả về danh sách ảnh tương tự với similarity scores
```

## Vector Database

Embedding vectors được lưu trong ChromaDB với cấu trúc:
- **ID**: `{image_id}-chunk-0`
- **Embedding**: Vector số (mảng float32)
- **Metadata**: 
  - `image_id`: ID của ảnh
  - `image_name`: Tên file
  - `file_type`: Loại file (jpg, png, etc.)
  - `upload_date`: Ngày upload
  - `content_type`: "image"

## Performance

- **CLIP Model**: 
  - Kích thước embedding: 512 dimensions
  - Thời gian xử lý: ~0.5-1s/ảnh (CPU), ~0.1-0.2s/ảnh (GPU)
  
- **Batch Processing**: 
  - Xử lý nhiều ảnh cùng lúc nhanh hơn
  - Khuyến nghị: batch size 8-16 ảnh

## Troubleshooting

### Lỗi: CLIP model không tải được
```bash
pip install git+https://github.com/openai/CLIP.git
pip install torch torchvision
```

### Lỗi: Out of memory
- Giảm batch size
- Sử dụng CPU thay vì GPU
- Resize ảnh trước khi upload (max 1024x1024)

### Lỗi: Vector Database không kết nối được
- Kiểm tra `CHROMA_PERSIST_DIR` có quyền ghi
- Xóa và tạo lại database nếu cần

## API Documentation

Xem chi tiết API tại: `http://localhost:8000/docs`

## Ví dụ sử dụng

Xem file `fresher_food/lib/services/api/image_api.dart` để biết cách sử dụng trong Flutter app.

