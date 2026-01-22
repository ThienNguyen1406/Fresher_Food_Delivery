"""
Domain entities - Document and Chunk
Pure domain objects, no framework dependencies
"""
from dataclasses import dataclass
from typing import Optional
from datetime import datetime


@dataclass
class DocumentChunk:
    """Chunk entity - represents a piece of text from a document"""
    chunk_id: str
    file_id: str
    file_name: str
    text: str
    chunk_index: int
    start_index: int
    end_index: int
    
    def __post_init__(self):
        """Validate chunk data"""
        if not self.text or not self.text.strip():
            raise ValueError("Chunk text cannot be empty")
        if self.start_index < 0 or self.end_index < self.start_index:
            raise ValueError("Invalid chunk indices")


@dataclass
class Document:
    """Document entity - represents a document in the system"""
    file_id: str
    file_name: str
    file_type: str
    upload_date: datetime
    total_chunks: int = 0
    
    def __post_init__(self):
        """Validate document data"""
        if not self.file_id or not self.file_name:
            raise ValueError("Document must have file_id and file_name")

