"""
Domain entities - Answer
"""
from dataclasses import dataclass
from typing import List, Dict, Optional


@dataclass
class RetrievedChunk:
    """Retrieved chunk with similarity score"""
    chunk_id: str
    file_id: str
    file_name: str
    chunk_index: int
    text: str
    similarity: float
    
    def __post_init__(self):
        """Validate retrieved chunk"""
        if not 0 <= self.similarity <= 1:
            raise ValueError("Similarity must be between 0 and 1")


@dataclass
class Answer:
    """Answer entity - represents the answer to a query"""
    context: str
    chunks: List[RetrievedChunk]
    has_context: bool
    
    @property
    def chunk_count(self) -> int:
        """Number of retrieved chunks"""
        return len(self.chunks)
    
    def get_top_chunks(self, n: int = 3) -> List[RetrievedChunk]:
        """Get top N chunks by similarity"""
        sorted_chunks = sorted(self.chunks, key=lambda x: x.similarity, reverse=True)
        return sorted_chunks[:n]

