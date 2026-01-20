"""
Vector Store Service - Lưu trữ và tìm kiếm vectors
Sử dụng Chroma hoặc Milvus
Lưu trữ trong app/db/
"""
import os
import logging
from typing import List, Optional, Dict
import numpy as np
from pathlib import Path

logger = logging.getLogger(__name__)

class VectorStoreService:
    def __init__(self):
        self.store_type = os.getenv("VECTOR_STORE", "chroma").lower()
        self.collection = None
        
        # Sử dụng app/db/ làm thư mục lưu trữ
        self.db_dir = Path(__file__).parent.parent.parent / "db"
        self.db_dir.mkdir(exist_ok=True)
        
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
            
            # Sử dụng app/db/chroma_db
            persist_directory = str(self.db_dir / "chroma_db")
            
            self.chroma_client = chromadb.PersistentClient(
                path=persist_directory,
                settings=Settings(anonymized_telemetry=False)
            )
            
            collection_name = os.getenv("CHROMA_COLLECTION", "documents")
            self.collection = self.chroma_client.get_or_create_collection(
                name=collection_name,
                metadata={"hnsw:space": "cosine"}
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
            
            milvus_host = os.getenv("MILVUS_HOST", "localhost")
            milvus_port = os.getenv("MILVUS_PORT", "19530")
            connections.connect("default", host=milvus_host, port=milvus_port)
            
            collection_name = os.getenv("MILVUS_COLLECTION", "documents")
            
            if not Collection(collection_name).exists():
                fields = [
                    FieldSchema(name="id", dtype=DataType.VARCHAR, is_primary=True, max_length=100),
                    FieldSchema(name="file_id", dtype=DataType.VARCHAR, max_length=50),
                    FieldSchema(name="file_name", dtype=DataType.VARCHAR, max_length=500),
                    FieldSchema(name="chunk_index", dtype=DataType.INT64),
                    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=65535),
                    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=384)
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
        # Metadata được lưu trong chunks, không cần lưu riêng
        pass
    
    async def save_chunks(self, chunks: List, embeddings: List[np.ndarray], file_type: str = "", upload_date: str = ""):
        """Lưu chunks với embeddings vào vector store"""
        if not chunks or not embeddings:
            return
        
        try:
            if self.store_type == "chroma":
                await self._save_chunks_chroma(chunks, embeddings, file_type, upload_date)
            elif self.store_type == "milvus":
                await self._save_chunks_milvus(chunks, embeddings, file_type, upload_date)
        except Exception as e:
            logger.error(f"Error saving chunks: {str(e)}")
            raise
    
    async def _save_chunks_chroma(self, chunks: List, embeddings: List[np.ndarray], file_type: str = "", upload_date: str = ""):
        """Lưu chunks vào Chroma"""
        from datetime import datetime
        
        ids = [chunk.chunk_id for chunk in chunks]
        texts = [chunk.text for chunk in chunks]
        
        # Nếu không có upload_date, dùng thời gian hiện tại
        if not upload_date:
            upload_date = datetime.now().isoformat()
        
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
    
    async def _save_chunks_milvus(self, chunks: List, embeddings: List[np.ndarray], file_type: str = "", upload_date: str = ""):
        """Lưu chunks vào Milvus"""
        from datetime import datetime
        
        if chunks:
            file_id = chunks[0].file_id
            self.collection.delete(expr=f'file_id == "{file_id}"')
        
        # Nếu không có upload_date, dùng thời gian hiện tại
        if not upload_date:
            upload_date = datetime.now().isoformat()
        
        ids = [chunk.chunk_id for chunk in chunks]
        file_ids = [chunk.file_id for chunk in chunks]
        file_names = [chunk.file_name for chunk in chunks]
        file_types = [file_type] * len(chunks)
        upload_dates = [upload_date] * len(chunks)
        chunk_indices = [chunk.chunk_index for chunk in chunks]
        texts = [chunk.text for chunk in chunks]
        embeddings_list = [emb.tolist() for emb in embeddings if emb is not None]
        
        # Note: Milvus schema cần có file_type và upload_date fields
        # Nếu chưa có, chỉ lưu các field hiện có
        data = [ids, file_ids, file_names, chunk_indices, texts, embeddings_list]
        self.collection.insert(data)
        self.collection.flush()
        
        logger.info(f"Saved {len(chunks)} chunks to Milvus")
    
    async def search_similar(self, query_embedding: np.ndarray, top_k: int = 5, file_id: Optional[str] = None) -> List[Dict]:
        """Tìm kiếm các chunks liên quan"""
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
        try:
            where = {"file_id": file_id} if file_id else None
            
            # Kiểm tra số lượng documents trong collection
            all_data = self.collection.get()
            total_chunks = len(all_data.get('ids', [])) if all_data else 0
            logger.info(f"Chroma collection has {total_chunks} total chunks")
            
            if total_chunks == 0:
                logger.warning("Chroma collection is empty. No documents to search.")
                return []
            
            logger.info(f"Searching with query embedding shape: {query_embedding.shape}, top_k: {top_k}, file_id filter: {file_id}")
            
            results = self.collection.query(
                query_embeddings=[query_embedding.tolist()],
                n_results=top_k,
                where=where
            )
            
            logger.info(f"Chroma query returned {len(results.get('ids', [[]])[0]) if results.get('ids') else 0} results")
            
            chunks = []
            if results.get('ids') and len(results['ids'][0]) > 0:
                for i in range(len(results['ids'][0])):
                    distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                    similarity = 1 - distance  # Chroma uses distance, convert to similarity
                    
                    chunk = {
                        'chunk_id': results['ids'][0][i],
                        'file_id': results['metadatas'][0][i].get('file_id'),
                        'file_name': results['metadatas'][0][i].get('file_name'),
                        'chunk_index': int(results['metadatas'][0][i].get('chunk_index', 0)),
                        'text': results['documents'][0][i],
                        'similarity': similarity
                    }
                    chunks.append(chunk)
                    logger.debug(f"Found chunk: file={chunk['file_name']}, similarity={similarity:.4f}, distance={distance:.4f}")
            
            return chunks
        except Exception as e:
            logger.error(f"Error in _search_chroma: {str(e)}", exc_info=True)
            return []
    
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
        """Xóa document và tất cả chunks"""
        try:
            if self.store_type == "chroma":
                existing = self.collection.get(where={"file_id": file_id})
                if existing['ids']:
                    self.collection.delete(ids=existing['ids'])
            elif self.store_type == "milvus":
                self.collection.delete(expr=f'file_id == "{file_id}"')
                self.collection.flush()
            
            logger.info(f"Deleted document {file_id}")
        except Exception as e:
            logger.error(f"Error deleting document: {str(e)}")
            raise
    
    async def get_all_documents(self) -> List[Dict]:
        """Lấy danh sách tất cả documents"""
        try:
            documents = []
            
            if self.store_type == "chroma":
                # Lấy tất cả data từ Chroma collection
                results = self.collection.get()
                
                if results and 'ids' in results and len(results['ids']) > 0:
                    # Tạo dictionary để group theo file_id
                    file_dict = {}
                    
                    # Chroma trả về metadata dưới dạng list
                    metadatas = results.get('metadatas', [])
                    
                    for i in range(len(results['ids'])):
                        metadata = metadatas[i] if i < len(metadatas) else {}
                        file_id = metadata.get('file_id', '')
                        
                        if file_id:
                            if file_id not in file_dict:
                                file_name = metadata.get('file_name', '')
                                # Extract file_type từ file_name nếu không có trong metadata
                                file_type = metadata.get('file_type', '')
                                if not file_type and file_name:
                                    file_type = file_name.split('.')[-1] if '.' in file_name else ''
                                
                                upload_date = metadata.get('upload_date', '')
                                if not upload_date:
                                    from datetime import datetime
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
            
            elif self.store_type == "milvus":
                # Lấy tất cả data từ Milvus collection
                self.collection.load()
                
                # Query tất cả documents (lấy thêm file_type và upload_date nếu có)
                output_fields = ["file_id", "file_name"]
                # Thêm file_type và upload_date nếu schema có
                try:
                    results = self.collection.query(
                        expr="",
                        output_fields=["file_id", "file_name", "file_type", "upload_date"],
                        limit=10000
                    )
                except:
                    # Nếu schema chưa có file_type và upload_date, chỉ lấy các field cơ bản
                    results = self.collection.query(
                        expr="",
                        output_fields=["file_id", "file_name"],
                        limit=10000
                    )
                
                if results:
                    # Group theo file_id
                    file_dict = {}
                    for result in results:
                        file_id = result.get('file_id')
                        if file_id:
                            if file_id not in file_dict:
                                file_dict[file_id] = {
                                    'file_id': file_id,
                                    'file_name': result.get('file_name', ''),
                                    'file_type': result.get('file_type', ''),
                                    'upload_date': result.get('upload_date', ''),
                                    'total_chunks': 0
                                }
                            file_dict[file_id]['total_chunks'] += 1
                    
                    documents = list(file_dict.values())
            
            logger.info(f"Retrieved {len(documents)} documents")
            return documents
            
        except Exception as e:
            logger.error(f"Error getting all documents: {str(e)}")
            return []
    
    async def get_document_info(self, file_id: str) -> Optional[Dict]:
        """Lấy thông tin document"""
        try:
            if self.store_type == "chroma":
                results = self.collection.get(where={"file_id": file_id})
                if results['ids'] and len(results['ids']) > 0:
                    # Lấy metadata từ chunk đầu tiên
                    metadatas = results.get('metadatas', [])
                    metadata = metadatas[0] if metadatas else {}
                    
                    file_name = metadata.get('file_name', '')
                    # Extract file_type từ file_name nếu không có trong metadata
                    file_type = metadata.get('file_type', '')
                    if not file_type and file_name:
                        file_type = file_name.split('.')[-1] if '.' in file_name else ''
                    
                    upload_date = metadata.get('upload_date', '')
                    if not upload_date:
                        from datetime import datetime
                        upload_date = datetime.now().isoformat()
                    
                    return {
                        'file_id': file_id,
                        'file_name': file_name,
                        'file_type': file_type,
                        'upload_date': upload_date,
                        'total_chunks': len(results['ids'])
                    }
            elif self.store_type == "milvus":
                self.collection.load()
                try:
                    results = self.collection.query(
                        expr=f'file_id == "{file_id}"',
                        output_fields=["file_id", "file_name", "file_type", "upload_date"],
                        limit=1
                    )
                except:
                    results = self.collection.query(
                        expr=f'file_id == "{file_id}"',
                        output_fields=["file_id", "file_name"],
                        limit=1
                    )
                
                if results:
                    result = results[0]
                    # Đếm tổng số chunks
                    count_results = self.collection.query(
                        expr=f'file_id == "{file_id}"',
                        output_fields=["file_id"],
                        limit=10000
                    )
                    
                    return {
                        'file_id': file_id,
                        'file_name': result.get('file_name', ''),
                        'file_type': result.get('file_type', ''),
                        'upload_date': result.get('upload_date', ''),
                        'total_chunks': len(count_results) if count_results else 0
                    }
        except Exception as e:
            logger.error(f"Error getting document info: {str(e)}")
        return None

