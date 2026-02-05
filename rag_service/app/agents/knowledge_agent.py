"""
Knowledge Agent - RAG search từ vector store
"""
from typing import Dict, Any, List, Optional
import asyncio
import logging
from app.agents.base_agent import BaseAgent
from app.api.deps import get_image_vector_store, get_image_embedding_service, get_embedding_service
from app.infrastructure.vector_store.image_vector_store import ImageVectorStore
from app.services.image import ImageEmbeddingService
from app.services.embedding import EmbeddingService

logger = logging.getLogger(__name__)


class KnowledgeAgent(BaseAgent):
    """
    Knowledge Agent thực hiện RAG search:
    - Text search: Tạo text embedding và search trong vector store
    - Image search: Tạo image embedding và search trong vector store
    - Hybrid search: Kết hợp cả hai
    """
    
    def __init__(
        self,
        vector_store: Optional[ImageVectorStore] = None,
        image_embedding_service: Optional[ImageEmbeddingService] = None,
        text_embedding_service: Optional[EmbeddingService] = None
    ):
        super().__init__("KnowledgeAgent")
        self.vector_store = vector_store
        self.image_embedding_service = image_embedding_service
        self.text_embedding_service = text_embedding_service
    
    async def process(self, state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Thực hiện RAG search dựa trên query type
        
        Returns:
            Updated state with:
                - knowledge_results: List of search results
                - knowledge_context: Formatted context from results
        """
        query_type = state.get("query_type", "text")
        query = state.get("query", "").strip()
        user_description = state.get("user_description", "")
        image_data = state.get("image_data")
        category_id = state.get("category_id")
        top_k = state.get("top_k", 5)
        
        # Lazy load services if not provided
        if not self.vector_store:
            self.vector_store = get_image_vector_store()
        if not self.image_embedding_service:
            self.image_embedding_service = get_image_embedding_service()
        if not self.text_embedding_service:
            self.text_embedding_service = get_embedding_service()
        
        knowledge_results = []
        knowledge_context = ""
        
        try:
            if query_type == "image" or query_type == "hybrid":
                # Image search
                if image_data:
                    self.log("🔍 Performing image search...")
                    image_results = await self._search_by_image(
                        image_data=image_data,
                        category_id=category_id,
                        top_k=top_k
                    )
                    knowledge_results.extend(image_results)
            
            if query_type == "text" or query_type == "hybrid":
                # Text search
                search_text = query or user_description
                if search_text:
                    self.log(f"🔍 Performing text search: '{search_text}'...")
                    text_results = await self._search_by_text(
                        query=search_text,
                        category_id=category_id,
                        top_k=top_k
                    )
                    knowledge_results.extend(text_results)
            
            # Merge và deduplicate results
            knowledge_results = self._merge_results(knowledge_results)
            
            # Format context
            knowledge_context = self._format_context(knowledge_results)
            
            self.log(f"✅ Found {len(knowledge_results)} knowledge results")
            
        except Exception as e:
            self.log(f"❌ Error in knowledge search: {str(e)}", level="error")
            knowledge_results = []
            knowledge_context = ""
        
        # Cập nhật state
        state.update({
            "knowledge_results": knowledge_results,
            "knowledge_context": knowledge_context
        })
        
        return state
    
    async def _search_by_image(
        self,
        image_data: bytes,
        category_id: Optional[str] = None,
        top_k: int = 5
    ) -> List[Dict[str, Any]]:
        """Search products by image"""
        try:
            # Tạo image embedding
            query_embedding = await self.image_embedding_service.create_embedding(image_data)
            
            if query_embedding is None:
                return []
            
            # Build where clause
            where_clause = {"content_type": "product"}
            if category_id:
                where_clause["category_id"] = category_id
            
            # Vector search
            results = await asyncio.to_thread(
                self.vector_store.collection.query,
                query_embeddings=[query_embedding.tolist()],
                n_results=top_k,
                where=where_clause
            )
            
            # Parse results
            products = []
            if results.get('ids') and len(results['ids'][0]) > 0:
                for i in range(len(results['ids'][0])):
                    metadata = results['metadatas'][0][i]
                    distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                    similarity = 1 - distance
                    
                    product = {
                        "product_id": metadata.get('file_id', '') or metadata.get('product_id', ''),
                        "product_name": metadata.get('product_name', ''),
                        "category_id": metadata.get('category_id', ''),
                        "category_name": metadata.get('category_name', ''),
                        "similarity": float(similarity),
                        "price": float(metadata.get('price', 0)) if metadata.get('price') else None,
                        "source": "image_search"
                    }
                    products.append(product)
            
            return products
            
        except Exception as e:
            self.log(f"Error in image search: {str(e)}", level="error")
            return []
    
    async def _search_by_text(
        self,
        query: str,
        category_id: Optional[str] = None,
        top_k: int = 5
    ) -> List[Dict[str, Any]]:
        """Search products by text"""
        try:
            # Tạo text embedding (dùng CLIP text encoder để tương thích với image embeddings)
            query_embedding = self.image_embedding_service.create_text_embedding(query)
            
            if query_embedding is None:
                return []
            
            # Build where clause
            where_clause = {"content_type": "product"}
            if category_id:
                where_clause["category_id"] = category_id
            
            # Vector search
            results = await asyncio.to_thread(
                self.vector_store.collection.query,
                query_embeddings=[query_embedding.tolist()],
                n_results=top_k,
                where=where_clause
            )
            
            # Parse results
            products = []
            if results.get('ids') and len(results['ids'][0]) > 0:
                for i in range(len(results['ids'][0])):
                    metadata = results['metadatas'][0][i]
                    distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 1.0
                    similarity = 1 - distance
                    
                    product = {
                        "product_id": metadata.get('file_id', '') or metadata.get('product_id', ''),
                        "product_name": metadata.get('product_name', ''),
                        "category_id": metadata.get('category_id', ''),
                        "category_name": metadata.get('category_name', ''),
                        "similarity": float(similarity),
                        "price": float(metadata.get('price', 0)) if metadata.get('price') else None,
                        "source": "text_search"
                    }
                    products.append(product)
            
            return products
            
        except Exception as e:
            self.log(f"Error in text search: {str(e)}", level="error")
            return []
    
    def _merge_results(self, results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Merge và deduplicate results từ nhiều sources"""
        seen = {}
        merged = []
        
        for result in results:
            product_id = result.get("product_id")
            if not product_id:
                continue
            
            # Nếu đã có, chọn result có similarity cao hơn
            if product_id in seen:
                existing = seen[product_id]
                if result.get("similarity", 0) > existing.get("similarity", 0):
                    seen[product_id] = result
            else:
                seen[product_id] = result
        
        # Sort by similarity
        merged = sorted(seen.values(), key=lambda x: x.get("similarity", 0), reverse=True)
        
        return merged
    
    def _format_context(self, results: List[Dict[str, Any]]) -> str:
        """Format search results thành context string"""
        if not results:
            return ""
        
        context_parts = []
        for i, result in enumerate(results[:5], 1):  # Top 5 results
            product_name = result.get("product_name", "Unknown")
            category_name = result.get("category_name", "")
            price = result.get("price")
            similarity = result.get("similarity", 0)
            
            context = f"{i}. {product_name}"
            if category_name:
                context += f" (Danh mục: {category_name})"
            if price:
                context += f" - Giá: {price:,.0f} VND"
            context += f" (Độ tương đồng: {similarity:.2%})"
            
            context_parts.append(context)
        
        return "\n".join(context_parts)

