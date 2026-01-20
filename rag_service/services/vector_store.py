"""
Vector Store Service - Lưu trữ và tìm kiếm vectors
Sử dụng Chroma hoặc Milvus
"""
import os
import logging
from typing import List, Optional, Dict
import numpy as np
from datetime import datetime
import uuid

logger = logging.getLogger(__name__)

class VectorStoreService:
    def __init__(self):
        self.store_type = os.getenv("VECTOR_STORE", "chroma").lower()
        self.collection = None
        
        if self.store_type == "chroma":
            self._init_chroma()
        elif self.store_type == "milvus":
            self._init_milvus()
        else:
            logger.warning(f"Unknown vector store type: {self.store_type}, using Chroma")
            self._init_chroma()
    
    def _init_chroma(self):
        """Khởi tạo Chroma vector store"""
        try:
            import chromadb
            from chromadb.config import Settings
            
            # Tạo hoặc load Chroma client
            persist_directory = os.getenv("CHROMA_PERSIST_DIR", "./chroma_db")
            self.chroma_client = chromadb.PersistentClient(
                path=persist_directory,
                settings=Settings(anonymized_telemetry=False)
            )
            
            # Tạo hoặc get collection
            collection_name = os.getenv("CHROMA_COLLECTION", "documents")
            self.collection = self.chroma_client.get_or_create_collection(
                name=collection_name,
                metadata={"hnsw:space": "cosine"}  # Sử dụng cosine similarity
            )
            
            logger.info(f"Chroma vector store initialized: {collection_name}")
        except ImportError:
            logger.error("Chroma not installed. Please install: pip install chromadb")
            raise
        except Exception as e:
            logger.error(f"Error initializing Chroma: {str(e)}")
            raise
    
    def _init_milvus(self):
        """Khởi tạo Milvus vector store"""
        try:
            from pymilvus import connections, Collection, FieldSchema, CollectionSchema, DataType
            
            # Kết nối Milvus
            milvus_host = os.getenv("MILVUS_HOST", "localhost")
            milvus_port = os.getenv("MILVUS_PORT", "19530")
            connections.connect("default", host=milvus_host, port=milvus_port)
            
            collection_name = os.getenv("MILVUS_COLLECTION", "documents")
            
            # Tạo collection nếu chưa có
            if not Collection(collection_name).exists():
                # Define schema
                fields = [
                    FieldSchema(name="id", dtype=DataType.VARCHAR, is_primary=True, max_length=100),
                    FieldSchema(name="file_id", dtype=DataType.VARCHAR, max_length=50),
                    FieldSchema(name="file_name", dtype=DataType.VARCHAR, max_length=500),
                    FieldSchema(name="chunk_index", dtype=DataType.INT64),
                    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=65535),
                    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=384)  # Default dim
                ]
                schema = CollectionSchema(fields, "Document chunks collection")
                self.collection = Collection(collection_name, schema)
                self.collection.create_index(
                    field_name="embedding",
                    index_params={"metric_type": "COSINE", "index_type": "IVF_FLAT"}
                )
            else:
                self.collection = Collection(collection_name)
            
            logger.info(f"Milvus vector store initialized: {collection_name}")
        except ImportError:
            logger.error("Milvus not installed. Please install: pip install pymilvus")
            raise
        except Exception as e:
            logger.error(f"Error initializing Milvus: {str(e)}")
            raise
    
    async def save_document(self, file_id: str, file_name: str, file_type: str):
        """Lưu document metadata"""
        # Chroma lưu metadata trong collection, không cần bảng riêng
        # Có thể dùng SQLite hoặc file JSON để lưu metadata nếu cần
        pass
    
    async def save_chunks(self, chunks: List, embeddings: List[np.ndarray]):
        """
        Lưu chunks với embeddings vào vector store
        """
        if not chunks or not embeddings:
            return
        
        try:
            if self.store_type == "chroma":
                await self._save_chunks_chroma(chunks, embeddings)
            elif self.store_type == "milvus":
                await self._save_chunks_milvus(chunks, embeddings)
        except Exception as e:
            logger.error(f"Error saving chunks: {str(e)}")
            raise
    
    async def _save_chunks_chroma(self, chunks: List, embeddings: List[np.ndarray]):
        """Lưu chunks vào Chroma"""
        ids = [chunk.chunk_id for chunk in chunks]
        texts = [chunk.text for chunk in chunks]
        metadatas = [
            {
                "file_id": chunk.file_id,
                "file_name": chunk.file_name,
                "chunk_index": str(chunk.chunk_index),
                "start_index": str(chunk.start_index),
                "end_index": str(chunk.end_index)
            }
            for chunk in chunks
        ]
        
        # Convert numpy arrays to list
        embeddings_list = [emb.tolist() for emb in embeddings if emb is not None]
        
        # Xóa chunks cũ của file nếu có
        if chunks:
            file_id = chunks[0].file_id
            existing = self.collection.get(where={"file_id": file_id})
            if existing['ids']:
                self.collection.delete(ids=existing['ids'])
        
        # Thêm chunks mới
        self.collection.add(
            ids=ids,
            embeddings=embeddings_list,
            documents=texts,
            metadatas=metadatas
        )
        
        logger.info(f"Saved {len(chunks)} chunks to Chroma")
    
    async def _save_chunks_milvus(self, chunks: List, embeddings: List[np.ndarray]):
        """Lưu chunks vào Milvus"""
        # Xóa chunks cũ của file nếu có
        if chunks:
            file_id = chunks[0].file_id
            self.collection.delete(expr=f'file_id == "{file_id}"')
        
        # Chuẩn bị data
        ids = [chunk.chunk_id for chunk in chunks]
        file_ids = [chunk.file_id for chunk in chunks]
        file_names = [chunk.file_name for chunk in chunks]
        chunk_indices = [chunk.chunk_index for chunk in chunks]
        texts = [chunk.text for chunk in chunks]
        embeddings_list = [emb.tolist() for emb in embeddings if emb is not None]
        
        # Insert data
        data = [ids, file_ids, file_names, chunk_indices, texts, embeddings_list]
        self.collection.insert(data)
        self.collection.flush()
        
        logger.info(f"Saved {len(chunks)} chunks to Milvus")
    
    async def search_similar(self, query_embedding: np.ndarray, top_k: int = 5, file_id: Optional[str] = None) -> List[Dict]:
        """
        Tìm kiếm các chunks liên quan dựa trên query embedding
        """
        try:
            if self.store_type == "chroma":
                return await self._search_chroma(query_embedding, top_k, file_id)
            elif self.store_type == "milvus":
                return await self._search_milvus(query_embedding, top_k, file_id)
        except Exception as e:
            logger.error(f"Error searching similar chunks: {str(e)}")
            return []
    
    async def _search_chroma(self, query_embedding: np.ndarray, top_k: int, file_id: Optional[str]):
        """Tìm kiếm trong Chroma"""
        where = {"file_id": file_id} if file_id else None
        
        results = self.collection.query(
            query_embeddings=[query_embedding.tolist()],
            n_results=top_k,
            where=where
        )
        
        chunks = []
        if results['ids'] and len(results['ids'][0]) > 0:
            for i in range(len(results['ids'][0])):
                chunk = {
                    'chunk_id': results['ids'][0][i],
                    'file_id': results['metadatas'][0][i].get('file_id'),
                    'file_name': results['metadatas'][0][i].get('file_name'),
                    'chunk_index': int(results['metadatas'][0][i].get('chunk_index', 0)),
                    'text': results['documents'][0][i],
                    'similarity': 1 - results['distances'][0][i] if 'distances' in results else 0.0
                }
                chunks.append(chunk)
        
        return chunks
    
    async def _search_milvus(self, query_embedding: np.ndarray, top_k: int, file_id: Optional[str]):
        """Tìm kiếm trong Milvus"""
        search_params = {"metric_type": "COSINE", "params": {"nprobe": 10}}
        
        expr = f'file_id == "{file_id}"' if file_id else None
        
        results = self.collection.search(
            data=[query_embedding.tolist()],
            anns_field="embedding",
            param=search_params,
            limit=top_k,
            expr=expr,
            output_fields=["file_id", "file_name", "chunk_index", "text"]
        )
        
        chunks = []
        if results and len(results[0]) > 0:
            for hit in results[0]:
                chunk = {
                    'chunk_id': hit.id,
                    'file_id': hit.entity.get('file_id'),
                    'file_name': hit.entity.get('file_name'),
                    'chunk_index': hit.entity.get('chunk_index'),
                    'text': hit.entity.get('text'),
                    'similarity': hit.score
                }
                chunks.append(chunk)
        
        return chunks
    
    async def delete_document(self, file_id: str):
        """Xóa document và tất cả chunks của nó"""
        try:
            if self.store_type == "chroma":
                existing = self.collection.get(where={"file_id": file_id})
                if existing['ids']:
                    self.collection.delete(ids=existing['ids'])
            elif self.store_type == "milvus":
                self.collection.delete(expr=f'file_id == "{file_id}"')
                self.collection.flush()
            
            logger.info(f"Deleted document {file_id} and all its chunks")
        except Exception as e:
            logger.error(f"Error deleting document: {str(e)}")
            raise
    
    async def get_all_documents(self) -> List[Dict]:
        """Lấy danh sách tất cả documents"""
        # Chroma không có query metadata trực tiếp, cần lưu metadata riêng
        # Tạm thời return empty list, có thể implement với SQLite hoặc file JSON
        return []
    
    async def get_document_info(self, file_id: str) -> Optional[Dict]:
        """Lấy thông tin document"""
        try:
            if self.store_type == "chroma":
                results = self.collection.get(where={"file_id": file_id})
                if results['ids']:
                    return {
                        'file_id': file_id,
                        'total_chunks': len(results['ids'])
                    }
        except Exception as e:
            logger.error(f"Error getting document info: {str(e)}")
        return None

