"""
Document API routes - Upload, delete, list documents
"""
from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from pathlib import Path

from app.rag.service import RAGService

router = APIRouter()

# Initialize RAG service
rag_service = RAGService()

# Models
class ProcessDocumentResponse(BaseModel):
    file_id: str
    file_name: str
    total_chunks: int
    message: str

class DocumentInfo(BaseModel):
    file_id: str
    file_name: str
    file_type: str
    total_chunks: int
    upload_date: str

@router.post("/upload", response_model=ProcessDocumentResponse)
async def upload_document(file: UploadFile = File(...)):
    """
    Upload và xử lý document (docx, txt, pdf, xlsx)
    Extract text, chunk, embed và lưu vào vector store
    """
    try:
        # Kiểm tra file type
        allowed_extensions = ['.txt', '.docx', '.pdf', '.xlsx']
        file_ext = Path(file.filename).suffix.lower()
        
        if file_ext not in allowed_extensions:
            raise HTTPException(
                status_code=400,
                detail=f"File type {file_ext} not supported. Allowed: {allowed_extensions}"
            )
        
        # Kiểm tra file size (50MB)
        contents = await file.read()
        if len(contents) > 50 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="File size exceeds 50MB limit")
        
        # Xử lý document
        file_id = await rag_service.process_and_store_document(
            contents, 
            file.filename
        )
        
        # Lấy thông tin document
        doc_info = await rag_service.get_document_info(file_id)
        
        return ProcessDocumentResponse(
            file_id=file_id,
            file_name=file.filename,
            total_chunks=doc_info.get('total_chunks', 0),
            message="Document processed and stored successfully"
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("", response_model=List[DocumentInfo])
async def get_documents():
    """
    Lấy danh sách tất cả documents đã upload
    """
    try:
        documents = await rag_service.get_all_documents()
        return documents
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{file_id}", response_model=DocumentInfo)
async def get_document_info(file_id: str):
    """
    Lấy thông tin chi tiết của một document
    """
    try:
        info = await rag_service.get_document_info(file_id)
        if not info:
            raise HTTPException(status_code=404, detail="Document not found")
        return DocumentInfo(**info)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{file_id}")
async def delete_document(file_id: str):
    """
    Xóa document và tất cả chunks của nó
    """
    try:
        await rag_service.delete_document(file_id)
        return {"message": "Document deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

