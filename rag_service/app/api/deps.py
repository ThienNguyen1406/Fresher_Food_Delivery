"""
Dependency Injection - Khởi tạo và cung cấp dependencies
Quản lý các singleton instances và dependency injection cho toàn bộ ứng dụng
"""
import logging
from app.core.settings import Settings
from app.services.document import DocumentProcessor
from app.services.embedding import EmbeddingService
from app.services.image import ImageEmbeddingService
from app.services.product import ProductEmbeddingService
from app.services.reranker import RerankerService
from app.infrastructure.vector_store.chroma import ChromaVectorStore
from app.infrastructure.vector_store.image_vector_store import ImageVectorStore
from app.infrastructure.vector_store.base import VectorStore
from app.core.rag_pipeline import RAGPipeline
from app.core.ingest_pipeline import IngestPipeline
from app.core.image_ingest_pipeline import ImageIngestPipeline
from app.core.product_ingest_pipeline import ProductIngestPipeline
from app.core.prompt_builder import PromptBuilder

logger = logging.getLogger(__name__)

# ========== Singleton instances (Các instance đơn lẻ) ==========
# Sử dụng singleton pattern để đảm bảo chỉ có 1 instance của mỗi service
_document_processor: DocumentProcessor = None
_embedding_service: EmbeddingService = None
_image_embedding_service: ImageEmbeddingService = None
_product_embedding_service: ProductEmbeddingService = None
_reranker_service: RerankerService = None
_vector_store: VectorStore = None
_image_vector_store: VectorStore = None
_rag_pipeline: RAGPipeline = None
_ingest_pipeline: IngestPipeline = None
_image_ingest_pipeline: ImageIngestPipeline = None
_product_ingest_pipeline: ProductIngestPipeline = None


def get_document_processor() -> DocumentProcessor:
    """
    Lấy instance của DocumentProcessor (singleton)
    
    Returns:
        DocumentProcessor instance
    """
    global _document_processor
    if _document_processor is None:
        _document_processor = DocumentProcessor()
    return _document_processor


def get_embedding_service() -> EmbeddingService:
    """
    Lấy instance của EmbeddingService (singleton)
    
    Returns:
        EmbeddingService instance
    """
    global _embedding_service
    if _embedding_service is None:
        _embedding_service = EmbeddingService()
    return _embedding_service


def get_vector_store() -> VectorStore:
    """
    Lấy instance của VectorStore (singleton)
    Mặc định sử dụng Chroma
    
    Returns:
        VectorStore instance
    """
    global _vector_store
    if _vector_store is None:
        # Sử dụng Chroma làm mặc định
        _vector_store = ChromaVectorStore()
    return _vector_store


def get_reranker_service() -> RerankerService:
    """
    Lấy instance của RerankerService (singleton)
    
    Returns:
        RerankerService instance
    """
    global _reranker_service
    if _reranker_service is None:
        _reranker_service = RerankerService()
    return _reranker_service


def get_rag_pipeline() -> RAGPipeline:
    """
    Lấy instance của RAGPipeline (singleton)
    Tự động inject các dependencies cần thiết
    
    Returns:
        RAGPipeline instance
    """
    global _rag_pipeline
    if _rag_pipeline is None:
        _rag_pipeline = RAGPipeline(
            embedding_service=get_embedding_service(),
            vector_store=get_vector_store(),
            reranker_service=get_reranker_service()
        )
    return _rag_pipeline


def get_ingest_pipeline() -> IngestPipeline:
    """
    Lấy instance của IngestPipeline (singleton)
    Tự động inject các dependencies cần thiết
    
    Returns:
        IngestPipeline instance
    """
    global _ingest_pipeline
    if _ingest_pipeline is None:
        _ingest_pipeline = IngestPipeline(
            document_processor=get_document_processor(),
            embedding_service=get_embedding_service(),
            vector_store=get_vector_store()
        )
    return _ingest_pipeline


def get_image_embedding_service() -> ImageEmbeddingService:
    """
    Lấy instance của ImageEmbeddingService (singleton)
    
    Returns:
        ImageEmbeddingService instance
    """
    global _image_embedding_service
    if _image_embedding_service is None:
        _image_embedding_service = ImageEmbeddingService()
    return _image_embedding_service


def get_image_vector_store() -> VectorStore:
    """
    Lấy instance của ImageVectorStore (singleton)
    Vector store riêng cho images với collection và dimension riêng
    
    Returns:
        ImageVectorStore instance
    """
    global _image_vector_store
    if _image_vector_store is None:
        _image_vector_store = ImageVectorStore()
    return _image_vector_store


def get_image_ingest_pipeline() -> ImageIngestPipeline:
    """
    Lấy instance của ImageIngestPipeline (singleton)
    Tự động inject các dependencies cần thiết
    
    Returns:
        ImageIngestPipeline instance
    """
    global _image_ingest_pipeline
    if _image_ingest_pipeline is None:
        _image_ingest_pipeline = ImageIngestPipeline(
            image_embedding_service=get_image_embedding_service(),
            vector_store=get_image_vector_store()  # Dùng image vector store riêng
        )
    return _image_ingest_pipeline


def get_product_embedding_service() -> ProductEmbeddingService:
    """
    Lấy instance của ProductEmbeddingService (singleton)
    
    Returns:
        ProductEmbeddingService instance
    """
    global _product_embedding_service
    if _product_embedding_service is None:
        _product_embedding_service = ProductEmbeddingService(
            image_embedding_service=get_image_embedding_service(),
            text_embedding_service=get_embedding_service()
        )
    return _product_embedding_service


def get_product_ingest_pipeline() -> ProductIngestPipeline:
    """
    Lấy instance của ProductIngestPipeline (singleton)
    Tự động inject các dependencies cần thiết
    
    Returns:
        ProductIngestPipeline instance
    """
    global _product_ingest_pipeline
    if _product_ingest_pipeline is None:
        _product_ingest_pipeline = ProductIngestPipeline(
            product_embedding_service=get_product_embedding_service(),
            vector_store=get_image_vector_store()
        )
    return _product_ingest_pipeline


def get_prompt_builder() -> PromptBuilder:
    """
    Lấy instance của PromptBuilder
    PromptBuilder là stateless nên không cần singleton
    
    Returns:
        PromptBuilder instance
    """
    return PromptBuilder()

