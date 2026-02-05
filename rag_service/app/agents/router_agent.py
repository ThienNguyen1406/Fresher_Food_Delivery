"""
Router Agent - Phân loại câu hỏi và quyết định luồng xử lý
"""
import re
from typing import Dict, Any, Optional
from app.agents.base_agent import BaseAgent
import logging

logger = logging.getLogger(__name__)


class RouterAgent(BaseAgent):
    """
    Router Agent phân loại câu hỏi và quyết định:
    - Query type: text, image, hybrid, chat
    - Cần agent nào: Knowledge, Tool, hoặc cả hai
    - Độ ưu tiên của từng agent
    """
    
    def __init__(self):
        super().__init__("RouterAgent")
    
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Phân loại câu hỏi và quyết định routing
        
        Returns:
            Updated state with:
                - query_type: "text", "image", "hybrid", "chat"
                - has_image: bool
                - has_text: bool
                - needs_knowledge_agent: bool
                - needs_tool_agent: bool
                - needs_reasoning: bool
                - routing_decision: str
        """
        query = state.get("query", "").strip()
        image_data = state.get("image_data")
        user_description = state.get("user_description", "")
        
        # Phát hiện loại query
        has_image = image_data is not None
        has_text = bool(query) or bool(user_description)
        
        # Xác định query type
        if has_image and has_text:
            query_type = "hybrid"
        elif has_image:
            query_type = "image"
        elif has_text:
            query_type = "text"
        else:
            query_type = "chat"  # Default fallback
        
        # Phân tích intent từ text
        intent = self._analyze_intent(query or user_description)
        
        # Quyết định routing
        routing_decision = self._make_routing_decision(
            query_type=query_type,
            intent=intent,
            has_image=has_image,
            has_text=has_text
        )
        
        # Cập nhật state
        state.update({
            "query_type": query_type,
            "has_image": has_image,
            "has_text": has_text,
            "intent": intent,
            "needs_knowledge_agent": routing_decision.get("use_knowledge", True),
            "needs_tool_agent": routing_decision.get("use_tool", False),
            "needs_reasoning": routing_decision.get("use_reasoning", False),
            "routing_decision": routing_decision,
            "agent_priority": routing_decision.get("priority", ["knowledge"])
        })
        
        self.log(f"✅ Routed query type: {query_type}, intent: {intent}, routing: {routing_decision}")
        
        return state
    
    def _analyze_intent(self, text: str) -> Dict[str, Any]:
        """Phân tích intent từ text query - HỖ TRỢ MULTI-INTENT"""
        if not text:
            return {"type": "unknown", "confidence": 0.0, "intents": []}
        
        text_lower = text.lower()
        
        # Intent patterns
        intents = {
            "product_search": {
                "patterns": [
                    r"\b(tìm|tìm kiếm|search|mua|bán|sản phẩm|món|rau|củ|trái cây|thịt|cá)\b",
                    r"\b(có gì|bán gì|món nào|sản phẩm nào)\b",
                    r"\b(giá|price|cost)\b.*\b(của|về)\b",
                    r"\b(lấy|hiển thị|show|display)\b.*\b(ảnh|hình|image|picture)\b",
                    r"\b(lấy ra|lấy)\b.*\b(hình ảnh|ảnh|hình)\b",  # "lấy ra hình ảnh"
                    r"\b(hình ảnh|ảnh|image)\b",
                ],
                "confidence": 0.9
            },
            "product_info": {
                "patterns": [
                    r"\b(thông tin|info|chi tiết|mô tả)\b.*\b(sản phẩm|món)\b",
                    r"\b(nguồn gốc|xuất xứ|origin)\b",
                    r"\b(hết hạn|expiry|ngày sản xuất)\b",
                ],
                "confidence": 0.8
            },
            "order_status": {
                "patterns": [
                    r"\b(đơn hàng|order|trạng thái|status)\b",
                    r"\b(khi nào|bao giờ|lúc nào)\b.*\b(giao|nhận)\b",
                    r"\b(mã đơn|order id)\b",
                ],
                "confidence": 0.9
            },
            "price_question": {
                "patterns": [
                    r"\b(giá|price|cost|tiền|phí)\b",
                    r"\b(bao nhiêu|nhiều tiền|chi phí)\b",
                ],
                "confidence": 0.8
            },
            "delivery_question": {
                "patterns": [
                    r"\b(giao hàng|delivery|ship|vận chuyển)\b",
                    r"\b(phí ship|phí giao|shipping fee)\b",
                ],
                "confidence": 0.8
            },
            "sales_statistics": {
                "patterns": [
                    r"\b(doanh số|doanh thu|revenue|sales)\b",
                    r"\b(thống kê|statistics|báo cáo|report)\b",
                    r"\b(doanh thu|doanh số)\b.*\b(theo tháng|monthly|theo năm|yearly)\b",  # "doanh thu theo tháng"
                    r"\b(theo tháng|monthly|theo năm|yearly)\b.*\b(của nó|của|nó)\b",  # "theo tháng của nó"
                    r"\b(tổng doanh thu|total revenue)\b",
                ],
                "confidence": 0.9
            },
            "general_chat": {
                "patterns": [
                    r"\b(chào|hello|hi|xin chào)\b",
                    r"\b(cảm ơn|thank|thanks)\b",
                    r"\b(tạm biệt|goodbye|bye)\b",
                ],
                "confidence": 0.7
            }
        }
        
        # PHÁT HIỆN MULTI-INTENT (có thể có nhiều intent trong 1 query)
        detected_intents = []
        
        for intent_name, intent_data in intents.items():
            for pattern in intent_data["patterns"]:
                if re.search(pattern, text_lower):
                    detected_intents.append({
                        "type": intent_name,
                        "confidence": intent_data["confidence"]
                    })
                    break  # Mỗi intent chỉ cần match 1 pattern
        
        # Nếu có nhiều intent → multi-intent
        if len(detected_intents) > 1:
            # Sắp xếp theo confidence
            detected_intents.sort(key=lambda x: x["confidence"], reverse=True)
            return {
                "type": "multi_intent",
                "confidence": max([i["confidence"] for i in detected_intents]),
                "intents": detected_intents,
                "primary_intent": detected_intents[0]["type"],
                "secondary_intents": [i["type"] for i in detected_intents[1:]]
            }
        elif len(detected_intents) == 1:
            return detected_intents[0]
        else:
            return {"type": "unknown", "confidence": 0.0, "intents": []}
    
    def _make_routing_decision(
        self,
        query_type: str,
        intent: Dict[str, Any],
        has_image: bool,
        has_text: bool
    ) -> Dict[str, Any]:
        """Quyết định routing dựa trên query type và intent - HỖ TRỢ MULTI-INTENT"""
        
        intent_type = intent.get("type", "unknown")
        
        # Xử lý multi-intent
        if intent_type == "multi_intent":
            primary_intent = intent.get("primary_intent", "unknown")
            secondary_intents = intent.get("secondary_intents", [])
            
            # Kết hợp routing rules
            use_knowledge = False
            use_tool = False
            use_reasoning = True  # Multi-intent luôn cần reasoning
            priority = []
            
            # Check primary intent
            if primary_intent in ["product_search", "product_info"]:
                use_knowledge = True
                priority.append("knowledge")
            
            if primary_intent == "sales_statistics" or "sales_statistics" in secondary_intents:
                use_tool = True
                priority.append("tool")
            
            # Check secondary intents
            if "product_search" in secondary_intents or "product_info" in secondary_intents:
                use_knowledge = True
                if "knowledge" not in priority:
                    priority.append("knowledge")
            
            if "sales_statistics" in secondary_intents:
                use_tool = True
                if "tool" not in priority:
                    priority.append("tool")
            
            priority.extend(["reasoning", "synthesis"])
            
            return {
                "use_knowledge": use_knowledge,
                "use_tool": use_tool,
                "use_reasoning": use_reasoning,
                "priority": priority,
                "is_multi_intent": True,
                "intents": [primary_intent] + secondary_intents
            }
        
        # Routing rules
        routing_rules = {
            "product_search": {
                "use_knowledge": True,
                "use_tool": False,
                "use_reasoning": True,
                "priority": ["knowledge", "reasoning", "synthesis"]
            },
            "product_info": {
                "use_knowledge": True,
                "use_tool": True,  # Có thể cần query database
                "use_reasoning": True,
                "priority": ["knowledge", "tool", "reasoning", "synthesis"]
            },
            "order_status": {
                "use_knowledge": False,
                "use_tool": True,  # Cần query database
                "use_reasoning": False,
                "priority": ["tool", "synthesis"]
            },
            "price_question": {
                "use_knowledge": True,
                "use_tool": True,
                "use_reasoning": False,
                "priority": ["knowledge", "tool", "synthesis"]
            },
            "delivery_question": {
                "use_knowledge": True,
                "use_tool": False,
                "use_reasoning": False,
                "priority": ["knowledge", "synthesis"]
            },
            "sales_statistics": {
                "use_knowledge": False,  # Doanh số không cần RAG search
                "use_tool": True,  # Cần query database
                "use_reasoning": True,  # Cần phân tích và format
                "priority": ["tool", "reasoning", "synthesis"]
            },
            "general_chat": {
                "use_knowledge": False,
                "use_tool": False,
                "use_reasoning": False,
                "priority": ["synthesis"]
            },
            "unknown": {
                "use_knowledge": True,  # Default: thử RAG
                "use_tool": False,
                "use_reasoning": True,
                "priority": ["knowledge", "reasoning", "synthesis"]
            }
        }
        
        # Lấy routing rule
        rule = routing_rules.get(intent_type, routing_rules["unknown"])
        
        # Điều chỉnh cho image queries
        if query_type == "image" or query_type == "hybrid":
            rule = rule.copy()
            rule["use_knowledge"] = True  # Image search luôn cần knowledge agent
            rule["priority"] = ["knowledge", "reasoning", "synthesis"]
        
        return rule

