"""
Function API routes - Execute function calls from AI
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional
import logging
import os

# Import function handler
import sys
# Add parent directory to path to import from services
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)

from services.function_handler import FunctionHandler

router = APIRouter()
logger = logging.getLogger(__name__)

# Initialize function handler
connection_string = os.getenv(
    "DATABASE_CONNECTION_STRING",
    "Server=DOMINICNGUYEN\\SQLEXPRESS;Database=FressFood;User Id=sa;Password=123456;TrustServerCertificate=True;"
)
function_handler = FunctionHandler(connection_string)

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
        
        result = await function_handler.execute_function(
            request.function_name,
            request.arguments
        )
        
        if result:
            # Kiểm tra xem có lỗi không
            import json
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
            "getCategoryProducts"
        ]
    }

