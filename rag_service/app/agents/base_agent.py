"""
Base Agent class - Abstract base class for all agents
"""
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)


class BaseAgent(ABC):
    """Base class for all agents in the Multi-Agent RAG system"""
    
    def __init__(self, name: str):
        self.name = name
        self.logger = logging.getLogger(f"{__name__}.{name}")
    
    @abstractmethod
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process the current state and return updated state
        
        Args:
            state: Current state dictionary containing:
                - query: User query
                - query_type: Type of query (text, image, hybrid, chat)
                - image_data: Optional image data
                - context: Optional context
                - results: Optional results from previous agents
                - reasoning: Optional reasoning steps
                - final_answer: Optional final answer
        
        Returns:
            Updated state dictionary
        """
        pass
    
    def log(self, message: str, level: str = "info"):
        """Log message with agent name"""
        if level == "info":
            self.logger.info(message)
        elif level == "warning":
            self.logger.warning(message)
        elif level == "error":
            self.logger.error(message)
        elif level == "debug":
            self.logger.debug(message)

