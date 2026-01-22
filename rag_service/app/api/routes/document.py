"""
Document API routes - Upload, delete, list documents
"""
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from pydantic import BaseModel
from typing import List
from pathlib import Path
import logging

from app.api.deps import get_ingest_pipeline, get_vector_store
from app.core.ingest_pipeline import IngestPipeline
from app.infrastructure.vector_store.base import VectorStore

router = APIRouter()
logger = logging.getLogger(__name__)

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
async def upload_document(
    file: UploadFile = File(...),
    ingest_pipeline: IngestPipeline = Depends(get_ingest_pipeline),
    vector_store: VectorStore = Depends(get_vector_store)
):
    """
    Upload và xử lý document (docx, txt, pdf, xlsx)
    Extract text, chunk, embed và lưu vào vector store
    
    Lưu ý: Quá trình này có thể mất vài phút với file lớn do cần tạo embeddings
    """
    import time
    start_time = time.time()
    
    try:
        logger.info(f"📤 Nhận request upload file: {file.filename}")
        
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
        file_size_mb = len(contents) / (1024 * 1024)
        logger.info(f"📦 File size: {file_size_mb:.2f} MB")
        
        if len(contents) > 50 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="File size exceeds 50MB limit")
        
        # Xử lý document
        logger.info(f"🔄 Bắt đầu xử lý file: {file.filename}")
        file_id = await ingest_pipeline.process_and_store(
            contents, 
            file.filename
        )
        
        # Lấy thông tin document
        doc_info = await vector_store.get_document_info(file_id)
        
        elapsed_time = time.time() - start_time
        logger.info(f"✅ Hoàn thành upload file {file.filename} trong {elapsed_time:.2f} giây")
        
        return ProcessDocumentResponse(
            file_id=file_id,
            file_name=file.filename,
            total_chunks=doc_info.get('total_chunks', 0) if doc_info else 0,
            message=f"Document processed and stored successfully in {elapsed_time:.2f}s"
        )
    
    except HTTPException:
        raise
    except Exception as e:
        elapsed_time = time.time() - start_time
        logger.error(f"❌ Lỗi khi upload document {file.filename} sau {elapsed_time:.2f}s: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500, 
            detail=f"Error processing document: {str(e)}"
        )

@router.get("", response_model=List[DocumentInfo])
async def get_documents():
    """
    Lấy danh sách tất cả documents đã upload
    """
    try:
        vector_store = get_vector_store()
        documents = await vector_store.get_all_documents()
        
        logger.info(f"API get_documents: Returning {len(documents)} documents")
        
        return documents
    except Exception as e:
        logger.error(f"Error in get_documents: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/debug")
async def debug_documents():
    """
    Debug endpoint để kiểm tra vector store và documents
    """
    try:
        vector_store = get_vector_store()
        
        # Lấy tất cả documents
        all_docs = await vector_store.get_all_documents()
        
        debug_info = {
            "total_documents": len(all_docs),
            "documents": all_docs,
            "vector_store_type": vector_store.store_type if hasattr(vector_store, 'store_type') else "unknown"
        }
        
        # Nếu là Chroma, lấy thêm thông tin chi tiết
        if hasattr(vector_store, 'collection') and vector_store.collection:
            try:
                all_data = vector_store.collection.get()
                total_chunks = len(all_data.get('ids', [])) if all_data else 0
                
                debug_info.update({
                    "total_chunks": total_chunks,
                    "collection_name": vector_store.collection.name,
                    "has_data": total_chunks > 0
                })
                
                # Lấy sample metadata để kiểm tra
                if total_chunks > 0:
                    sample_metadatas = all_data.get('metadatas', [])[:3]
                    debug_info["sample_metadatas"] = sample_metadatas
                    
            except Exception as e:
                debug_info["error"] = str(e)
                logger.error(f"Error getting Chroma debug info: {str(e)}", exc_info=True)
        
        return debug_info
        
    except Exception as e:
        logger.error(f"Error in debug_documents: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{file_id}", response_model=DocumentInfo)
async def get_document_info(file_id: str):
    """
    Lấy thông tin chi tiết của một document
    """
    try:
        vector_store = get_vector_store()
        info = await vector_store.get_document_info(file_id)
        if not info:
            raise HTTPException(status_code=404, detail="Document not found")
        return DocumentInfo(**info)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting document info: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{file_id}")
async def delete_document(file_id: str):
    """
    Xóa document và tất cả chunks của nó
    """
    try:
        vector_store = get_vector_store()
        await vector_store.delete_document(file_id)
        return {"message": "Document deleted successfully"}
    except Exception as e:
        logger.error(f"Error deleting document: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))
