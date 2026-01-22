"""
Chroma vector store implementation - Triển khai vector store sử dụng Chroma
Chroma là vector database local, phù hợp cho development và production nhỏ
"""
import os
import logging
from typing import List, Optional, Dict
import numpy as np
from pathlib import Path
from datetime import datetime

from app.infrastructure.vector_store.base import VectorStore
from app.domain.document import DocumentChunk

logger = logging.getLogger(__name__)


class ChromaVectorStore(VectorStore):
    """
    Chroma vector store implementation
    
    Chroma là vector database mã nguồn mở, lưu trữ local:
    - Phù hợp cho development và production nhỏ
    - Không cần server riêng
    - Lưu trữ dữ liệu trên disk
    """
    
    def __init__(self):
        """Khởi tạo Chroma vector store"""
        self.store_type = "chroma"
        self.collection = None
        self._init_chroma()
    
    def _init_chroma(self):
        """Khởi tạo Chroma database và collection"""
        try:
            import chromadb
            from chromadb.config import Settings
            
            # Sử dụng data/vector_store/ làm thư mục lưu trữ
            db_dir = Path(__file__).parent.parent.parent.parent / "data" / "vector_store"
            db_dir.mkdir(parents=True, exist_ok=True)
            persist_directory = str(db_dir / "chroma_db")
            
            # Tạo Chroma client với persistent storage
            self.chroma_client = chromadb.PersistentClient(
                path=persist_directory,
                settings=Settings(anonymized_telemetry=False)  # Tắt telemetry
            )
            
            # Tạo hoặc lấy collection
            collection_name = os.getenv("CHROMA_COLLECTION", "documents")
            self.collection = self.chroma_client.get_or_create_collection(
                name=collection_name,
                metadata={"hnsw:space": "cosine"}  # Sử dụng cosine similarity
            )
            
            logger.info(f"Chroma vector store đã khởi tạo: {collection_name}")
        except ImportError:
            logger.error("Chroma chưa được cài đặt. Vui lòng cài: pip install chromadb")
            raise
        except Exception as e:
            logger.error(f"Lỗi khi khởi tạo Chroma: {str(e)}")
            raise
    
    async def save_chunks(
        self, 
        chunks: List[DocumentChunk], 
        embeddings: List[np.ndarray],
        file_type: str = "",
        upload_date: str = ""
    ) -> None:
        """Save chunks with embeddings to Chroma"""
        if not chunks or not embeddings:
            return
        
        if not upload_date:
            upload_date = datetime.now().isoformat()
        
        ids = [chunk.chunk_id for chunk in chunks]
        texts = [chunk.text for chunk in chunks]
        
        metadatas = [
            {
                "file_id": chunk.file_id,
                "file_name": chunk.file_name,
                "file_type": file_type,
                "upload_date": upload_date,
                "chunk_index": str(chunk.chunk_index),
                "start_index": str(chunk.start_index),
                "end_index": str(chunk.end_index)
            }
            for chunk in chunks
        ]
        
        embeddings_list = [emb.tolist() for emb in embeddings if emb is not None]
        
        # Delete existing chunks for this file
        if chunks:
            file_id = chunks[0].file_id
            existing = self.collection.get(where={"file_id": file_id})
            if existing['ids']:
                self.collection.delete(ids=existing['ids'])
        
        self.collection.add(
            ids=ids,
            embeddings=embeddings_list,
            documents=texts,
            metadatas=metadatas
        )
        
        logger.info(f"Saved {len(chunks)} chunks to Chroma")
    
    async def search_similar(
        self, 
        query_embedding: np.ndarray, 
        top_k: int = 5, 
        file_id: Optional[str] = None
    ) -> List[Dict]:
        """Search for similar chunks in Chroma"""
        try:
            where = {"file_id": file_id} if file_id else None
            
            all_data = self.collection.get()
            total_chunks = len(all_data.get('ids', [])) if all_data else 0
            
            if total_chunks == 0:
                logger.warning("Chroma collection is empty")
                return []
            
            results = self.collection.query(
                query_embeddings=[query_embedding.tolist()],
                n_results=top_k,
                where=where
            )
            
            chunks = []
            if results.get('ids') and len(results['ids'][0]) > 0:
                for i in range(len(results['ids'][0])):
                    distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                    similarity = 1 - distance
                    
                    chunk = {
                        'chunk_id': results['ids'][0][i],
                        'file_id': results['metadatas'][0][i].get('file_id'),
                        'file_name': results['metadatas'][0][i].get('file_name'),
                        'chunk_index': int(results['metadatas'][0][i].get('chunk_index', 0)),
                        'text': results['documents'][0][i],
                        'similarity': similarity
                    }
                    chunks.append(chunk)
            
            return chunks
        except Exception as e:
            logger.error(f"Error searching Chroma: {str(e)}", exc_info=True)
            return []
    
    async def delete_document(self, file_id: str) -> None:
        """Delete document and all its chunks"""
        try:
            existing = self.collection.get(where={"file_id": file_id})
            if existing['ids']:
                self.collection.delete(ids=existing['ids'])
            logger.info(f"Deleted document {file_id}")
        except Exception as e:
            logger.error(f"Error deleting document: {str(e)}")
            raise
    
    async def get_all_documents(self) -> List[Dict]:
        """
        Lấy danh sách tất cả documents
        
        Returns:
            Danh sách documents với thông tin: file_id, file_name, file_type, upload_date, total_chunks
        """
        try:
            # Lấy tất cả dữ liệu từ collection
            results = self.collection.get()
            
            # Log để debug
            logger.info(f"Chroma collection.get() returned: ids={len(results.get('ids', [])) if results else 0}")
            
            if not results or 'ids' not in results or len(results['ids']) == 0:
                logger.info("Chroma collection is empty - no documents found")
                return []
            
            # Group chunks theo file_id
            file_dict = {}
            metadatas = results.get('metadatas', [])
            
            logger.info(f"Processing {len(results['ids'])} chunks to group by file_id")
            
            for i in range(len(results['ids'])):
                metadata = metadatas[i] if i < len(metadatas) else {}
                file_id = metadata.get('file_id', '')
                
                if file_id:
                    if file_id not in file_dict:
                        file_name = metadata.get('file_name', '')
                        file_type = metadata.get('file_type', '')
                        if not file_type and file_name:
                            file_type = file_name.split('.')[-1] if '.' in file_name else ''
                        
                        upload_date = metadata.get('upload_date', '')
                        if not upload_date:
                            upload_date = datetime.now().isoformat()
                        
                        file_dict[file_id] = {
                            'file_id': file_id,
                            'file_name': file_name,
                            'file_type': file_type,
                            'upload_date': upload_date,
                            'total_chunks': 0
                        }
                    file_dict[file_id]['total_chunks'] += 1
            
            documents = list(file_dict.values())
            logger.info(f"Found {len(documents)} unique documents from {len(results['ids'])} chunks")
            
            return documents
        except Exception as e:
            logger.error(f"Lỗi khi lấy danh sách documents: {str(e)}", exc_info=True)
            return []
    
    async def get_document_info(self, file_id: str) -> Optional[Dict]:
        """Get document information"""
        try:
            results = self.collection.get(where={"file_id": file_id})
            if results['ids'] and len(results['ids']) > 0:
                metadatas = results.get('metadatas', [])
                metadata = metadatas[0] if metadatas else {}
                
                file_name = metadata.get('file_name', '')
                file_type = metadata.get('file_type', '')
                if not file_type and file_name:
                    file_type = file_name.split('.')[-1] if '.' in file_name else ''
                
                upload_date = metadata.get('upload_date', '')
                if not upload_date:
                    upload_date = datetime.now().isoformat()
                
                return {
                    'file_id': file_id,
                    'file_name': file_name,
                    'file_type': file_type,
                    'upload_date': upload_date,
                    'total_chunks': len(results['ids'])
                }
        except Exception as e:
            logger.error(f"Error getting document info: {str(e)}")
        return None

