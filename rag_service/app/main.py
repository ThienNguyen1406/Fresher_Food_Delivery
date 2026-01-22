"""
RAG Service - Main entry point
FastAPI application cho RAG (Retrieval Augmented Generation)
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import os
import logging
import time

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

# Middleware để log request time
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log thời gian xử lý request"""
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    logger = logging.getLogger(__name__)
    logger.info(f"{request.method} {request.url.path} - {response.status_code} - {process_time:.2f}s")
    return response

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

# Exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Xử lý lỗi toàn cục"""
    logger = logging.getLogger(__name__)
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": f"Internal server error: {str(exc)}"}
    )

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

