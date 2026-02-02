"""
Image Attribute Extractor - Extract structured attributes from product images
CHỈ DÙNG KHI: ingest, admin review, build metadata
KHÔNG DÙNG TRONG: search flow (search chỉ dùng CLIP embedding)
"""
import logging
import json
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)


class ImageAttributeExtractor:
    """Extract structured JSON attributes from product images using Vision LLM"""
    
    def __init__(self, llm_provider):
        self.llm_provider = llm_provider
    
    async def extract_attributes(self, image_bytes: bytes) -> Optional[Dict[str, Any]]:
        """
        Extract structured attributes from image as JSON
        """
        if not self.llm_provider or not hasattr(self.llm_provider, 'client') or not self.llm_provider.client:
            logger.warning("⚠️  LLM provider không khả dụng, bỏ qua attribute extraction")
            return None
        
        try:
            import base64
            image_base64 = base64.b64encode(image_bytes).decode('utf-8')
            
            system_message = """You are an image attribute extraction engine for an e-commerce search system.
                                Extract ONLY visually observable attributes.
                                No brand names. No product names. No guessing."""

            vision_prompt = """Analyze the product image and output a JSON object.

                                Rules:
                                - Only include what is clearly visible.
                                - If an attribute is unclear, use null.
                                - Do NOT infer brand, product name, flavor, or ingredients.
                                - Do NOT write full sentences.

                                JSON schema:
                                {
                                "packaging_type": "",
                                "material": "",
                                "shape": "",
                                "primary_colors": [],
                                "secondary_colors": [],
                                "text_present": true/false,
                                "text_style": "",
                                "graphics": "",
                                "size_impression": "",
                                "generic_category": ""
                                }

                                Output ONLY valid JSON, no other text."""
            
            vision_response = self.llm_provider.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": system_message},
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": vision_prompt},
                            {
                                "type": "image_url",
                                "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}
                            }
                        ]
                    }
                ],
                max_tokens=300,
                temperature=0.1,
                response_format={"type": "json_object"}  # 🔥 Force JSON output
            )
            
            response_text = vision_response.choices[0].message.content.strip()
            
            # Check rejection
            response_lower = response_text.lower()
            rejection_keywords = [
                "i'm sorry", "i can't help", "i cannot", "i can't assist",
                "i'm not able", "i'm unable", "cannot identify", "can't identify"
            ]
            if any(kw in response_lower for kw in rejection_keywords):
                logger.warning("⚠️  Vision model đã từ chối extract attributes")
                return None
            
            # Parse JSON
            try:
                attributes = json.loads(response_text)
                logger.info(f"✅ Đã extract image attributes: {len(attributes)} fields")
                return attributes
            except json.JSONDecodeError as e:
                logger.warning(f"⚠️  Không thể parse JSON từ Vision response: {e}")
                logger.debug(f"Response text: {response_text[:200]}")
                return None
                
        except Exception as e:
            logger.warning(f"⚠️  Lỗi khi extract image attributes: {str(e)}")
            return None
    
    def attributes_to_text(self, attributes: Dict[str, Any]) -> str:
        """
        Convert JSON attributes to searchable text for embedding
        Chỉ dùng khi ingest để tạo text embedding từ attributes
        """
        if not attributes:
            return ""
        
        parts = []
        
        if attributes.get("packaging_type"):
            parts.append(f"packaging: {attributes['packaging_type']}")
        if attributes.get("material"):
            parts.append(f"material: {attributes['material']}")
        if attributes.get("shape"):
            parts.append(f"shape: {attributes['shape']}")
        if attributes.get("primary_colors"):
            parts.append(f"colors: {', '.join(attributes['primary_colors'])}")
        if attributes.get("generic_category"):
            parts.append(f"category: {attributes['generic_category']}")
        if attributes.get("text_present"):
            parts.append("has text")
        if attributes.get("graphics"):
            parts.append(f"graphics: {attributes['graphics']}")
        if attributes.get("size_impression"):
            parts.append(f"size: {attributes['size_impression']}")
        
        return ". ".join(parts)

