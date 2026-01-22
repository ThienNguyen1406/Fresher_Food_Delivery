"""
Script kiểm tra cấu hình RAG Service
Chạy script này để xem cấu hình hiện tại
"""
import os
from app.core.settings import Settings

def check_config():
    """Kiểm tra và hiển thị cấu hình hiện tại"""
    print("\n" + "="*60)
    print("KIEM TRA CAU HINH RAG SERVICE")
    print("="*60)
    
    # OpenAI Configuration
    print("\nOpenAI Configuration:")
    has_api_key = bool(Settings.OPENAI_API_KEY)
    api_key_display = Settings.OPENAI_API_KEY[:20] + "..." if Settings.OPENAI_API_KEY else "CHUA CAU HINH"
    print(f"  OPENAI_API_KEY: {api_key_display}")
    print(f"  USE_OPENAI_EMBEDDINGS: {Settings.USE_OPENAI_EMBEDDINGS}")
    print(f"  EMBEDDING_MODEL: {Settings.EMBEDDING_MODEL}")
    print(f"  OPENAI_MODEL: {Settings.OPENAI_MODEL}")
    
    if not has_api_key:
        print("\n  CANH BAO: Chua co OpenAI API Key!")
        print("     He thong se dung Sentence Transformer (cham hon)")
        print("     De cau hinh: Them OPENAI_API_KEY vao file .env hoac environment variable")
    
    # Vector Store
    print("\nVector Store Configuration:")
    print(f"  VECTOR_STORE_TYPE: {Settings.VECTOR_STORE_TYPE}")
    print(f"  CHROMA_COLLECTION: {Settings.CHROMA_COLLECTION}")
    
    # Reranker
    print("\nReranker Configuration:")
    print(f"  USE_RERANKER: {Settings.USE_RERANKER}")
    print(f"  RERANKER_MODEL: {Settings.RERANKER_MODEL}")
    
    # Document Processing
    print("\nDocument Processing:")
    print(f"  CHUNK_SIZE: {Settings.CHUNK_SIZE}")
    print(f"  CHUNK_OVERLAP: {Settings.CHUNK_OVERLAP}")
    
    # LLM Fallback
    print("\nLLM Fallback:")
    print(f"  USE_OLLAMA_FALLBACK: {Settings.USE_OLLAMA_FALLBACK}")
    if Settings.USE_OLLAMA_FALLBACK:
        print(f"  OLLAMA_BASE_URL: {Settings.OLLAMA_BASE_URL}")
        print(f"  OLLAMA_MODEL: {Settings.OLLAMA_MODEL}")
    
    print("\n" + "="*60)
    
    # Recommendations
    if not has_api_key:
        print("\nKHUYEN NGHI:")
        print("   1. Lay OpenAI API Key tai: https://platform.openai.com/api-keys")
        print("   2. Them vao file .env: OPENAI_API_KEY=sk-your-key-here")
        print("   3. Hoac set environment variable: export OPENAI_API_KEY=sk-your-key-here")
        print("   4. Xem SETUP.md de biet chi tiet")
    else:
        print("\nCau hinh OK! Ban co the chay service.")
    
    print("="*60 + "\n")

if __name__ == "__main__":
    check_config()

