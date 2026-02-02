import os
import logging
from typing import List, Optional, Dict
import numpy as np
from pathlib import Path
from datetime import datetime

from app.infrastructure.vector_store.base import VectorStore
from app.domain.document import DocumentChunk
from app.core.settings import Settings

logger = logging.getLogger(__name__)


class ImageVectorStore(VectorStore):
    """
    Vector store riêng cho images
    """
    
    def __init__(self):
        """Khởi tạo Image Vector Store với collection riêng"""
        self.store_type = "chroma"
        self.collection = None
        self._init_chroma()
    
    def _init_chroma(self):
        """Khởi tạo Chroma database và collection riêng cho images"""
        try:
            import chromadb
            from chromadb.config import Settings as ChromaSettings
            
            # Sử dụng data/vector_store/ làm thư mục lưu trữ
            db_dir = Path(__file__).parent.parent.parent.parent / "data" / "vector_store"
            db_dir.mkdir(parents=True, exist_ok=True)
            persist_directory = str(db_dir / "chroma_db")
            
            # Tạo Chroma client với persistent storage
            self.chroma_client = chromadb.PersistentClient(
                path=persist_directory,
                settings=ChromaSettings(anonymized_telemetry=False)
            )
            
            # Tạo hoặc lấy collection riêng cho images với dimension 512
            collection_name = Settings.CHROMA_IMAGE_COLLECTION
            
            # Kiểm tra collection đã tồn tại chưa
            try:
                existing_collection = self.chroma_client.get_collection(name=collection_name)
                logger.info(f"Collection '{collection_name}' đã tồn tại")
            except Exception:
                # Collection chưa tồn tại, tạo mới
                logger.info(f"Tạo collection mới '{collection_name}' với dimension 512")
            
            self.collection = self.chroma_client.get_or_create_collection(
                name=collection_name,
                metadata={"hnsw:space": "cosine"}
            )
            
            logger.info(f"Image vector store đã khởi tạo: {collection_name} (dimension: 512)")
        except ImportError:
            logger.error("Chroma chưa được cài đặt. Vui lòng cài: pip install chromadb")
            raise
        except Exception as e:
            logger.error(f"Lỗi khi khởi tạo Image Vector Store: {str(e)}")
            raise
    
    async def save_chunks(
        self, 
        chunks: List[DocumentChunk], 
        embeddings: List[np.ndarray],
        file_type: str = "",
        upload_date: str = "",
        extra_metadata: Optional[List[Dict]] = None
    ) -> None:
        """
        Save image chunks with embeddings to Chroma
        """
        if not chunks or not embeddings:
            return
        
        if not upload_date:
            upload_date = datetime.now().isoformat()
        
        ids = [chunk.chunk_id for chunk in chunks]
        texts = [chunk.text for chunk in chunks]
        
        metadatas = []
        for i, chunk in enumerate(chunks):
            metadata = {
                "file_id": chunk.file_id,
                "file_name": chunk.file_name,
                "file_type": file_type,
                "upload_date": upload_date,
                "chunk_index": str(chunk.chunk_index),
                "start_index": str(chunk.start_index),
                "end_index": str(chunk.end_index),
                "content_type": "image"  # Default: image
            }
            
            # Merge extra metadata nếu có
            if extra_metadata and i < len(extra_metadata):
                metadata.update(extra_metadata[i])
            
            metadatas.append(metadata)
        
        embeddings_list = [emb.tolist() for emb in embeddings if emb is not None]
        
        # Validate embedding dimension
        for i, emb in enumerate(embeddings):
            if emb is not None and len(emb) != 512:
                logger.warning(f"Embedding {i} có dimension {len(emb)}, expected 512")
        
        # Delete existing chunks for this file
        if chunks:
            file_id = chunks[0].file_id
            try:
                existing = self.collection.get(where={"file_id": file_id})
                if existing['ids']:
                    self.collection.delete(ids=existing['ids'])
            except Exception as e:
                logger.warning(f"Không thể xóa existing chunks: {str(e)}")
        
        try:
            self.collection.add(
                ids=ids,
                embeddings=embeddings_list,
                documents=texts,
                metadatas=metadatas
            )
            logger.info(f"Saved {len(chunks)} image chunks to Chroma")
        except Exception as e:
            # Nếu lỗi về dimension, có thể collection đã tồn tại với dimension khác
            if "dimension" in str(e).lower():
                logger.error(f"Lỗi dimension: {str(e)}")
                logger.error("Collection có thể đã được tạo với dimension khác. Cần xóa và tạo lại.")
                raise ValueError(f"Collection dimension mismatch: {str(e)}")
            raise
    
    async def search_similar(
        self, 
        query_embedding: np.ndarray, 
        top_k: int = 5, 
        file_id: Optional[str] = None
    ) -> List[Dict]:
        """Search for similar images in Chroma"""
        import time
        start_time = time.time()
        
        try:
            # Validate dimension
            if len(query_embedding) != 512:
                logger.warning(f"Query embedding có dimension {len(query_embedding)}, expected 512")
            
            where = {"file_id": file_id} if file_id else {"content_type": "image"}
            
            results = self.collection.query(
                query_embeddings=[query_embedding.tolist()],
                n_results=top_k,
                where=where
            )
            
            search_time = time.time() - start_time
            logger.debug(f"Image search completed in {search_time:.3f}s (top_k={top_k}, file_id={file_id})")
            
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
            logger.error(f"Error searching images: {str(e)}", exc_info=True)
            return []
    
    async def delete_document(self, file_id: str) -> None:
        """Delete image and all its chunks"""
        try:
            existing = self.collection.get(where={"file_id": file_id})
            if existing['ids']:
                self.collection.delete(ids=existing['ids'])
            logger.info(f"Deleted image {file_id}")
        except Exception as e:
            logger.error(f"Error deleting image: {str(e)}")
            raise
    
    async def get_all_documents(self) -> List[Dict]:
        """Get list of all images"""
        try:
            # Lấy tất cả images (có content_type = "image")
            results = self.collection.get(where={"content_type": "image"})
            
            if not results or 'ids' not in results or len(results['ids']) == 0:
                return []
            
            # Group chunks theo file_id
            file_dict = {}
            metadatas = results.get('metadatas', [])
            
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
            
            return list(file_dict.values())
        except Exception as e:
            logger.error(f"Lỗi khi lấy danh sách images: {str(e)}", exc_info=True)
            return []
    
    async def get_document_info(self, file_id: str) -> Optional[Dict]:
        """Get image information"""
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
            logger.error(f"Error getting image info: {str(e)}")
        return None

