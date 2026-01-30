"""
Search Response Schemas
"""
from pydantic import BaseModel
from typing import List, Optional, Dict


class ProductSearchResult(BaseModel):
    """Single product search result"""
    product_id: str
    product_name: str
    category_id: str
    category_name: str
    similarity: float
    price: Optional[float] = None


class ProductSearchResponse(BaseModel):
    """Response for product search"""
    results: List[ProductSearchResult]
    query_type: str  # "image", "text", or "chat"
    description: Optional[str] = None  # Mô tả từ LLM (nếu có)


class EmbedProductResponse(BaseModel):
    """Response for product embedding"""
    product_id: str
    message: str
    has_image: bool
    has_text: bool


class ChatProductResponse(BaseModel):
    """Response for chat product search"""
    products: List[Dict]
    message: str
    has_images: bool

