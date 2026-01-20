"""
RAG Service - Service chính tích hợp RAG
Kết hợp document processing, embedding và retrieval
"""
import logging
from typing import List, Tuple, Dict, Optional
import uuid

from app.rag.processor import DocumentProcessor
from app.rag.embedding import EmbeddingService
from app.rag.vector_store import VectorStoreService

logger = logging.getLogger(__name__)

class RAGService:
    def __init__(self):
        self.document_processor = DocumentProcessor()
        self.embedding_service = EmbeddingService()
        self.vector_store = VectorStoreService()
    
    async def process_and_store_document(self, file_content: bytes, file_name: str) -> str:
        """
        Xử lý và lưu trữ document vào vector store
        """
        file_id = f"DOC-{str(uuid.uuid4())[:8]}"
        
        try:
            logger.info(f"Processing document: {file_name} (ID: {file_id})")
            
            # 1. Extract và chunk text
            chunks = await self.document_processor.process_document(
                file_content, 
                file_name, 
                file_id
            )
            
            if not chunks:
                raise ValueError("No text extracted from document")
            
            # 2. Tạo embeddings cho các chunks
            texts = [chunk.text for chunk in chunks]
            embeddings = await self.embedding_service.create_embeddings(texts)
            
            # Lọc bỏ None embeddings
            valid_chunks = []
            valid_embeddings = []
            for chunk, emb in zip(chunks, embeddings):
                if emb is not None:
                    valid_chunks.append(chunk)
                    valid_embeddings.append(emb)
            
            if not valid_chunks:
                raise ValueError("Failed to create embeddings for document")
            
            # 3. Lưu document metadata
            file_type = file_name.split('.')[-1] if '.' in file_name else ""
            from datetime import datetime
            upload_date = datetime.now().isoformat()
            await self.vector_store.save_document(file_id, file_name, file_type)
            
            # 4. Lưu chunks với embeddings (bao gồm file_type và upload_date)
            await self.vector_store.save_chunks(valid_chunks, valid_embeddings, file_type, upload_date)
            
            logger.info(f"Successfully processed and stored document {file_name} with {len(valid_chunks)} chunks")
            
            return file_id
        
        except Exception as e:
            logger.error(f"Error processing document {file_name}: {str(e)}")
            raise
    
    async def retrieve_context(self, query: str, top_k: int = 5, file_id: str = None) -> Tuple[str, List[dict]]:
        """
        Retrieve relevant context từ vector store dựa trên query
        Returns: (context_string, chunks_list)
        """
        try:
            logger.info(f"Retrieving context for query: '{query[:100]}...' (top_k={top_k}, file_id={file_id})")
            
            # 1. Tạo embedding cho query
            query_embedding = await self.embedding_service.create_embedding(query)
            
            if query_embedding is None:
                logger.warning("Failed to create embedding for query")
                return "", []
            
            logger.info(f"Query embedding created successfully, shape: {query_embedding.shape}")
            
            # 2. Kiểm tra xem có documents trong vector store không
            all_docs = await self.vector_store.get_all_documents()
            logger.info(f"Total documents in vector store: {len(all_docs)}")
            if len(all_docs) == 0:
                logger.warning("No documents found in vector store. Please upload documents first.")
                return "", []
            
            # 3. Tìm kiếm các chunks liên quan
            chunks = await self.vector_store.search_similar(query_embedding, top_k, file_id)
            
            logger.info(f"Search returned {len(chunks)} chunks")
            if chunks:
                for i, chunk in enumerate(chunks[:3]):  # Log 3 chunks đầu tiên
                    logger.info(f"Chunk {i+1}: similarity={chunk.get('similarity', 0):.4f}, file={chunk.get('file_name', 'Unknown')}, text_preview={chunk.get('text', '')[:50]}...")
            
            if not chunks:
                logger.warning(f"No relevant chunks found for query: '{query[:100]}...'")
                return "", []
            
            # 4. Kết hợp các chunks thành context
            context_parts = ["Thông tin liên quan từ tài liệu:"]
            
            for chunk in sorted(chunks, key=lambda x: x.get('similarity', 0), reverse=True):
                context_parts.append(f"\n[File: {chunk.get('file_name', 'Unknown')}, Chunk {chunk.get('chunk_index', 0)}]")
                context_parts.append(chunk.get('text', ''))
                context_parts.append("")
            
            context = "\n".join(context_parts)
            logger.info(f"Retrieved {len(chunks)} relevant chunks for query, context length: {len(context)} characters")
            
            return context, chunks
        
        except Exception as e:
            logger.error(f"Error retrieving context: {str(e)}", exc_info=True)
            return "", []
    
    async def delete_document(self, file_id: str):
        """Xóa document khỏi vector store"""
        await self.vector_store.delete_document(file_id)
    
    async def get_all_documents(self) -> List[Dict]:
        """Lấy danh sách tất cả documents"""
        return await self.vector_store.get_all_documents()
    
    async def get_document_info(self, file_id: str) -> Optional[Dict]:
        """Lấy thông tin document"""
        return await self.vector_store.get_document_info(file_id)

