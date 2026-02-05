"""
Tool Agent - Function calling để query database và các tools khác
"""
from typing import Dict, Any, List, Optional
import logging
from app.agents.base_agent import BaseAgent
from app.services.function.function_handler import FunctionHandler

logger = logging.getLogger(__name__)


class ToolAgent(BaseAgent):
    """
    Tool Agent thực hiện function calling:
    - Query database để lấy thông tin chi tiết sản phẩm
    - Query đơn hàng
    - Query thông tin khác từ database
    """
    
    def __init__(self, function_handler: Optional[FunctionHandler] = None):
        super().__init__("ToolAgent")
        self.function_handler = function_handler or FunctionHandler()
    
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Thực hiện function calling dựa trên intent và query
        
        Returns:
            Updated state with:
                - tool_results: Results from function calls
                - tool_context: Formatted context from tool results
        """
        query = state.get("query", "").strip()
        intent = state.get("intent", {})
        intent_type = intent.get("type", "unknown")
        knowledge_results = state.get("knowledge_results", [])
        
        tool_results = []
        tool_context = ""
        
        try:
            # Quyết định functions cần gọi dựa trên intent
            functions_to_call = self._determine_functions(intent_type, query, knowledge_results)
            
            # Gọi functions
            for func_name, func_args in functions_to_call:
                self.log(f"🔧 Calling function: {func_name} with args: {func_args}")
                
                try:
                    result = await self._call_function(func_name, func_args)
                    if result:
                        tool_results.append({
                            "function": func_name,
                            "arguments": func_args,
                            "result": result
                        })
                except Exception as e:
                    self.log(f"❌ Error calling function {func_name}: {str(e)}", level="error")
            
            # Format context
            tool_context = self._format_context(tool_results)
            
            self.log(f"✅ Executed {len(tool_results)} function calls")
            
        except Exception as e:
            self.log(f"❌ Error in tool agent: {str(e)}", level="error")
            tool_results = []
            tool_context = ""
        
        # Cập nhật state
        state.update({
            "tool_results": tool_results,
            "tool_context": tool_context
        })
        
        return state
    
    def _determine_functions(
        self,
        intent_type: str,
        query: str,
        knowledge_results: List[Dict[str, Any]]
    ) -> List[tuple]:
        """Xác định functions cần gọi dựa trên intent"""
        functions = []
        query_lower = query.lower()
        
        if intent_type == "product_info":
            # Nếu có product_id từ knowledge results, query chi tiết
            if knowledge_results:
                product_id = knowledge_results[0].get("product_id")
                if product_id:
                    functions.append(("get_product_details", {"product_id": product_id}))
            else:
                # Thử extract product name từ query
                product_name = self._extract_product_name(query)
                if product_name:
                    functions.append(("search_products", {"query": product_name, "top_k": 5}))
        
        elif intent_type == "order_status":
            # Extract order ID từ query
            order_id = self._extract_order_id(query)
            if order_id:
                functions.append(("get_order_status", {"order_id": order_id}))
        
        elif intent_type == "price_question":
            # Query giá sản phẩm
            if knowledge_results:
                product_id = knowledge_results[0].get("product_id")
                if product_id:
                    functions.append(("get_product_price", {"product_id": product_id}))
        
        elif intent_type == "sales_statistics" or intent_type == "multi_intent":
            # Xử lý yêu cầu về doanh số/thống kê
            import re
            from datetime import datetime
            
            # Kiểm tra xem có product_id từ knowledge_results không (multi-intent case)
            product_id = None
            if knowledge_results and len(knowledge_results) > 0:
                product_id = knowledge_results[0].get("product_id")
                self.log(f"🔍 Found product_id from knowledge_results: {product_id}")
            
            # Nếu có product_id → query doanh thu theo sản phẩm
            if product_id:
                # Extract năm từ query (nếu có)
                year_match = re.search(r"(?:năm|year)\s*(\d{4})", query_lower)
                year = int(year_match.group(1)) if year_match else datetime.now().year
                
                # Gọi function lấy doanh thu theo tháng của sản phẩm
                self.log(f"🔧 Calling getProductMonthlyRevenue for product {product_id}, year {year}")
                functions.append(("getProductMonthlyRevenue", {
                    "productId": product_id,
                    "year": year
                }))
            # Nếu không có product_id nhưng có từ khóa "theo tháng" hoặc "doanh thu"
            elif "theo tháng" in query_lower or "monthly" in query_lower or "doanh số" in query_lower or "doanh thu" in query_lower:
                # Extract năm từ query (nếu có)
                year_match = re.search(r"(?:năm|year)\s*(\d{4})", query_lower)
                year = int(year_match.group(1)) if year_match else datetime.now().year
                
                # Gọi function lấy doanh thu theo tháng (tổng)
                self.log(f"🔧 Calling getMonthlyRevenue for year {year}")
                functions.append(("getMonthlyRevenue", {"year": year}))
            
            # Kiểm tra yêu cầu thống kê theo khoảng thời gian
            elif "khoảng" in query_lower or "từ" in query_lower or "đến" in query_lower:
                # Extract dates từ query (có thể cải thiện với NLP)
                # Tạm thời dùng năm hiện tại
                functions.append(("getRevenueStatistics", {
                    "startDate": f"{datetime.now().year}-01-01",
                    "endDate": f"{datetime.now().year}-12-31"
                }))
            else:
                # Default: lấy doanh thu theo tháng năm hiện tại
                self.log(f"🔧 Default: Calling getMonthlyRevenue for current year")
                functions.append(("getMonthlyRevenue", {"year": datetime.now().year}))
        
        return functions
    
    def _extract_product_name(self, query: str) -> Optional[str]:
        """Extract product name từ query"""
        # Simple extraction - có thể cải thiện với NLP
        import re
        # Loại bỏ các từ không cần thiết
        query = re.sub(r"\b(giá|price|thông tin|info|chi tiết|details|mô tả|description)\b", "", query, flags=re.IGNORECASE)
        query = query.strip()
        return query if len(query) > 2 else None
    
    def _extract_order_id(self, query: str) -> Optional[str]:
        """Extract order ID từ query"""
        import re
        # Tìm pattern như "DH-123456" hoặc "order 123"
        match = re.search(r"(?:DH-|order\s+|mã\s+đơn\s+)([A-Z0-9-]+)", query, re.IGNORECASE)
        if match:
            return match.group(1)
        return None
    
    async def _call_function(self, func_name: str, func_args: Dict[str, Any]) -> Optional[Any]:
        """Gọi function thông qua FunctionHandler"""
        try:
            # FunctionHandler sử dụng execute_function với tên function
            # Map tên function sang method name trong FunctionHandler
            function_map = {
                "getMonthlyRevenue": "_get_monthly_revenue",
                "getRevenueStatistics": "_get_revenue_statistics",
                "getProductMonthlyRevenue": "_get_product_monthly_revenue",  # Doanh thu theo product_id
                "get_product_details": "_get_product_details",
                "search_products": "_search_products",
                "get_order_status": "_get_order_status",
                "get_product_price": "_get_product_price",
            }
            
            # Sử dụng execute_function nếu có
            if hasattr(self.function_handler, "execute_function"):
                return await self.function_handler.execute_function(func_name, func_args)
            
            # Fallback: thử gọi trực tiếp
            method_name = function_map.get(func_name, func_name)
            if hasattr(self.function_handler, method_name):
                func = getattr(self.function_handler, method_name)
                if callable(func):
                    # Check if async
                    import inspect
                    if inspect.iscoroutinefunction(func):
                        return await func(func_args)
                    else:
                        return func(func_args)
            
            return None
            
        except Exception as e:
            self.log(f"Error calling function {func_name}: {str(e)}", level="error")
            return None
    
    def _format_context(self, tool_results: List[Dict[str, Any]]) -> str:
        """Format tool results thành context string"""
        if not tool_results:
            return ""
        
        import json
        
        context_parts = []
        for result in tool_results:
            func_name = result.get("function", "unknown")
            func_result = result.get("result")
            
            if func_result:
                # Nếu là JSON string, parse và format đẹp hơn
                if isinstance(func_result, str):
                    try:
                        parsed = json.loads(func_result)
                        if isinstance(parsed, dict):
                            # Format đặc biệt cho doanh thu theo tháng
                            if "monthlyData" in parsed:
                                # Kiểm tra xem có phải doanh thu theo sản phẩm không
                                if "productId" in parsed and "productName" in parsed:
                                    context_parts.append("=== DOANH SỐ THEO THÁNG CỦA SẢN PHẨM ===")
                                    context_parts.append(f"Sản phẩm: {parsed.get('productName', 'N/A')} (Mã: {parsed.get('productId', 'N/A')})")
                                else:
                                    context_parts.append("=== DOANH SỐ THEO THÁNG ===")
                                
                                context_parts.append(f"Năm: {parsed.get('year', 'N/A')}")
                                context_parts.append(f"Tổng doanh thu: {parsed.get('totalRevenue', 0):,.0f} VND")
                                
                                # Thông tin tháng bán chạy nhất (nếu có)
                                if "bestMonth" in parsed and parsed["bestMonth"]:
                                    best = parsed["bestMonth"]
                                    context_parts.append(f"Tháng bán chạy nhất: {best.get('tenThang', 'N/A')} ({best.get('doanhThu', 0):,.0f} VND)")
                                
                                context_parts.append("\nChi tiết theo tháng:")
                                for month_data in parsed.get("monthlyData", []):
                                    thang = month_data.get("tenThang", f"Tháng {month_data.get('thang', 'N/A')}")
                                    doanh_thu = month_data.get("doanhThu", 0)
                                    so_luong = month_data.get("soLuongBan", 0)
                                    if so_luong > 0:
                                        context_parts.append(f"  {thang}: {doanh_thu:,.0f} VND ({so_luong} sản phẩm)")
                                    else:
                                        context_parts.append(f"  {thang}: {doanh_thu:,.0f} VND")
                                context_parts.append("")
                            else:
                                context_parts.append(f"Kết quả từ {func_name}: {json.dumps(parsed, ensure_ascii=False, indent=2)}")
                        else:
                            context_parts.append(f"Kết quả từ {func_name}: {str(func_result)}")
                    except (json.JSONDecodeError, TypeError):
                        context_parts.append(f"Kết quả từ {func_name}: {str(func_result)}")
                else:
                    context_parts.append(f"Kết quả từ {func_name}: {str(func_result)}")
        
        return "\n".join(context_parts)

