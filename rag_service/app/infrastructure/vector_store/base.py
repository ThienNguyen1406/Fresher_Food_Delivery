"""
Base interface for vector store implementations
"""
from abc import ABC, abstractmethod
from typing import List, Optional, Dict
import numpy as np
from app.domain.document import DocumentChunk


class VectorStore(ABC):
    """Abstract base class for vector store implementations"""
    
    @abstractmethod
    async def save_chunks(
        self, 
        chunks: List[DocumentChunk], 
        embeddings: List[np.ndarray],
        file_type: str = "",
        upload_date: str = ""
    ) -> None:
        """Save chunks with embeddings to vector store"""
        pass
    
    @abstractmethod
    async def search_similar(
        self, 
        query_embedding: np.ndarray, 
        top_k: int = 5, 
        file_id: Optional[str] = None
    ) -> List[Dict]:
        """Search for similar chunks"""
        pass
    
    @abstractmethod
    async def delete_document(self, file_id: str) -> None:
        """Delete document and all its chunks"""
        pass
    
    @abstractmethod
    async def get_all_documents(self) -> List[Dict]:
        """Get list of all documents"""
        pass
    
    @abstractmethod
    async def get_document_info(self, file_id: str) -> Optional[Dict]:
        """Get document information"""
        pass

