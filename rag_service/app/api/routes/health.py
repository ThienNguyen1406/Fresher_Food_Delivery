"""
Health check API route
"""
from fastapi import APIRouter

router = APIRouter()

@router.get("")
async def health():
    """Health check endpoint"""
    return {"status": "healthy"}

