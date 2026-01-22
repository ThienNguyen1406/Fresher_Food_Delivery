"""
Text utilities - Text cleaning, chunking, etc.
"""
import re
from typing import List


def clean_text(text: str) -> str:
    """Clean text: remove extra whitespace, normalize"""
    if not text:
        return ""
    
    cleaned = re.sub(r'\s+', ' ', text, flags=re.MULTILINE)
    cleaned = re.sub(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]', '', cleaned)
    
    return cleaned.strip()


def chunk_text(
    text: str, 
    chunk_size: int = 500, 
    chunk_overlap: int = 50
) -> List[tuple]:
    """
    Chunk text into smaller pieces with overlap
    
    Returns:
        List of tuples: (chunk_text, start_index, end_index)
    """
    chunks = []
    cleaned_text = clean_text(text)
    
    if not cleaned_text or not cleaned_text.strip():
        return chunks
    
    start_index = 0
    chunk_index = 0
    
    while start_index < len(cleaned_text):
        end_index = min(start_index + chunk_size, len(cleaned_text))
        
        # Find good break point (end of sentence or paragraph)
        if end_index < len(cleaned_text):
            search_range = min(100, end_index - start_index)
            last_period = cleaned_text.rfind('.', start_index, end_index)
            last_newline = cleaned_text.rfind('\n', start_index, end_index)
            
            best_break = max(last_period, last_newline)
            if best_break > start_index + chunk_size // 2:
                end_index = best_break + 1
        
        chunk_text = cleaned_text[start_index:end_index].strip()
        
        if chunk_text:
            chunks.append((chunk_text, start_index, end_index))
            chunk_index += 1
        
        # Move start_index with overlap
        start_index = max(start_index + 1, end_index - chunk_overlap)
    
    return chunks

