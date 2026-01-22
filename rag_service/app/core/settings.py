"""
Core settings - Cấu hình ứng dụng
Tất cả các cấu hình của RAG service được định nghĩa ở đây
"""
import os
from pathlib import Path

# Load environment variables từ file .env (nếu có)
try:
    from dotenv import load_dotenv
    # Load .env file từ thư mục gốc của project
    env_path = Path(__file__).parent.parent.parent / ".env"
    if env_path.exists():
        load_dotenv(env_path)
        print(f"[OK] Da load file .env tu: {env_path}")
    else:
        # Thử load từ thư mục hiện tại
        load_dotenv()
except ImportError:
    # Nếu chưa cài python-dotenv, chỉ dùng environment variables
    pass


class Settings:
    """
    Cấu hình ứng dụng RAG Service
    
    Tất cả các tham số có thể được override bằng environment variables
    """
    
    # ========== Vector Store (Kho lưu trữ vector) ==========
    # Loại vector store sử dụng (chroma, qdrant, faiss, ...)
    VECTOR_STORE_TYPE = os.getenv("VECTOR_STORE", "chroma").lower()
    # Tên collection trong Chroma
    CHROMA_COLLECTION = os.getenv("CHROMA_COLLECTION", "documents")
    # Thư mục lưu trữ dữ liệu Chroma
    CHROMA_PERSIST_DIR = os.getenv("CHROMA_PERSIST_DIR", str(Path(__file__).parent.parent.parent / "data" / "vector_store" / "chroma_db"))
    
    # ========== Embeddings (Tạo embedding vectors) ==========
    # Khuyến nghị: text-embedding-3-large
    # Có sử dụng OpenAI embeddings hay không (mặc định: true)
    USE_OPENAI_EMBEDDINGS = os.getenv("USE_OPENAI_EMBEDDINGS", "true").lower() == "true"
    # API key của OpenAI
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
    # Model embedding sử dụng (mặc định: text-embedding-3-large)
    EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "text-embedding-3-large")
    
    # ========== LLM (Large Language Model) ==========
    # Khuyến nghị: GPT-4.1 (fallback to Ollama)
    # Model LLM của OpenAI (mặc định: gpt-4.1)
    OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-4.1")
    # Có sử dụng Ollama làm fallback khi OpenAI lỗi không
    USE_OLLAMA_FALLBACK = os.getenv("USE_OLLAMA_FALLBACK", "true").lower() == "true"
    # URL của Ollama server
    OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
    # Model Ollama sử dụng
    OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama2")
    
    # ========== Reranker (Sắp xếp lại kết quả) ==========
    # LƯU Ý: Reranker làm chậm phản hồi (cần tải model 1GB+)
    # Khuyến nghị: Tắt reranker nếu dùng OpenAI embeddings (đã đủ tốt)
    # Chỉ bật reranker nếu dùng Sentence Transformer và cần độ chính xác cao
    USE_RERANKER = os.getenv("USE_RERANKER", "false").lower() == "true"  # Mặc định: TẮT để tăng tốc
    # Model reranker sử dụng (mặc định: BAAI/bge-reranker-base)
    RERANKER_MODEL = os.getenv("RERANKER_MODEL", "BAAI/bge-reranker-base")
    
    # ========== Document Processing (Xử lý tài liệu) ==========
    # Kích thước mỗi chunk (số ký tự)
    CHUNK_SIZE = int(os.getenv("CHUNK_SIZE", "500"))
    # Số ký tự overlap giữa các chunks
    CHUNK_OVERLAP = int(os.getenv("CHUNK_OVERLAP", "50"))
    
    # ========== Database (Cơ sở dữ liệu) ==========
    # Connection string cho SQL Server (dùng cho function calling)
    DATABASE_CONNECTION_STRING = os.getenv(
        "DATABASE_CONNECTION_STRING",
        "Server=DOMINICNGUYEN\\SQLEXPRESS;Database=FressFood;User Id=sa;Password=123456;TrustServerCertificate=True;"
    )
    
    # ========== App (Ứng dụng) ==========
    # Base URL của ứng dụng backend
    APP_BASE_URL = os.getenv("APP_BASE_URL", "https://localhost:7240")

