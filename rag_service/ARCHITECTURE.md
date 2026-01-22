# Kiến trúc và Luồng hoạt động RAG Service

## 📋 Mục lục

1. [Tổng quan kiến trúc](#tổng-quan-kiến-trúc)
2. [Cấu trúc thư mục](#cấu-trúc-thư-mục)
3. [Luồng hoạt động](#luồng-hoạt-động)
4. [Các thành phần chính](#các-thành-phần-chính)
5. [Dependency Injection](#dependency-injection)
6. [Data Flow](#data-flow)

---

## 🏗️ Tổng quan kiến trúc

RAG Service được xây dựng theo **Clean Architecture** với các layer rõ ràng:

```
┌─────────────────────────────────────────────────┐
│           API Layer (FastAPI)                   │
│  - Routes: document, query, function, health    │
│  - Dependency Injection                        │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│         Core Layer (Business Logic)              │
│  - RAG Pipeline: Query → Retrieve → Rerank      │
│  - Ingest Pipeline: File → Chunks → Vector     │
│  - Prompt Builder                               │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│         Services Layer (Application)             │
│  - Document Processor                           │
│  - Embedding Service                            │
│  - Reranker Service                             │
│  - Function Handler                             │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│      Infrastructure Layer (External)            │
│  - Vector Store (Chroma)                        │
│  - LLM (OpenAI, Ollama)                         │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│         Domain Layer (Pure Entities)            │
│  - Document, Query, Answer                      │
│  - No framework dependencies                    │
└─────────────────────────────────────────────────┘
```

---

## 📁 Cấu trúc thư mục

```
rag_service/
├── app/
│   ├── main.py                    # FastAPI app - Entry point
│   │
│   ├── api/                       # API Layer
│   │   ├── deps.py                # Dependency Injection
│   │   └── routes/                # API Routes
│   │       ├── document.py        # Upload & ingest documents
│   │       ├── query.py           # Semantic search
│   │       ├── function.py        # Function calling
│   │       └── health.py          # Health check
│   │
│   ├── core/                      # Business Logic (RAG Brain)
│   │   ├── settings.py            # Configuration
│   │   ├── rag_pipeline.py        # Query → Retrieve → Rerank → Answer
│   │   ├── ingest_pipeline.py     # File → Chunks → Embeddings → Vector Store
│   │   └── prompt_builder.py      # Build prompts for LLM
│   │
│   ├── domain/                    # Pure Domain Entities (NO framework)
│   │   ├── document.py            # Document, DocumentChunk
│   │   ├── query.py               # Query entity
│   │   └── answer.py              # Answer, RetrievedChunk
│   │
│   ├── services/                  # Application Services (tổ chức theo chức năng)
│   │   ├── document/              # Xử lý tài liệu
│   │   │   ├── __init__.py
│   │   │   └── document_processor.py  # Extract text & chunk documents
│   │   ├── embedding/             # Tạo embeddings
│   │   │   ├── __init__.py
│   │   │   └── embedding_service.py   # Create embeddings (OpenAI/SentenceTransformer)
│   │   ├── reranker/              # Sắp xếp lại kết quả
│   │   │   ├── __init__.py
│   │   │   └── reranker_service.py    # Re-rank results (bge-reranker)
│   │   └── function/              # Function calling
│   │       ├── __init__.py
│   │       └── function_handler.py    # Execute function calls from AI
│   │
│   ├── infrastructure/            # External Systems
│   │   ├── vector_store/
│   │   │   ├── base.py            # VectorStore interface
│   │   │   └── chroma.py          # Chroma implementation
│   │   └── llm/
│   │       ├── openai.py          # OpenAI LLM (GPT-4.1)
│   │       └── ollama.py           # Ollama LLM (fallback)
│   │
│   └── utils/                     # Utilities
│       ├── text.py                # Text cleaning & chunking
│       └── tokenizer.py           # Token utilities
│
├── data/                          # Vector store data
│   └── vector_store/
│       └── chroma_db/             # Chroma database
│
├── requirements.txt               # Dependencies
└── README.md                      # Documentation
```

---

## 🔄 Luồng hoạt động

### 1. Luồng Ingest Document (Upload & Xử lý tài liệu)

```
User uploads file
       ↓
[API Route: POST /api/documents/upload]
       ↓
[IngestPipeline.process_and_store()]
       ↓
┌──────────────────────────────────────┐
│ 1. DocumentProcessor                 │
│    - Extract text from file          │
│    - Chunk text into small pieces    │
│    - Return: List[DocumentChunk]     │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 2. EmbeddingService                   │
│    - Create embeddings for chunks    │
│    - Use OpenAI (text-embedding-3)   │
│    - Return: List[embeddings]         │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 3. VectorStore (Chroma)               │
│    - Save chunks + embeddings        │
│    - Store metadata                  │
│    - Return: file_id                 │
└──────────────────────────────────────┘
       ↓
Response: {file_id, total_chunks, message}
```

**Chi tiết từng bước:**

1. **API Route** (`document.py`):
   - Nhận file từ user
   - Validate file type và size
   - Gọi `IngestPipeline`

2. **Document Processor**:
   - Đọc file (docx, pdf, txt, xlsx)
   - Trích xuất text
   - Chia nhỏ thành chunks (500 ký tự, overlap 50)
   - Tạo `DocumentChunk` entities

3. **Embedding Service**:
   - Tạo embedding vector cho mỗi chunk
   - Sử dụng OpenAI `text-embedding-3-large` (khuyến nghị)
   - Fallback sang Sentence Transformer nếu cần

4. **Vector Store**:
   - Lưu chunks + embeddings vào Chroma
   - Lưu metadata (file_id, file_name, upload_date)
   - Trả về file_id

---

### 2. Luồng Query (Tìm kiếm và Trả lời)

```
User asks question
       ↓
[API Route: POST /api/query/retrieve]
       ↓
[RAGPipeline.retrieve()]
       ↓
┌──────────────────────────────────────┐
│ 1. EmbeddingService                   │
│    - Create embedding for query       │
│    - Return: query_embedding          │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 2. VectorStore.search_similar()       │
│    - Search similar chunks           │
│    - Use cosine similarity           │
│    - Return: List[chunks] (top_k*2)   │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 3. RerankerService (Optional)         │
│    - Re-rank chunks by relevance      │
│    - Use bge-reranker                 │
│    - Return: Top K chunks             │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 4. Build Context                      │
│    - Combine chunks into context      │
│    - Format for LLM                   │
│    - Return: Answer object            │
└──────────────────────────────────────┘
       ↓
Response: {context, chunks, has_context}
```

**Chi tiết từng bước:**

1. **API Route** (`query.py`):
   - Nhận query từ user
   - Tạo `Query` domain object
   - Gọi `RAGPipeline`

2. **Embedding Query**:
   - Tạo embedding cho câu hỏi
   - Sử dụng cùng model như khi ingest

3. **Vector Search**:
   - Tìm kiếm các chunks tương tự
   - Sử dụng cosine similarity
   - Lấy nhiều hơn top_k (nếu có reranker)

4. **Reranking** (nếu bật):
   - Đánh giá lại độ liên quan
   - Sử dụng bge-reranker
   - Sắp xếp lại và lấy top_k

5. **Build Answer**:
   - Chuyển đổi thành `RetrievedChunk` entities
   - Xây dựng context string
   - Trả về `Answer` object

---

### 3. Luồng Function Calling

```
AI requests function call
       ↓
[API Route: POST /api/functions/execute]
       ↓
[FunctionHandler.execute_function()]
       ↓
┌──────────────────────────────────────┐
│ 1. Parse function name & arguments    │
│    - Validate function exists         │
│    - Extract arguments                 │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 2. Execute Function                   │
│    - Connect to SQL Server            │
│    - Execute SQL query                │
│    - Process results                  │
└──────────────────────────────────────┘
       ↓
┌──────────────────────────────────────┐
│ 3. Format Response                    │
│    - Convert to JSON                  │
│    - Handle errors                    │
└──────────────────────────────────────┘
       ↓
Response: {result, success, error}
```

**Các functions có sẵn:**

- `getProductExpiry` - Lấy hạn sử dụng sản phẩm
- `getProductsExpiringSoon` - Sản phẩm sắp hết hạn
- `getMonthlyRevenue` - Doanh thu theo tháng
- `getRevenueStatistics` - Thống kê doanh thu
- `getBestSellingProductImage` - Sản phẩm bán chạy
- `getProductInfo` - Thông tin sản phẩm
- `getOrderStatus` - Trạng thái đơn hàng
- `getCustomerOrders` - Đơn hàng của khách hàng
- `getTopProducts` - Top sản phẩm bán chạy
- `getInventoryStatus` - Trạng thái tồn kho
- `getCategoryProducts` - Sản phẩm theo danh mục

---

## 🧩 Các thành phần chính

### 1. Domain Layer (Pure Entities)

**Mục đích:** Định nghĩa các entities thuần, không phụ thuộc framework

- `DocumentChunk`: Chunk của document
  - `chunk_id`, `file_id`, `file_name`
  - `text`, `chunk_index`
  - `start_index`, `end_index`

- `Query`: Câu hỏi của user
  - `question`: Nội dung câu hỏi
  - `file_id`: Lọc theo file (optional)
  - `top_k`: Số lượng kết quả

- `Answer`: Kết quả tìm kiếm
  - `context`: Chuỗi context đã format
  - `chunks`: Danh sách `RetrievedChunk`
  - `has_context`: Có context hay không

### 2. Core Layer (Business Logic)

**Mục đích:** Chứa logic nghiệp vụ chính

- **RAGPipeline**: Xử lý query → retrieve → rerank → answer
- **IngestPipeline**: Xử lý file → chunks → embeddings → vector store
- **PromptBuilder**: Xây dựng prompts cho LLM
- **Settings**: Cấu hình toàn bộ ứng dụng

### 3. Services Layer (Application Services)

**Mục đích:** Các service xử lý nghiệp vụ cụ thể, tổ chức theo chức năng

- **DocumentProcessor** (`services/document/`): Trích xuất và chunk text từ các loại tài liệu
- **EmbeddingService** (`services/embedding/`): Tạo embeddings (OpenAI/SentenceTransformer)
- **RerankerService** (`services/reranker/`): Sắp xếp lại kết quả tìm kiếm (bge-reranker)
- **FunctionHandler** (`services/function/`): Thực thi function calls từ AI để lấy dữ liệu real-time từ database

### 4. Infrastructure Layer (External Systems)

**Mục đích:** Tích hợp với các hệ thống bên ngoài

- **VectorStore**: Interface và implementation (Chroma)
- **LLM**: Interface và implementation (OpenAI, Ollama)

### 5. API Layer (FastAPI Routes)

**Mục đích:** Expose API endpoints

- `/api/documents/*` - Quản lý documents
- `/api/query/*` - Tìm kiếm và retrieve
- `/api/functions/*` - Function calling
- `/api/health` - Health check

---

## 💉 Dependency Injection

Tất cả dependencies được quản lý qua `app/api/deps.py`:

```python
# Singleton pattern
_document_processor = None
_embedding_service = None
_reranker_service = None
_vector_store = None
_rag_pipeline = None
_ingest_pipeline = None

# Getter functions
def get_document_processor() -> DocumentProcessor
def get_embedding_service() -> EmbeddingService
def get_reranker_service() -> RerankerService
def get_vector_store() -> VectorStore
def get_rag_pipeline() -> RAGPipeline
def get_ingest_pipeline() -> IngestPipeline
```

**Lợi ích:**
- Singleton pattern: Chỉ 1 instance của mỗi service
- Dễ test: Có thể mock dependencies
- Lazy loading: Chỉ khởi tạo khi cần
- Centralized: Quản lý dependencies ở một nơi

---

## 📊 Data Flow

### Ingest Flow (Upload Document)

```
File (bytes)
    ↓
DocumentProcessor.process_document()
    ↓
List[DocumentChunk] (domain entities)
    ↓
EmbeddingService.create_embeddings()
    ↓
List[np.ndarray] (embeddings)
    ↓
VectorStore.save_chunks()
    ↓
Chroma Database (persisted)
```

### Query Flow (Search & Retrieve)

```
Query (string)
    ↓
EmbeddingService.create_embedding()
    ↓
np.ndarray (query embedding)
    ↓
VectorStore.search_similar()
    ↓
List[Dict] (chunks with similarity)
    ↓
RerankerService.rerank() (optional)
    ↓
List[Dict] (reranked chunks)
    ↓
Convert to RetrievedChunk (domain entities)
    ↓
Build Answer (context string)
    ↓
Answer (domain entity)
```

---

## 🔧 Cấu hình

Tất cả cấu hình trong `app/core/settings.py`:

### Vector Store
- `VECTOR_STORE_TYPE`: "chroma" (mặc định)
- `CHROMA_COLLECTION`: "documents"
- `CHROMA_PERSIST_DIR`: `data/vector_store/chroma_db`

### Embeddings
- `USE_OPENAI_EMBEDDINGS`: `true` (mặc định)
- `EMBEDDING_MODEL`: "text-embedding-3-large" (khuyến nghị)

### LLM
- `OPENAI_MODEL`: "gpt-4.1" (khuyến nghị)
- `USE_OLLAMA_FALLBACK`: `true` (mặc định)
- `OLLAMA_BASE_URL`: "http://localhost:11434"

### Reranker
- `USE_RERANKER`: `true` (mặc định)
- `RERANKER_MODEL`: "BAAI/bge-reranker-base"

### Document Processing
- `CHUNK_SIZE`: 500 (ký tự)
- `CHUNK_OVERLAP`: 50 (ký tự)

---

## 🚀 Cách chạy

```bash
# Chạy service
python app/main.py

# Hoặc với uvicorn
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# API sẽ chạy tại
http://localhost:8000
http://localhost:8000/docs (Swagger UI)
```

---

## 📝 Ghi chú

- **Clean Architecture**: Tách biệt rõ ràng giữa các layer
- **Dependency Injection**: Quản lý dependencies tập trung
- **Domain-Driven Design**: Domain entities thuần, không phụ thuộc framework
- **Singleton Pattern**: Mỗi service chỉ có 1 instance
- **Interface Segregation**: Mỗi interface có trách nhiệm rõ ràng

---

## 🔄 Luồng tương tác giữa các component

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTP Request
       ↓
┌──────────────────┐
│  API Routes       │
│  (FastAPI)        │
└──────┬────────────┘
       │
       ↓
┌──────────────────┐
│  Dependency      │
│  Injection       │
│  (deps.py)       │
└──────┬────────────┘
       │
       ├──→ RAGPipeline ──→ EmbeddingService
       │                    └──→ OpenAI API
       │
       ├──→ RAGPipeline ──→ VectorStore
       │                    └──→ Chroma DB
       │
       ├──→ RAGPipeline ──→ RerankerService
       │                    └──→ bge-reranker
       │
       └──→ IngestPipeline ──→ DocumentProcessor
                              └──→ Extract & Chunk
```

---

**Tài liệu này được cập nhật theo cấu trúc Clean Architecture mới nhất.**

