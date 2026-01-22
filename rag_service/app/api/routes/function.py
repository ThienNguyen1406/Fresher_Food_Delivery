"""
Function API routes - Execute function calls from AI
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional
import logging
import json

from app.services.function import FunctionHandler
from app.core.settings import Settings

router = APIRouter()
logger = logging.getLogger(__name__)

# Initialize function handler
_function_handler: FunctionHandler = None

def get_function_handler() -> FunctionHandler:
    """Get function handler instance"""
    global _function_handler
    if _function_handler is None:
        _function_handler = FunctionHandler(Settings.DATABASE_CONNECTION_STRING)
    return _function_handler

# Models
class FunctionExecuteRequest(BaseModel):
    function_name: str
    arguments: Dict[str, Any] = {}

class FunctionExecuteResponse(BaseModel):
    result: str
    success: bool
    error: Optional[str] = None

@router.post("/execute", response_model=FunctionExecuteResponse)
async def execute_function(request: FunctionExecuteRequest):
    """
    Thực thi function call và trả về kết quả
    """
    try:
        logger.info(f"Executing function: {request.function_name} with arguments: {request.arguments}")
        
        function_handler = get_function_handler()
        result = await function_handler.execute_function(
            request.function_name,
            request.arguments
        )
        
        if result:
            # Kiểm tra xem có lỗi không
            try:
                result_dict = json.loads(result)
                if "error" in result_dict:
                    return FunctionExecuteResponse(
                        result=result,
                        success=False,
                        error=result_dict.get("error")
                    )
            except:
                pass
            
            return FunctionExecuteResponse(
                result=result,
                success=True
            )
        else:
            return FunctionExecuteResponse(
                result="",
                success=False,
                error="Function execution returned empty result"
            )
            
    except Exception as ex:
        logger.error(f"Error executing function {request.function_name}: {str(ex)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Lỗi khi thực thi function: {str(ex)}"
        )

@router.get("/list")
async def list_functions():
    """
    Lấy danh sách các function có sẵn
    """
    return {
        "functions": [
            "getProductExpiry",
            "getProductsExpiringSoon",
            "getMonthlyRevenue",
            "getRevenueStatistics",
            "getBestSellingProductImage",
            "getProductInfo",
            "getOrderStatus",
            "getCustomerOrders",
            "getTopProducts",
            "getInventoryStatus",
            "getCategoryProducts",
            "getActivePromotions"
        ]
    }
