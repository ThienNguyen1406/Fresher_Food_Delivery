"""
RAG Service - Service chính tích hợp RAG
Kết hợp document processing, embedding và retrieval
"""
import logging
from typing import List, Tuple
from services.document_processor import DocumentProcessor
from services.embedding_service import EmbeddingService
from services.vector_store import VectorStoreService

logger = logging.getLogger(__name__)

class RAGService:
    def __init__(
        self,
        document_processor: DocumentProcessor,
        embedding_service: EmbeddingService,
        vector_store: VectorStoreService
    ):
        self.document_processor = document_processor
        self.embedding_service = embedding_service
        self.vector_store = vector_store
    
    async def process_and_store_document(self, file_content: bytes, file_name: str) -> str:
        """
        Xử lý và lưu trữ document vào vector store
        """
        import uuid
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
            await self.vector_store.save_document(file_id, file_name, file_type)
            
            # 4. Lưu chunks với embeddings
            await self.vector_store.save_chunks(valid_chunks, valid_embeddings)
            
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
            # 1. Tạo embedding cho query
            query_embedding = await self.embedding_service.create_embedding(query)
            
            if query_embedding is None:
                logger.warning("Failed to create embedding for query")
                return "", []
            
            # 2. Tìm kiếm các chunks liên quan
            chunks = await self.vector_store.search_similar(query_embedding, top_k, file_id)
            
            if not chunks:
                logger.info("No relevant chunks found for query")
                return "", []
            
            # 3. Kết hợp các chunks thành context
            context_parts = ["Thông tin liên quan từ tài liệu:"]
            
            for chunk in sorted(chunks, key=lambda x: x.get('similarity', 0), reverse=True):
                context_parts.append(f"\n[File: {chunk.get('file_name', 'Unknown')}, Chunk {chunk.get('chunk_index', 0)}]")
                context_parts.append(chunk.get('text', ''))
                context_parts.append("")
            
            context = "\n".join(context_parts)
            logger.info(f"Retrieved {len(chunks)} relevant chunks for query")
            
            return context, chunks
        
        except Exception as e:
            logger.error(f"Error retrieving context: {str(e)}")
            return "", []
    
    async def delete_document(self, file_id: str):
        """Xóa document khỏi vector store"""
        await self.vector_store.delete_document(file_id)

