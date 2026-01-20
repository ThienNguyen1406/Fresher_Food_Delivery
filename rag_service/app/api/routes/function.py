"""
Function Calling API routes - Xử lý function calls từ AI
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional
import logging
import os

from app.services.function_handler import FunctionHandler

router = APIRouter()
logger = logging.getLogger(__name__)

# Lấy connection string từ environment variable hoặc config
def get_connection_string() -> str:
    """Lấy SQL Server connection string từ environment variable"""
    # Có thể lấy từ environment variable hoặc config file
    # Nếu không có, sẽ dùng connection string mặc định
    connection_string = os.getenv(
        "SQL_SERVER_CONNECTION_STRING",
        "DRIVER={ODBC Driver 17 for SQL Server};Server=DOMINICNGUYEN\\SQLEXPRESS;Database=FressFood;UID=sa;PWD=123456;TrustServerCertificate=yes;"
    )
    logger.info(f"Using SQL Server connection string: {connection_string[:50]}...")
    return connection_string

# Initialize function handler
function_handler = FunctionHandler(get_connection_string())

# Models
class FunctionCallRequest(BaseModel):
    function_name: str
    arguments: Dict[str, Any]

class FunctionCallResponse(BaseModel):
    result: str
    success: bool
    error: Optional[str] = None

@router.post("/execute", response_model=FunctionCallResponse)
async def execute_function(request: FunctionCallRequest):
    """
    Thực thi function call từ AI
    
    Args:
        request: FunctionCallRequest chứa function_name và arguments
        
    Returns:
        FunctionCallResponse chứa kết quả
    """
    try:
        logger.info(f"Received function call request: {request.function_name} with arguments: {request.arguments}")
        
        result = await function_handler.execute_function(
            request.function_name,
            request.arguments
        )
        
        # Kiểm tra xem result có chứa error không
        import json
        result_dict = json.loads(result)
        
        if "error" in result_dict:
            return FunctionCallResponse(
                result=result,
                success=False,
                error=result_dict["error"]
            )
        
        return FunctionCallResponse(
            result=result,
            success=True
        )
        
    except Exception as e:
        logger.error(f"Error executing function {request.function_name}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "function_handler"}

