from typing import Dict, Any, List, Optional
import logging
import asyncio
from app.agents.router_agent import RouterAgent
from app.agents.entity_resolver_agent import EntityResolverAgent
from app.agents.knowledge_agent import KnowledgeAgent
from app.agents.tool_agent import ToolAgent
from app.agents.reasoning_agent import ReasoningAgent
from app.agents.synthesis_agent import SynthesisAgent
from app.agents.reasoning_synthesis_agent import ReasoningSynthesisAgent
from app.agents.critic_agent import CriticAgent
from app.core.settings import Settings

logger = logging.getLogger(__name__)


class MultiAgentOrchestrator:
    """
    Multi-Agent Orchestrator điều phối các agents theo workflow:
    """
    
    def __init__(
        self,
        router_agent: Optional[RouterAgent] = None,
        entity_resolver_agent: Optional[EntityResolverAgent] = None,
        knowledge_agent: Optional[KnowledgeAgent] = None,
        tool_agent: Optional[ToolAgent] = None,
        reasoning_agent: Optional[ReasoningAgent] = None,
        synthesis_agent: Optional[SynthesisAgent] = None,
        reasoning_synthesis_agent: Optional[ReasoningSynthesisAgent] = None,
        critic_agent: Optional[CriticAgent] = None
    ):
        self.router_agent = router_agent or RouterAgent()
        self.entity_resolver_agent = entity_resolver_agent or EntityResolverAgent()
        self.knowledge_agent = knowledge_agent or KnowledgeAgent()
        self.tool_agent = tool_agent or ToolAgent()
        
        # 🔥 PERFORMANCE: Sử dụng merged agent nếu được enable
        if Settings.USE_MERGED_REASONING_SYNTHESIS:
            self.reasoning_synthesis_agent = reasoning_synthesis_agent or ReasoningSynthesisAgent()
            self.reasoning_agent = None
            self.synthesis_agent = None
            self.logger = logging.getLogger(f"{__name__}.MultiAgentOrchestrator")
            self.logger.info("✅ Using merged ReasoningSynthesisAgent for better performance")
        else:
            self.reasoning_agent = reasoning_agent or ReasoningAgent()
            self.synthesis_agent = synthesis_agent or SynthesisAgent()
            self.reasoning_synthesis_agent = None
            self.logger = logging.getLogger(f"{__name__}.MultiAgentOrchestrator")
            self.logger.info("ℹ️  Using separate ReasoningAgent and SynthesisAgent")
        
        self.critic_agent = critic_agent or CriticAgent()
    
    async def process(
        self,
        query: str,
        image_data: Optional[bytes] = None,
        user_description: Optional[str] = None,
        category_id: Optional[str] = None,
        top_k: int = 5,
        enable_critic: Optional[bool] = None
    ) -> Dict[str, Any]:
        """
        Xử lý query qua Multi-Agent pipeline
        """
        # PERFORMANCE: Determine if Critic should run (confidence-based or env var)
        if enable_critic is None:
            enable_critic = Settings.ENABLE_CRITIC_AGENT
        
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
            #  Router Agent
            self.logger.info("📍 Step 1: Router Agent")
            state = await self.router_agent.process(state)
            
            #  BƯỚC 1: Entity Resolver Agent (nếu cần product search)
            if state.get("needs_knowledge_agent", True):
                self.logger.info("🔍 Step 1.5: Entity Resolver Agent")
                state = await self.entity_resolver_agent.process(state)
                resolved_entity = state.get("entity_normalized")
                if resolved_entity:
                    self.logger.info(f"✅ Resolved entity: '{resolved_entity}'")
                    # Override sub-query với normalized entity
                    if "sub_queries" in state:
                        state["sub_queries"]["product_search"] = resolved_entity
                else:
                    self.logger.warning(f"⚠️ Could not resolve entity from query: {state.get('query', '')[:50]}")
            
            #  Knowledge Agent (nếu cần)
            if state.get("needs_knowledge_agent", True):
                self.logger.info("📚 Step 2: Knowledge Agent")
                
                #  Sử dụng entity từ Entity Resolver hoặc sub-query
                entity_query = state.get("entity_query")  # Từ Entity Resolver (đã normalize)
                sub_queries = state.get("sub_queries", {})
                product_query = entity_query or sub_queries.get("product_search") or sub_queries.get("product_info")
                
                if product_query:
                    self.logger.info(f"📚 Using sub-query for product search: '{product_query}' (original: '{state.get('query', '')[:50]}')")
                    # Tạm thời override query với sub-query
                    original_query = state.get("query", "")
                    state["query"] = product_query
                    state["_original_query"] = original_query  # Backup để restore sau
                
                # Error handling để không crash silent
                knowledge_error = None
                try:
                    state = await self.knowledge_agent.process(state)
                    knowledge_results_count = len(state.get('knowledge_results', []))
                except Exception as e:
                    self.logger.exception("❌ KnowledgeAgent crashed")
                    knowledge_error = str(e)
                    state["knowledge_error"] = knowledge_error
                    state["knowledge_results"] = []
                    state["knowledge_context"] = ""
                    knowledge_results_count = 0
                
                #  Fallback retry nếu không tìm được (và không có error)
                if knowledge_results_count == 0 and product_query and not knowledge_error:
                    self.logger.warning(f"⚠️ Knowledge Agent returned 0 results. Retrying with extracted keywords...")
                    # Extract keywords từ original query
                    try:
                        extracted_product = self.knowledge_agent._extract_product_name_from_query(state.get("_original_query", product_query))
                        if extracted_product and extracted_product != product_query:
                            self.logger.info(f"🔄 Retrying with extracted product name: '{extracted_product}'")
                            state["query"] = extracted_product
                            retry_state = await self.knowledge_agent.process(state)
                            if len(retry_state.get('knowledge_results', [])) > 0:
                                state["knowledge_results"] = retry_state.get("knowledge_results", [])
                                state["knowledge_context"] = retry_state.get("knowledge_context", "")
                                knowledge_results_count = len(state.get('knowledge_results', []))
                                self.logger.info(f"✅ Retry successful: {knowledge_results_count} products found")
                    except Exception as retry_error:
                        self.logger.warning(f"⚠️ Retry also failed: {str(retry_error)}")
                
                # Restore original query
                if "_original_query" in state:
                    state["query"] = state.pop("_original_query")
                
                self.logger.info(f"📚 Knowledge Agent results: {knowledge_results_count} products found")
                
                # Đảm bảo knowledge_results không bị mất
                if knowledge_results_count > 0:
                    product_names = [r.get("product_name", "N/A") for r in state.get('knowledge_results', [])[:3]]
                    self.logger.info(f"📚 Products found: {', '.join(product_names)}")
                else:
                    if knowledge_error:
                        self.logger.error(f"❌ Knowledge Agent error: {knowledge_error}")
                    else:
                        self.logger.warning(f"⚠️ Knowledge Agent returned 0 results for query: {state.get('query', '')[:50]}")
                    
                    #  Nếu user hỏi về sản phẩm cụ thể nhưng không tìm được → return early
                    original_query = state.get("_original_query") or state.get("query", "")
                    resolved_entity = state.get("entity_normalized")
                    if resolved_entity:
                        # User hỏi về sản phẩm cụ thể nhưng không tìm được
                        self.logger.warning(f"🛡️ Hard guard: No products found for entity '{resolved_entity}'. Setting early return flag.")
                        state["entity_not_found"] = True
                        state["early_return"] = True
                        state["early_return_message"] = f"""Xin lỗi, hiện tại chúng tôi không tìm thấy sản phẩm **\"{resolved_entity}\"** trong hệ thống.

Bạn có thể thử:
• Kiểm tra lại chính tả (ví dụ: \"cá hồi\", \"salmon\", \"thịt bò\")
• Xem danh sách sản phẩm theo danh mục
• Liên hệ bộ phận hỗ trợ để được tư vấn

Hoặc bạn muốn:
1️⃣ Xem danh sách sản phẩm tương tự?
2️⃣ Xem doanh thu tổng theo tháng của toàn cửa hàng?"""
            else:
                self.logger.info("⏭️  Skipping Knowledge Agent")
            
            # 🔥 PERFORMANCE: Parallel execution của Tool Agent và Reasoning Agent (nếu có thể)
            needs_tool = state.get("needs_tool_agent", False)
            needs_reasoning = state.get("needs_reasoning", False)
            is_multi_intent = state.get("routing_decision", {}).get("is_multi_intent", False)
            
            # 🔥 FIX 3: Validate entity match trước khi Tool Agent chạy
            knowledge_results = state.get("knowledge_results", [])
            original_query = state.get("_original_query") or state.get("query", "")
            
            if knowledge_results and original_query:
                validated_results = self._validate_product_entity(original_query, knowledge_results)
                if len(validated_results) < len(knowledge_results):
                    self.logger.warning(f"⚠️ Entity validation rejected {len(knowledge_results) - len(validated_results)} products due to entity mismatch")
                    state["knowledge_results"] = validated_results
                    if not validated_results:
                        self.logger.error(f"❌ All products rejected by entity validation. Query: '{original_query[:50]}'")
                        # 🔥 HARD GUARD: Set early return flag
                        resolved_entity = state.get("entity_normalized")
                        if resolved_entity:
                            state["entity_not_found"] = True
                            state["early_return"] = True
                            state["early_return_message"] = f"""Xin lỗi, hiện tại chúng tôi không tìm thấy sản phẩm **\"{resolved_entity}\"** trong hệ thống.

Bạn có thể thử:
• Kiểm tra lại chính tả (ví dụ: \"cá hồi\", \"salmon\", \"thịt bò\")
• Xem danh sách sản phẩm theo danh mục
• Liên hệ bộ phận hỗ trợ để được tư vấn

Hoặc bạn muốn:
1️⃣ Xem danh sách sản phẩm tương tự?
2️⃣ Xem doanh thu tổng theo tháng của toàn cửa hàng?"""
                        else:
                            state["entity_not_found"] = True
                            state["entity_query"] = original_query
            
            #  BACKUP knowledge_results trước khi Tool Agent chạy
            knowledge_results_backup = state.get("knowledge_results", [])
            
            # PERFORMANCE: Parallel execution nếu Tool và Reasoning không phụ thuộc chặt
            if needs_tool and needs_reasoning and Settings.ENABLE_PARALLEL_AGENTS and not is_multi_intent:
                # Tool Agent và Reasoning Agent có thể chạy song song (nếu không phải multi-intent)
                self.logger.info("⚡ Running Tool Agent and Reasoning Agent in parallel...")
                tool_state = state.copy()
                reasoning_state = state.copy()
                
                tool_task = self.tool_agent.process(tool_state)
                reasoning_task = self.reasoning_agent.process(reasoning_state) if self.reasoning_agent else None
                
                if reasoning_task:
                    tool_result, reasoning_result = await asyncio.gather(tool_task, reasoning_task)
                    # Merge results
                    state.update(tool_result)
                    state.update(reasoning_result)
                    self.logger.info(f"✅ Parallel execution completed: Tool ({len(state.get('tool_results', []))} functions), Reasoning")
                else:
                    state = await tool_task
            else:
                # Sequential execution (default hoặc multi-intent)
                if needs_tool:
                    self.logger.info("🔧 Step 3: Tool Agent")
                    if is_multi_intent:
                        self.logger.info(f"🔧 Multi-intent detected. Knowledge results available: {len(state.get('knowledge_results', []))}")
                    
                    state = await self.tool_agent.process(state)
                    self.logger.info(f"🔧 Tool Agent executed. Results: {len(state.get('tool_results', []))} functions called")
                    
                    #  VALIDATION: Nếu có tool_results với product_id nhưng knowledge_results bị mất → restore
                    tool_results = state.get("tool_results", [])
                    if tool_results and len(knowledge_results_backup) > 0:
                        for tool_result in tool_results:
                            func_args = tool_result.get("arguments", {})
                            product_id = func_args.get("productId") or func_args.get("product_id")
                            if product_id:
                                if len(state.get("knowledge_results", [])) == 0:
                                    self.logger.warning(f"⚠️ Knowledge results lost but product_id {product_id} found in tool_results. Restoring...")
                                    state["knowledge_results"] = knowledge_results_backup
                                    self.logger.info(f"✅ Restored {len(knowledge_results_backup)} knowledge results")
                                break
                else:
                    self.logger.info("⏭️  Skipping Tool Agent")
                
                # Reasoning Agent (nếu cần và chưa chạy parallel)
                if needs_reasoning and not (needs_tool and Settings.ENABLE_PARALLEL_AGENTS and not is_multi_intent):
                    self.logger.info("🧠 Step 4: Reasoning Agent")
                    if self.reasoning_agent:
                        state = await self.reasoning_agent.process(state)
                    else:
                        self.logger.info("⏭️  Using merged ReasoningSynthesisAgent (will run later)")
                else:
                    self.logger.info("⏭️  Skipping Reasoning Agent")
            
            #  HARD GUARD: Nếu có early return flag → skip synthesis và return ngay
            if state.get("early_return", False):
                self.logger.info("🛡️ Hard guard triggered: Skipping synthesis due to missing entity data")
                state["final_answer"] = state.get("early_return_message", "Xin lỗi, không tìm thấy thông tin phù hợp.")
                state["answer_confidence"] = 0.0
                self.logger.info("✅ Multi-Agent pipeline completed (early return)")
                return state
            
            #  PERFORMANCE: Sử dụng merged ReasoningSynthesisAgent hoặc separate agents
            #  LOG STATE TRƯỚC KHI SYNTHESIS (debug mâu thuẫn)
            import json
            knowledge_results_before = state.get("knowledge_results", [])
            state_before_synthesis = {
                "knowledge_results_count": len(knowledge_results_before),
                "knowledge_results": [
                    {
                        "product_id": r.get("product_id"),
                        "product_name": r.get("product_name"),
                        "similarity": r.get("similarity")
                    } 
                    for r in knowledge_results_before[:3]
                ],
                "has_knowledge_context": bool(state.get("knowledge_context")),
                "has_tool_context": bool(state.get("tool_context")),
                "has_reasoning_context": bool(state.get("reasoning_context")),
                "tool_results_count": len(state.get("tool_results", []))
            }
            self.logger.info(f"📊 STATE BEFORE SYNTHESIS: {json.dumps(state_before_synthesis, ensure_ascii=False, indent=2)}")
            
            #  VALIDATION: Đảm bảo knowledge_results không bị mất trước khi synthesis
            if len(knowledge_results_before) > 0:
                self.logger.info(f"✅ Knowledge results available: {len(knowledge_results_before)} products")
                product_names = [r.get("product_name", "N/A") for r in knowledge_results_before[:3]]
                self.logger.info(f"✅ Product names: {', '.join(product_names)}")
            else:
                self.logger.warning(f"⚠️ No knowledge results before synthesis for query: {state.get('query', '')[:50]}")
            
            #  PERFORMANCE: Sử dụng merged agent nếu có
            if self.reasoning_synthesis_agent:
                self.logger.info("🧠📝 Step 4-5: ReasoningSynthesisAgent (merged - 1 LLM call)")
                state = await self.reasoning_synthesis_agent.process(state)
            else:
                # Fallback: Separate agents (nếu không dùng merged)
                if needs_reasoning and self.reasoning_agent:
                    self.logger.info("🧠 Step 4: Reasoning Agent")
                    state = await self.reasoning_agent.process(state)
                
                self.logger.info("📝 Step 5: Synthesis Agent")
                state = await self.synthesis_agent.process(state)
            
            #  VALIDATION: Kiểm tra knowledge_results sau synthesis
            knowledge_results_after = state.get("knowledge_results", [])
            if len(knowledge_results_before) > 0 and len(knowledge_results_after) == 0:
                self.logger.error(f"❌ CRITICAL: knowledge_results bị mất sau synthesis! Trước: {len(knowledge_results_before)}, Sau: {len(knowledge_results_after)}")
                # Khôi phục knowledge_results
                state["knowledge_results"] = knowledge_results_before
                self.logger.info(f"✅ Restored {len(knowledge_results_before)} knowledge results")
            
            #  PERFORMANCE: Critic Agent chỉ chạy nếu enable và confidence thấp
            answer_confidence = state.get("answer_confidence", 1.0)
            should_run_critic = enable_critic and (
                answer_confidence < Settings.CRITIC_CONFIDENCE_THRESHOLD or
                state.get("entity_not_found", False) or
                len(knowledge_results_before) == 0
            )
            
            if should_run_critic:
                self.logger.info(f"🔍 Step 6: Critic Agent (confidence: {answer_confidence:.2f} < {Settings.CRITIC_CONFIDENCE_THRESHOLD})")
                state = await self.critic_agent.process(state)
                
                # Nếu có hallucination, có thể re-synthesize
                if state.get("has_hallucination", False):
                    self.logger.warning("⚠️  Hallucination detected, using verified answer")
                    state["final_answer"] = state.get("final_answer_verified", state.get("final_answer", ""))
            else:
                self.logger.info(f"⏭️  Skipping Critic Agent (confidence: {answer_confidence:.2f} >= {Settings.CRITIC_CONFIDENCE_THRESHOLD})")
            
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
    
    def _validate_product_entity(self, user_query: str, knowledge_results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Hard constraint validation - reject products không match entity
        Guardrail chống nhầm sản phẩm
        """
        if not user_query or not knowledge_results:
            return knowledge_results
        
        import re
        from difflib import SequenceMatcher
        
        # Extract keywords từ query (nouns - tên sản phẩm)
        query_lower = user_query.lower()
        stopwords = {
            "hình", "ảnh", "hình ảnh", "lấy", "ra", "và", "của", "nó", "theo", "tháng",
            "doanh", "thu", "số", "thống", "kê", "về", "với", "cho", "từ", "đến"
        }
        query_clean = re.sub(r'[^\w\s]', ' ', query_lower)
        keywords = [w for w in query_clean.split() if w and w not in stopwords and len(w) > 2]
        
        if not keywords:
            # Không extract được keywords → accept tất cả (fallback)
            return knowledge_results
        
        # Synonym map cho entity matching
        synonym_map = {
            "cá hồi": ["cá hồi", "salmon", "cá hồi na uy", "cá hồi tươi"],
            "thịt bò": ["thịt bò", "beef", "thịt bò tươi"],
            "thịt heo": ["thịt heo", "pork", "thịt lợn"],
            "gà": ["gà", "chicken", "gà ta", "gà công nghiệp"],
            "tôm": ["tôm", "shrimp", "tôm sú", "tôm hùm"],
        }
        
        validated = []
        for result in knowledge_results:
            product_name = result.get("product_name", "")
            product_name_lower = product_name.lower()
            
            # 🔥 BONUS: Guardrail chống nhầm sản phẩm với synonym + fuzzy match
            matched = False
            for keyword in keywords:
                keyword_lower = keyword.lower()
                
                # Exact match
                if keyword_lower in product_name_lower:
                    matched = True
                    break
                
                # Synonym match
                for main_term, synonyms in synonym_map.items():
                    if keyword_lower in main_term or main_term in keyword_lower:
                        if any(syn in product_name_lower for syn in synonyms):
                            matched = True
                            break
                    if matched:
                        break
                
                if matched:
                    break
                
                # Fuzzy match (cho phép typo nhỏ)
                product_words = product_name_lower.split()
                for word in product_words:
                    if len(word) >= 3 and len(keyword_lower) >= 3:
                        similarity = SequenceMatcher(None, keyword_lower, word).ratio()
                        if similarity > 0.7:  # 70% similarity
                            matched = True
                            break
                if matched:
                    break
            
            if matched:
                validated.append(result)
            else:
                # 🔥 BONUS: Raise warning với entity mismatch
                self.logger.warning(f"❌ Entity mismatch: '{product_name}' does not match keywords {keywords} from query '{user_query[:50]}'")
        
        return validated
    
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


