# RAG Service - Python FastAPI Service

Service Python xử lý RAG (Retrieval Augmented Generation) cho chatbot, hỗ trợ upload file, extract text, embedding và vector search.

📖 **Xem [ARCHITECTURE.md](ARCHITECTURE.md) để hiểu rõ về cấu trúc và luồng hoạt động.**  
📖 **Xem [SETUP.md](SETUP.md) để biết chi tiết về cài đặt và cấu hình.**

## ⚠️ QUAN TRỌNG: Cấu hình OpenAI API Key

**Để sử dụng embeddings nhanh (khuyến nghị), bạn CẦN cấu hình OpenAI API Key:**

```bash
# Tạo file .env
cp .env.example .env

# Thêm OpenAI API Key vào .env
OPENAI_API_KEY=sk-your-openai-api-key-here
```

**Kiểm tra cấu hình:**
```bash
python check_config.py
```

Nếu không có OpenAI API Key, hệ thống sẽ dùng Sentence Transformer (chậm hơn nhiều).

## Tính năng

- ✅ Upload và xử lý file: docx, txt, pdf, xlsx
- ✅ Extract text và chunk thành các đoạn nhỏ
- ✅ Tạo embeddings bằng Sentence Transformer hoặc OpenAI
- ✅ **Upload và xử lý ảnh: jpg, png, gif, webp, bmp**
- ✅ **Tạo image embeddings bằng CLIP model**
- ✅ **Tìm kiếm ảnh tương tự (image similarity search)**
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

**3. Cài đặt CLIP model cho image embeddings (BẮT BUỘC nếu dùng image features):**

```bash
# Windows (với venv)
venv\Scripts\python.exe -m pip install git+https://github.com/openai/CLIP.git

# Linux/Mac (với venv)
venv/bin/pip install git+https://github.com/openai/CLIP.git

# Hoặc dùng script có sẵn:
# Windows
install_clip.bat

# Linux/Mac
chmod +x install_clip.sh
./install_clip.sh
```

**Lưu ý:** CLIP model (~150MB) sẽ được tải về lần đầu tiên khi chạy service.

2. **Cấu hình environment variables (QUAN TRỌNG):**

**⚠️ BẮT BUỘC: Cấu hình OpenAI API Key để sử dụng embeddings nhanh**

```bash
# Tạo file .env từ template
cp .env.example .env

# Chỉnh sửa .env và thêm OpenAI API Key
# Lấy API key tại: https://platform.openai.com/api-keys
OPENAI_API_KEY=sk-your-openai-api-key-here
```

**Nếu không có OpenAI API Key:**
- Hệ thống sẽ tự động dùng Sentence Transformer (chậm hơn nhiều)
- Xem [SETUP.md](SETUP.md) để biết chi tiết

3. **Chạy service:**
```bash
# Cách 1: Chạy từ main.py ở root (khuyến nghị)
python main.py

# Cách 2: Chạy từ app/main.py (phải ở thư mục root)
python app/main.py

# Cách 3: Sử dụng uvicorn trực tiếp
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

### Chroma (Mặc định - Khuyến nghị)
- Dễ setup, không cần server riêng
- Lưu trữ local trong `data/vector_store/chroma_db`
- Phù hợp cho development và production nhỏ
- Có thể nâng cấp lên Qdrant sau

### Qdrant (Production - Tùy chọn)
- Cần cài đặt Qdrant server riêng
- Hiệu năng tốt hơn cho large-scale
- Phù hợp cho production lớn

## Embedding Models

### OpenAI Embeddings (Khuyến nghị - Mặc định)
- Model: `text-embedding-3-large`
- Cần API key
- Chất lượng tốt nhất

### Sentence Transformer (Fallback)
- Model: `paraphrase-multilingual-MiniLM-L12-v2`
- Hỗ trợ tiếng Việt
- Miễn phí, chạy local
- Tự động fallback nếu OpenAI không khả dụng

## Cấu trúc thư mục

```
rag_service/
├── app/
│   ├── main.py            # FastAPI app - Entry point
│   ├── api/               # API Layer (FastAPI routes)
│   │   ├── deps.py        # Dependency injection
│   │   └── routes/
│   │       ├── document.py    # Upload & ingest document
│   │       ├── query.py        # Semantic search
│   │       ├── function.py     # Function calling
│   │       └── health.py       # Health check
│   ├── core/              # Business logic (RAG brain)
│   │   ├── rag_pipeline.py     # Query → retrieve → answer
│   │   ├── ingest_pipeline.py  # File → chunks → vector
│   │   ├── prompt_builder.py   # Build prompts for LLM
│   │   └── settings.py         # Configuration
│   ├── domain/            # Pure domain entities (NO framework)
│   │   ├── document.py         # Document, Chunk entity
│   │   ├── query.py            # Query entity
│   │   └── answer.py           # Answer entity
│   ├── services/          # Application services
│   │   ├── document_processor.py
│   │   ├── embedding_service.py
│   │   ├── reranker_service.py
│   │   └── function_handler.py
│   ├── infrastructure/    # External systems
│   │   ├── vector_store/
│   │   │   ├── base.py         # Base interface
│   │   │   └── chroma.py       # Chroma implementation
│   │   └── llm/
│   │       ├── openai.py       # OpenAI LLM
│   │       └── ollama.py        # Ollama fallback
│   └── utils/             # Utilities
│       ├── text.py
│       └── tokenizer.py
├── data/                  # Vector store data
│   └── vector_store/
├── db/                    # Legacy Chroma DB (có thể xóa sau)
├── requirements.txt
├── requirements-minimal.txt
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


run app
-  .\venv\Scripts\activate
- python main.py


