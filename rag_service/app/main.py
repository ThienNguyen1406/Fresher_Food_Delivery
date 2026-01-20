"""
RAG Service - Main entry point
FastAPI application cho RAG (Retrieval Augmented Generation)
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os
import logging

# Cấu hình logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

from app.api import router as api_router

app = FastAPI(
    title="RAG Service",
    version="1.0.0",
    description="Retrieval Augmented Generation Service for Chatbot"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Cross orgianl
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(api_router, prefix="/api", tags=["RAG"])

@app.get("/")
async def root():
    return {
        "message": "RAG Service is running",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    
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

