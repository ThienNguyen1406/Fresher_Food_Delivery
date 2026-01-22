"""
Domain entities - Query
"""
from dataclasses import dataclass
from typing import Optional


@dataclass
class Query:
    """Query entity - represents a user query"""
    question: str
    file_id: Optional[str] = None
    top_k: int = 5
    
    def __post_init__(self):
        """Validate query"""
        if not self.question or not self.question.strip():
            raise ValueError("Query question cannot be empty")
        if self.top_k < 1:
            raise ValueError("top_k must be at least 1")

