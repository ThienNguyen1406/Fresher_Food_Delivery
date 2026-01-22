# Hướng dẫn Cài đặt và Cấu hình RAG Service

## 📋 Mục lục

1. [Cài đặt Dependencies](#cài-đặt-dependencies)
2. [Cấu hình Environment Variables](#cấu-hình-environment-variables)
3. [Kiểm tra Cấu hình](#kiểm-tra-cấu-hình)
4. [Chạy Service](#chạy-service)

---

## 🔧 Cài đặt Dependencies

### Cách 1: Cài đặt đầy đủ (Khuyến nghị)

```bash
cd rag_service
pip install -r requirements.txt
```

### Cách 2: Cài đặt từng bước (Nếu gặp lỗi SSL/timeout)

```bash
# Bước 1: Core dependencies
pip install fastapi uvicorn[standard] python-multipart pydantic

# Bước 2: Document processing
pip install python-docx PyPDF2 openpyxl

# Bước 3: Utilities
pip install "numpy>=1.24.0,<2.0.0"

# Bước 4: OpenAI (nếu dùng OpenAI embeddings)
pip install openai

# Bước 5: ChromaDB
pip install chromadb

# Bước 6: Sentence Transformers (nếu không dùng OpenAI)
pip install sentence-transformers

# Bước 7: Reranker
pip install sentence-transformers  # Đã cài ở bước 6

# Bước 8: Function calling
pip install pyodbc httpx
```

---

## ⚙️ Cấu hình Environment Variables

### Bước 1: Tạo file `.env`

```bash
# Copy file example
cp .env.example .env

# Hoặc tạo file mới
touch .env
```

### Bước 2: Cấu hình OpenAI API Key (QUAN TRỌNG)

**Để sử dụng OpenAI embeddings (khuyến nghị):**

1. Lấy API key từ: https://platform.openai.com/api-keys
2. Thêm vào file `.env`:

```env
OPENAI_API_KEY=sk-your-actual-api-key-here
USE_OPENAI_EMBEDDINGS=true
EMBEDDING_MODEL=text-embedding-3-large
```

**Nếu không có OpenAI API key:**

Hệ thống sẽ tự động fallback sang Sentence Transformer (chậm hơn):

```env
USE_OPENAI_EMBEDDINGS=false
EMBEDDING_MODEL=paraphrase-multilingual-MiniLM-L12-v2
```

### Bước 3: Cấu hình các biến khác (Tùy chọn)

Xem file `.env.example` để biết tất cả các biến có thể cấu hình.

---

## ✅ Kiểm tra Cấu hình

### Kiểm tra OpenAI API Key

```bash
# Windows PowerShell
$env:OPENAI_API_KEY="sk-your-key-here"
python -c "import os; print('OK' if os.getenv('OPENAI_API_KEY') else 'MISSING')"

# Linux/Mac
export OPENAI_API_KEY="sk-your-key-here"
python -c "import os; print('OK' if os.getenv('OPENAI_API_KEY') else 'MISSING')"
```

### Kiểm tra trong code

Tạo file `check_config.py`:

```python
from app.core.settings import Settings

print("=== RAG Service Configuration ===")
print(f"OpenAI API Key: {'✅ Set' if Settings.OPENAI_API_KEY else '❌ Missing'}")
print(f"Use OpenAI Embeddings: {Settings.USE_OPENAI_EMBEDDINGS}")
print(f"Embedding Model: {Settings.EMBEDDING_MODEL}")
print(f"LLM Model: {Settings.OPENAI_MODEL}")
print(f"Vector Store: {Settings.VECTOR_STORE_TYPE}")
print(f"Use Reranker: {Settings.USE_RERANKER}")
```

Chạy:
```bash
python check_config.py
```

---

## 🚀 Chạy Service

### Cách 1: Chạy từ main.py ở root (Khuyến nghị)

```bash
# Đảm bảo bạn đang ở thư mục rag_service/
python main.py
```

### Cách 2: Chạy với uvicorn

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Cách 3: Chạy với environment variables

```bash
# Windows PowerShell
$env:OPENAI_API_KEY="sk-your-key"; python app/main.py

# Linux/Mac
OPENAI_API_KEY="sk-your-key" python app/main.py
```

---

## 🔍 Troubleshooting

### Vấn đề: "OpenAI embeddings chưa được cấu hình"

**Nguyên nhân:** Chưa set `OPENAI_API_KEY` environment variable

**Giải pháp:**

1. **Cách 1: Tạo file `.env`**
   ```bash
   # Tạo file .env trong thư mục rag_service
   echo OPENAI_API_KEY=sk-your-key-here > .env
   ```

2. **Cách 2: Set environment variable trực tiếp**
   ```bash
   # Windows PowerShell
   $env:OPENAI_API_KEY="sk-your-key-here"
   
   # Linux/Mac
   export OPENAI_API_KEY="sk-your-key-here"
   ```

3. **Cách 3: Sử dụng Sentence Transformer (không cần API key)**
   ```bash
   # Set trong .env
   USE_OPENAI_EMBEDDINGS=false
   ```

### Vấn đề: Upload file chậm

**Nguyên nhân có thể:**
- Đang dùng Sentence Transformer (chậm hơn OpenAI)
- File quá lớn
- Network chậm khi gọi OpenAI API

**Giải pháp:**
- Sử dụng OpenAI embeddings (nhanh hơn 50-100 lần)
- Giảm `CHUNK_SIZE` trong settings
- Kiểm tra kết nối mạng

### Vấn đề: "get_all_documents" trả về rỗng

**Nguyên nhân:** Chưa upload file nào hoặc dữ liệu ở database cũ

**Giải pháp:**
1. Upload file qua `POST /api/documents/upload`
2. Kiểm tra debug endpoint: `GET /api/documents/debug`

---

## 📝 Lưu ý

1. **OpenAI API Key là BẮT BUỘC** nếu muốn sử dụng:
   - OpenAI embeddings (text-embedding-3-large) - Khuyến nghị
   - OpenAI LLM (GPT-4.1)

2. **Sentence Transformer** là fallback miễn phí nhưng:
   - Chậm hơn nhiều (không có batch API)
   - Cần tải model về lần đầu (có thể mất vài phút)
   - Chất lượng embeddings thấp hơn OpenAI

3. **File `.env`** nên được thêm vào `.gitignore` để không commit API keys

---

## 🔐 Bảo mật

⚠️ **QUAN TRỌNG:** Không commit file `.env` vào git!

Thêm vào `.gitignore`:
```
.env
*.env
!.env.example
```

