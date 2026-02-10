"""
__init__ Routes cho Multi Agents 

---> Kiến trúc Multi-Agent:
- Router Agent: Phân loại câu hỏi
- Knowledge Agent: RAG search từ vector store
- Tool Agent: Function calling (database queries)
- Reasoning Agent: Lập kế hoạch xử lý
- Synthesis Agent: Tổng hợp kết quả
- Critic Agent: Kiểm tra hallucination
"""

from app.agents.router_agent import RouterAgent
from app.agents.entity_resolver_agent import EntityResolverAgent
from app.agents.knowledge_agent import KnowledgeAgent
from app.agents.tool_agent import ToolAgent
from app.agents.reasoning_agent import ReasoningAgent
from app.agents.synthesis_agent import SynthesisAgent
from app.agents.critic_agent import CriticAgent
from app.agents.orchestrator import MultiAgentOrchestrator

__all__ = [
    "RouterAgent",
    "EntityResolverAgent",
    "KnowledgeAgent",
    "ToolAgent",
    "ReasoningAgent",
    "SynthesisAgent",
    "CriticAgent",
    "MultiAgentOrrchestrator",
]

