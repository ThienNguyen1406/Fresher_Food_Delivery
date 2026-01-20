"""
Main entry point - Chạy RAG service
"""
from app.main import app
import uvicorn
import os

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    
    # Hiển thị URL để truy cập từ browser
    print("\n" + "="*50)
    print("🚀 RAG Service đang chạy!")
    print("="*50)
    print(f"📖 API Documentation: http://localhost:{port}/docs")
    print(f"🔍 Swagger UI: http://localhost:{port}/docs")
    print(f"📋 ReDoc: http://localhost:{port}/redoc")
    print(f"❤️  Health Check: http://localhost:{port}/health")
    print("="*50)
    print(f"\nĐể dừng service, nhấn Ctrl+C\n")
    
    uvicorn.run(app, host=host, port=port)
