"""
Query API routes - Retrieve context, ask questions
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import logging

from app.rag.service import RAGService

router = APIRouter()
logger = logging.getLogger(__name__)

# Initialize RAG service
rag_service = RAGService()

# Models
class QueryRequest(BaseModel):
    question: str
    file_id: Optional[str] = None
    top_k: int = 5

class QueryResponse(BaseModel):
    context: str
    chunks: List[dict]
    has_context: bool

@router.post("/retrieve", response_model=QueryResponse)
async def retrieve_context(request: QueryRequest):
    """
    Retrieve context từ vector store dựa trên query
    """
    try:
        import logging
        logger = logging.getLogger(__name__)
        
        logger.info(f"Received query request: question='{request.question}', top_k={request.top_k}, file_id={request.file_id}")
        
        # Kiểm tra xem có documents không
        all_docs = await rag_service.get_all_documents()
        logger.info(f"Total documents available: {len(all_docs)}")
        
        if len(all_docs) == 0:
            logger.warning("No documents in vector store")
            return QueryResponse(
                context="",
                chunks=[],
                has_context=False
            )
        
        context, chunks = await rag_service.retrieve_context(
            request.question,
            top_k=request.top_k,
            file_id=request.file_id
        )
        
        logger.info(f"Retrieved {len(chunks)} chunks, has_context={len(chunks) > 0}")
        
        return QueryResponse(
            context=context,
            chunks=chunks,
            has_context=len(chunks) > 0
        )
    
    except Exception as e:
        logger.error(f"Error in retrieve_context endpoint: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/debug/vector-store")
async def debug_vector_store():
    """
    Debug endpoint để kiểm tra vector store
    """
    try:
        # Lấy tất cả documents
        all_docs = await rag_service.get_all_documents()
        
        # Kiểm tra vector store trực tiếp
        vector_store = rag_service.vector_store
        store_info = {
            "store_type": vector_store.store_type,
            "total_documents": len(all_docs),
            "documents": all_docs
        }
        
        # Nếu là Chroma, lấy thêm thông tin
        if vector_store.store_type == "chroma" and vector_store.collection:
            try:
                all_data = vector_store.collection.get()
                total_chunks = len(all_data.get('ids', [])) if all_data else 0
                store_info["total_chunks"] = total_chunks
                store_info["collection_name"] = vector_store.collection.name
                
                # Lấy sample chunks để kiểm tra
                if total_chunks > 0:
                    sample_ids = all_data.get('ids', [])[:5]  # 5 chunks đầu tiên
                    sample_metadatas = all_data.get('metadatas', [])[:5]
                    store_info["sample_chunks"] = [
                        {
                            "chunk_id": sample_ids[i] if i < len(sample_ids) else None,
                            "file_id": sample_metadatas[i].get('file_id') if i < len(sample_metadatas) else None,
                            "file_name": sample_metadatas[i].get('file_name') if i < len(sample_metadatas) else None,
                        }
                        for i in range(min(5, total_chunks))
                    ]
            except Exception as e:
                store_info["error"] = str(e)
                logger.error(f"Error getting Chroma info: {str(e)}", exc_info=True)
        
        return store_info
    except Exception as e:
        logger.error(f"Error in debug_vector_store: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

