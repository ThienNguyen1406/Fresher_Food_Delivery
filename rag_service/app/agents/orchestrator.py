"""
Multi-Agent Orchestrator - LangGraph-like state machine để điều phối các agents
"""
from typing import Dict, Any, List, Optional
import logging
import asyncio
from app.agents.router_agent import RouterAgent
from app.agents.knowledge_agent import KnowledgeAgent
from app.agents.tool_agent import ToolAgent
from app.agents.reasoning_agent import ReasoningAgent
from app.agents.synthesis_agent import SynthesisAgent
from app.agents.critic_agent import CriticAgent

logger = logging.getLogger(__name__)


class MultiAgentOrchestrator:
    """
    Multi-Agent Orchestrator điều phối các agents theo workflow:
    
    1. Router Agent: Phân loại query
    2. Knowledge Agent: RAG search (nếu cần)
    3. Tool Agent: Function calling (nếu cần)
    4. Reasoning Agent: Lập kế hoạch (nếu cần)
    5. Synthesis Agent: Tổng hợp kết quả
    6. Critic Agent: Kiểm tra hallucination
    """
    
    def __init__(
        self,
        router_agent: Optional[RouterAgent] = None,
        knowledge_agent: Optional[KnowledgeAgent] = None,
        tool_agent: Optional[ToolAgent] = None,
        reasoning_agent: Optional[ReasoningAgent] = None,
        synthesis_agent: Optional[SynthesisAgent] = None,
        critic_agent: Optional[CriticAgent] = None
    ):
        self.router_agent = router_agent or RouterAgent()
        self.knowledge_agent = knowledge_agent or KnowledgeAgent()
        self.tool_agent = tool_agent or ToolAgent()
        self.reasoning_agent = reasoning_agent or ReasoningAgent()
        self.synthesis_agent = synthesis_agent or SynthesisAgent()
        self.critic_agent = critic_agent or CriticAgent()
        
        self.logger = logging.getLogger(f"{__name__}.MultiAgentOrchestrator")
    
    async def process(
        self,
        query: str,
        image_data: Optional[bytes] = None,
        user_description: Optional[str] = None,
        category_id: Optional[str] = None,
        top_k: int = 5,
        enable_critic: bool = True
    ) -> Dict[str, Any]:
        """
        Xử lý query qua Multi-Agent pipeline
        
        Args:
            query: Text query
            image_data: Optional image data
            user_description: Optional user description
            category_id: Optional category filter
            top_k: Number of results to return
            enable_critic: Enable critic agent (default: True)
        
        Returns:
            Final state với final_answer và metadata
        """
        # Khởi tạo state
        state = {
            "query": query,
            "image_data": image_data,
            "user_description": user_description,
            "category_id": category_id,
            "top_k": top_k,
            "enable_critic": enable_critic
        }
        
        self.logger.info(f"🚀 Starting Multi-Agent pipeline for query: {query[:50]}...")
        
        try:
            # Step 1: Router Agent
            self.logger.info("📍 Step 1: Router Agent")
            state = await self.router_agent.process(state)
            
            # Step 2: Knowledge Agent (nếu cần)
            if state.get("needs_knowledge_agent", True):
                self.logger.info("📚 Step 2: Knowledge Agent")
                state = await self.knowledge_agent.process(state)
                self.logger.info(f"📚 Knowledge Agent results: {len(state.get('knowledge_results', []))} products found")
            else:
                self.logger.info("⏭️  Skipping Knowledge Agent")
            
            # Step 3: Tool Agent (nếu cần)
            # QUAN TRỌNG: Với multi-intent, Tool Agent cần chạy SAU Knowledge Agent để có product_id
            needs_tool = state.get("needs_tool_agent", False)
            is_multi_intent = state.get("routing_decision", {}).get("is_multi_intent", False)
            
            if needs_tool:
                self.logger.info("🔧 Step 3: Tool Agent")
                if is_multi_intent:
                    self.logger.info(f"🔧 Multi-intent detected. Knowledge results available: {len(state.get('knowledge_results', []))}")
                state = await self.tool_agent.process(state)
                self.logger.info(f"🔧 Tool Agent executed. Results: {len(state.get('tool_results', []))} functions called")
            else:
                self.logger.info("⏭️  Skipping Tool Agent")
            
            # Step 4: Reasoning Agent (nếu cần)
            if state.get("needs_reasoning", False):
                self.logger.info("🧠 Step 4: Reasoning Agent")
                state = await self.reasoning_agent.process(state)
            else:
                self.logger.info("⏭️  Skipping Reasoning Agent")
            
            # Step 5: Synthesis Agent (luôn chạy)
            self.logger.info("📝 Step 5: Synthesis Agent")
            state = await self.synthesis_agent.process(state)
            
            # Step 6: Critic Agent (nếu enable)
            if enable_critic:
                self.logger.info("🔍 Step 6: Critic Agent")
                state = await self.critic_agent.process(state)
                
                # Nếu có hallucination, có thể re-synthesize
                if state.get("has_hallucination", False):
                    self.logger.warning("⚠️  Hallucination detected, using verified answer")
                    state["final_answer"] = state.get("final_answer_verified", state.get("final_answer", ""))
            else:
                self.logger.info("⏭️  Skipping Critic Agent")
            
            self.logger.info("✅ Multi-Agent pipeline completed")
            
        except Exception as e:
            self.logger.error(f"❌ Error in Multi-Agent pipeline: {str(e)}", exc_info=True)
            # Fallback answer
            state["final_answer"] = "Xin lỗi, đã xảy ra lỗi khi xử lý câu hỏi của bạn. Vui lòng thử lại sau."
            state["error"] = str(e)
        
        return state
    
    async def process_batch(
        self,
        queries: List[Dict[str, Any]],
        max_concurrent: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Xử lý batch queries
        
        Args:
            queries: List of query dicts với keys: query, image_data, user_description, etc.
            max_concurrent: Số lượng queries xử lý đồng thời
        
        Returns:
            List of final states
        """
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def process_with_semaphore(query_dict):
            async with semaphore:
                return await self.process(**query_dict)
        
        tasks = [process_with_semaphore(q) for q in queries]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Xử lý exceptions
        final_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                self.logger.error(f"Error processing query {i}: {str(result)}")
                final_results.append({
                    "final_answer": "Xin lỗi, đã xảy ra lỗi khi xử lý câu hỏi.",
                    "error": str(result)
                })
            else:
                final_results.append(result)
        
        return final_results
    
    def get_state_summary(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """Lấy summary của state (cho logging/debugging)"""
        return {
            "query_type": state.get("query_type"),
            "intent": state.get("intent", {}).get("type"),
            "knowledge_results_count": len(state.get("knowledge_results", [])),
            "tool_results_count": len(state.get("tool_results", [])),
            "has_reasoning": bool(state.get("reasoning_context")),
            "final_answer_length": len(state.get("final_answer", "")),
            "answer_confidence": state.get("answer_confidence", 0),
            "critic_score": state.get("critic_score", 0),
            "has_hallucination": state.get("has_hallucination", False)
        }

