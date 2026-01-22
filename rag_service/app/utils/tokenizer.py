"""
Tokenizer utilities
"""
from typing import List


def count_tokens(text: str) -> int:
    """Simple token counter (approximate)"""
    # Simple approximation: 1 token ≈ 4 characters
    return len(text) // 4


def truncate_text(text: str, max_tokens: int) -> str:
    """Truncate text to max tokens"""
    max_chars = max_tokens * 4
    if len(text) <= max_chars:
        return text
    return text[:max_chars] + "..."

