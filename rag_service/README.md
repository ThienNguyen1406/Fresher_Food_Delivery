# RAG Service - Python FastAPI Service

Service Python xử lý RAG (Retrieval Augmented Generation) cho chatbot, hỗ trợ upload file, extract text, embedding và vector search.

## Tính năng

- ✅ Upload và xử lý file: docx, txt, pdf, xlsx
- ✅ Extract text và chunk thành các đoạn nhỏ
- ✅ Tạo embeddings bằng Sentence Transformer hoặc OpenAI
- ✅ Lưu trữ vectors trong Chroma hoặc Milvus
- ✅ Tìm kiếm semantic similarity
- ✅ API RESTful với FastAPI

## Cài đặt

1. **Cài đặt Python dependencies:**

**Cách 1: Cài đặt đầy đủ (nếu mạng ổn định)**
```bash
cd rag_service
pip install -r requirements.txt
```

**Cách 2: Cài đặt từng bước (khuyến nghị nếu gặp lỗi SSL/timeout)**
```bash
# Xem hướng dẫn chi tiết trong INSTALL.md
pip install fastapi uvicorn[standard] python-multipart pydantic
pip install python-docx PyPDF2 openpyxl
pip install "numpy>=1.24.0,<2.0.0" python-json-logger
pip install openai chromadb sentence-transformers
```

**Nếu gặp lỗi SSL/timeout, xem file [INSTALL.md](INSTALL.md) để biết thêm cách xử lý.**

2. **Cấu hình environment variables:**
```bash
cp .env.example .env
# Chỉnh sửa .env theo nhu cầu
```

3. **Chạy service:**
```bash
python main.py
# Hoặc
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

4. **Ingest documents (tùy chọn):**
```bash
# Ingest một file
python -m app.ingest path/to/file.docx

# Ingest tất cả files trong thư mục
python -m app.ingest path/to/directory --dir
```

Service sẽ chạy tại: `http://localhost:8000`

## API Endpoints

### 1. Upload Document
```http
POST /api/documents/upload
Content-Type: multipart/form-data
File: [your file]
```

Response:
```json
{
  "file_id": "DOC-xxxxx",
  "file_name": "document.docx",
  "total_chunks": 15,
  "message": "Document processed and stored successfully"
}
```

### 2. Retrieve Context
```http
POST /api/query/retrieve
Content-Type: application/json

{
  "question": "So sánh doanh thu 2024 với 2025",
  "file_id": "DOC-xxxxx",  // Optional
  "top_k": 5
}
```

Response:
```json
{
  "context": "Thông tin liên quan từ tài liệu:...",
  "chunks": [...],
  "has_context": true
}
```

### 3. Get All Documents
```http
GET /api/documents
```

### 4. Delete Document
```http
DELETE /api/documents/{file_id}
```

## Tích hợp với ASP.NET Backend

Cập nhật `ChatController.cs` để gọi Python RAG service:

```csharp
private readonly HttpClient _httpClient;
private readonly string _ragServiceUrl = "http://localhost:8000";

// Gọi Python service để upload document
var response = await _httpClient.PostAsync(
    $"{_ragServiceUrl}/upload-document",
    multipartContent
);
```

## Vector Store Options

### Chroma (Mặc định)
- Dễ setup, không cần server riêng
- Lưu trữ local trong `app/db/chroma_db`
- Phù hợp cho development và small-scale

### Milvus (Production)
- Cần cài đặt Milvus server riêng
- Hiệu năng tốt hơn cho large-scale
- Phù hợp cho production

## Embedding Models

### Sentence Transformer (Mặc định)
- Model: `paraphrase-multilingual-MiniLM-L12-v2`
- Hỗ trợ tiếng Việt
- Miễn phí, chạy local

### OpenAI Embeddings (Optional)
- Model: `text-embedding-3-small`
- Cần API key
- Chất lượng tốt hơn nhưng có phí

## Cấu trúc thư mục

```
rag_service/
├── main.py                 # Entry point
├── app/
│   ├── main.py            # FastAPI app
│   ├── ingest.py          # Script ingest documents
│   ├── api/               # API routes
│   │   ├── __init__.py
│   │   └── routes/
│   │       ├── document.py    # Document endpoints
│   │       └── query.py       # Query endpoints
│   ├── rag/               # RAG logic
│   │   ├── service.py         # RAG service chính
│   │   ├── processor.py       # Document processor
│   │   ├── embedding.py       # Embedding service
│   │   └── vector_store.py    # Vector store
│   ├── data/              # Data files (temporary)
│   └── db/                # Vector database storage
├── requirements.txt
├── .env.example
└── README.md
```

## Troubleshooting

1. **Lỗi import sentence_transformers:**
   - Cài đặt: `pip install sentence-transformers`

2. **Lỗi Chroma:**
   - Xóa thư mục `chroma_db` và chạy lại

3. **Memory issues với large files:**
   - Giảm `CHUNK_SIZE` trong `document_processor.py`
   - Sử dụng Milvus thay vì Chroma

