"""
Query API routes - Retrieve context, ask questions
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import logging

from app.api.deps import get_rag_pipeline
from app.domain.query import Query
from app.domain.answer import Answer, RetrievedChunk

router = APIRouter()
logger = logging.getLogger(__name__)

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
    TỐI ƯU: Mục tiêu phản hồi < 2 giây
    """
    import time
    start_time = time.time()
    
    try:
        logger.info(f"📥 Received query: question='{request.question[:50]}...', top_k={request.top_k}, file_id={request.file_id}")
        
        # TỐI ƯU: Giới hạn top_k để tăng tốc (tối đa 5 cho query nhanh)
        top_k = min(request.top_k, 5)
        if top_k != request.top_k:
            logger.info(f"⚡ Giới hạn top_k từ {request.top_k} xuống {top_k} để tăng tốc")
        
        # Create domain query
        query = Query(
            question=request.question,
            file_id=request.file_id,
            top_k=top_k
        )
        
        # Get RAG pipeline
        rag_pipeline = get_rag_pipeline()
        
        # Retrieve context
        answer = await rag_pipeline.retrieve(query)
        
        elapsed_time = time.time() - start_time
        logger.info(f"✅ Query completed in {elapsed_time:.2f}s (target: <2s)")
        
        # Convert to response format
        chunks_dict = [
            {
                'chunk_id': chunk.chunk_id,
                'file_id': chunk.file_id,
                'file_name': chunk.file_name,
                'chunk_index': chunk.chunk_index,
                'text': chunk.text,
                'similarity': chunk.similarity
            }
            for chunk in answer.chunks
        ]
        
        logger.info(f"Retrieved {len(answer.chunks)} chunks, has_context={answer.has_context}")
        
        return QueryResponse(
            context=answer.context,
            chunks=chunks_dict,
            has_context=answer.has_context
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
        from app.api.deps import get_vector_store
        vector_store = get_vector_store()
        
        # Lấy tất cả documents
        all_docs = await vector_store.get_all_documents()
        
        store_info = {
            "store_type": vector_store.store_type if hasattr(vector_store, 'store_type') else "chroma",
            "total_documents": len(all_docs),
            "documents": all_docs
        }
        
        # Nếu là Chroma, lấy thêm thông tin
        if hasattr(vector_store, 'collection') and vector_store.collection:
            try:
                all_data = vector_store.collection.get()
                total_chunks = len(all_data.get('ids', [])) if all_data else 0
                store_info["total_chunks"] = total_chunks
                store_info["collection_name"] = vector_store.collection.name
                
                # Lấy sample chunks để kiểm tra
                if total_chunks > 0:
                    sample_ids = all_data.get('ids', [])[:5]
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
