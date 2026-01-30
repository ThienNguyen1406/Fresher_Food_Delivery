"""
Search Request Schemas
"""
from pydantic import BaseModel
from typing import Optional


class ProductData(BaseModel):
    """Product data for embedding"""
    product_id: Optional[str] = None
    product_name: str
    description: Optional[str] = None
    category_id: str
    category_name: Optional[str] = None
    price: Optional[float] = None
    unit: Optional[str] = None
    origin: Optional[str] = None


class ProductSearchRequest(BaseModel):
    """Request for product search"""
    query: Optional[str] = None
    category_id: Optional[str] = None
    top_k: int = 10

