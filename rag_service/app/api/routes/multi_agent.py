"""
Multi-Agent RAG API Routes
"""
from fastapi import APIRouter, UploadFile, File, HTTPException, Query, Body
from pydantic import BaseModel
from typing import Optional, List
import logging
from app.agents.orchestrator import MultiAgentOrchestrator

router = APIRouter()
logger = logging.getLogger(__name__)


class MultiAgentQueryRequest(BaseModel):
    """Request cho Multi-Agent RAG"""
    query: str
    user_description: Optional[str] = None
    category_id: Optional[str] = None
    top_k: int = 5
    enable_critic: bool = True


class MultiAgentQueryResponse(BaseModel):
    """Response từ Multi-Agent RAG"""
    final_answer: str
    query_type: str
    intent: dict
    knowledge_results: List[dict] = []
    tool_results: List[dict] = []
    answer_confidence: float = 0.0
    critic_score: Optional[float] = None
    has_hallucination: bool = False
    metadata: dict = {}


@router.post("/multi-agent/query", response_model=MultiAgentQueryResponse)
async def multi_agent_query(
    request: MultiAgentQueryRequest = Body(...)
):
    """
    Multi-Agent RAG query endpoint (text only)
    """
    try:
        orchestrator = MultiAgentOrchestrator()
        
        state = await orchestrator.process(
            query=request.query,
            user_description=request.user_description,
            category_id=request.category_id,
            top_k=request.top_k,
            enable_critic=request.enable_critic
        )
        
        return MultiAgentQueryResponse(
            final_answer=state.get("final_answer", ""),
            query_type=state.get("query_type", "text"),
            intent=state.get("intent", {}),
            knowledge_results=state.get("knowledge_results", []),
            tool_results=state.get("tool_results", []),
            answer_confidence=state.get("answer_confidence", 0.0),
            critic_score=state.get("critic_score"),
            has_hallucination=state.get("has_hallucination", False),
            metadata=orchestrator.get_state_summary(state)
        )
        
    except Exception as e:
        logger.error(f"Error in multi-agent query: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error processing query: {str(e)}")


@router.post("/multi-agent/query-image", response_model=MultiAgentQueryResponse)
async def multi_agent_query_image(
    image: UploadFile = File(...),
    query: Optional[str] = Query(None),
    user_description: Optional[str] = Query(None),
    category_id: Optional[str] = Query(None),
    top_k: int = Query(5, ge=1, le=50),
    enable_critic: bool = Query(True)
):
    """
    Multi-Agent RAG query endpoint với image
    """
    try:
        # Đọc image data
        image_data = await image.read()
        
        orchestrator = MultiAgentOrchestrator()
        
        state = await orchestrator.process(
            query=query or "",
            image_data=image_data,
            user_description=user_description,
            category_id=category_id,
            top_k=top_k,
            enable_critic=enable_critic
        )
        
        return MultiAgentQueryResponse(
            final_answer=state.get("final_answer", ""),
            query_type=state.get("query_type", "image"),
            intent=state.get("intent", {}),
            knowledge_results=state.get("knowledge_results", []),
            tool_results=state.get("tool_results", []),
            answer_confidence=state.get("answer_confidence", 0.0),
            critic_score=state.get("critic_score"),
            has_hallucination=state.get("has_hallucination", False),
            metadata=orchestrator.get_state_summary(state)
        )
        
    except Exception as e:
        logger.error(f"Error in multi-agent query with image: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error processing query: {str(e)}")


@router.post("/multi-agent/query-batch")
async def multi_agent_query_batch(
    requests: List[MultiAgentQueryRequest] = Body(...),
    max_concurrent: int = Query(3, ge=1, le=10)
):
    """
    Batch Multi-Agent RAG queries
    """
    try:
        orchestrator = MultiAgentOrchestrator()
        
        query_dicts = [
            {
                "query": req.query,
                "user_description": req.user_description,
                "category_id": req.category_id,
                "top_k": req.top_k,
                "enable_critic": req.enable_critic
            }
            for req in requests
        ]
        
        results = await orchestrator.process_batch(query_dicts, max_concurrent=max_concurrent)
        
        return {
            "results": [
                {
                    "final_answer": r.get("final_answer", ""),
                    "query_type": r.get("query_type", "text"),
                    "metadata": orchestrator.get_state_summary(r)
                }
                for r in results
            ]
        }
        
    except Exception as e:
        logger.error(f"Error in batch multi-agent query: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Error processing batch queries: {str(e)}")

