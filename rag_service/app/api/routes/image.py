"""
Image API routes - Upload, search, delete images
Pipeline: Image → Image Encoder → Embedding Vector → Vector Database
"""
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import List, Optional
from pathlib import Path
import logging

from app.api.deps import get_image_ingest_pipeline, get_image_vector_store, get_image_embedding_service
from app.core.image_ingest_pipeline import ImageIngestPipeline
from app.infrastructure.vector_store.base import VectorStore
from app.services.image import ImageEmbeddingService

router = APIRouter()
logger = logging.getLogger(__name__)

# Models
class ProcessImageResponse(BaseModel):
    image_id: str
    image_name: str
    message: str
    embedding_dimension: Optional[int] = None

class ImageInfo(BaseModel):
    image_id: str
    image_name: str
    file_type: str
    upload_date: str

class ImageSearchRequest(BaseModel):
    image_bytes: bytes
    top_k: int = 5

class ImageSearchResponse(BaseModel):
    results: List[dict]
    query_image_id: Optional[str] = None

@router.post("/upload", response_model=ProcessImageResponse)
async def upload_image(
    file: UploadFile = File(...),
    image_ingest_pipeline: ImageIngestPipeline = Depends(get_image_ingest_pipeline),
    metadata: Optional[str] = Query(None, description="JSON metadata string")
):
    """
    Upload và xử lý ảnh 
  
    """
    import time
    import json
    start_time = time.time()
    
    try:
        logger.info(f"📤 Nhận request upload ảnh: {file.filename}")
        
        # Kiểm tra file type
        allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
        file_ext = Path(file.filename).suffix.lower()
        
        if file_ext not in allowed_extensions:
            raise HTTPException(
                status_code=400,
                detail=f"File type {file_ext} not supported. Allowed: {allowed_extensions}"
            )
        
        # Đọc ảnh
        contents = await file.read()
        file_size_mb = len(contents) / (1024 * 1024)
        logger.info(f"📦 File size: {file_size_mb:.2f} MB")
        
        # Kiểm tra file size (10MB)
        if len(contents) > 10 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="File size exceeds 10MB limit")
        
        # Parse metadata nếu có
        metadata_dict = None
        if metadata:
            try:
                metadata_dict = json.loads(metadata)
            except json.JSONDecodeError:
                logger.warning(f"Invalid metadata JSON: {metadata}")
        
        # Xử lý ảnh: Image → Embedding Vector → Vector Database
        logger.info(f"🔄 Bắt đầu xử lý ảnh: {file.filename}")
        image_id = await image_ingest_pipeline.process_and_store(
            contents, 
            file.filename,
            metadata=metadata_dict
        )
        
        # Lấy thông tin embedding dimension
        embedding_service = get_image_embedding_service()
        test_embedding = await embedding_service.create_embedding(contents[:1024])  # Sample để lấy dimension
        embedding_dim = len(test_embedding) if test_embedding is not None else None
        
        elapsed_time = time.time() - start_time
        logger.info(f"✅ Hoàn thành upload ảnh {file.filename} trong {elapsed_time:.2f} giây")
        
        return ProcessImageResponse(
            image_id=image_id,
            image_name=file.filename,
            message=f"Image processed and stored successfully in {elapsed_time:.2f}s",
            embedding_dimension=embedding_dim
        )
    
    except HTTPException:
        raise
    except Exception as e:
        elapsed_time = time.time() - start_time
        logger.error(f"❌ Lỗi khi upload ảnh {file.filename} sau {elapsed_time:.2f}s: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500, 
            detail=f"Error processing image: {str(e)}"
        )

@router.post("/upload/batch", response_model=List[ProcessImageResponse])
async def upload_images_batch(
    files: List[UploadFile] = File(...),
    image_ingest_pipeline: ImageIngestPipeline = Depends(get_image_ingest_pipeline)
):
    """
    Upload và xử lý nhiều ảnh cùng lúc (batch)
    """
    import time
    start_time = time.time()
    
    try:
        logger.info(f"📤 Nhận request upload batch {len(files)} ảnh")
        
        # Đọc tất cả ảnh
        images = []
        image_names = []
        
        for file in files:
            # Kiểm tra file type
            allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
            file_ext = Path(file.filename).suffix.lower()
            
            if file_ext not in allowed_extensions:
                logger.warning(f"Skipping {file.filename}: unsupported file type")
                continue
            
            contents = await file.read()
            
            # Kiểm tra file size (10MB)
            if len(contents) > 10 * 1024 * 1024:
                logger.warning(f"Skipping {file.filename}: file too large")
                continue
            
            images.append(contents)
            image_names.append(file.filename)
        
        if not images:
            raise HTTPException(status_code=400, detail="No valid images to process")
        
        # Xử lý batch
        logger.info(f"🔄 Bắt đầu xử lý batch {len(images)} ảnh")
        image_ids = await image_ingest_pipeline.process_and_store_batch(
            images,
            image_names
        )
        
        elapsed_time = time.time() - start_time
        logger.info(f"✅ Hoàn thành upload batch {len(images)} ảnh trong {elapsed_time:.2f} giây")
        
        return [
            ProcessImageResponse(
                image_id=img_id,
                image_name=img_name,
                message=f"Image processed successfully"
            )
            for img_id, img_name in zip(image_ids, image_names)
        ]
    
    except HTTPException:
        raise
    except Exception as e:
        elapsed_time = time.time() - start_time
        logger.error(f"❌ Lỗi khi upload batch ảnh sau {elapsed_time:.2f}s: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500, 
            detail=f"Error processing images: {str(e)}"
        )

@router.post("/search", response_model=ImageSearchResponse)
async def search_similar_images(
    file: UploadFile = File(...),
    top_k: int = Query(5, ge=1, le=50),
    image_embedding_service: ImageEmbeddingService = Depends(get_image_embedding_service),
    vector_store: VectorStore = Depends(get_image_vector_store)
):
    """
    Tìm kiếm ảnh tương tự
    """
    import time
    import numpy as np
    start_time = time.time()
    
    try:
        logger.info(f"🔍 Nhận request tìm kiếm ảnh tương tự: {file.filename}")
        
        # Đọc ảnh query
        contents = await file.read()
        
        # Tạo embedding từ ảnh query
        logger.info(f"🔢 Đang tạo embedding từ ảnh query...")
        query_embedding = await image_embedding_service.create_embedding(contents)
        
        if query_embedding is None:
            raise HTTPException(status_code=500, detail="Không thể tạo embedding từ ảnh query")
        
        # Tìm kiếm trong vector database
        logger.info(f"🔍 Đang tìm kiếm trong vector database (top_k={top_k})...")
        results = await vector_store.search_similar(
            query_embedding=query_embedding,
            top_k=top_k
        )
        
        elapsed_time = time.time() - start_time
        logger.info(f"✅ Tìm thấy {len(results)} kết quả trong {elapsed_time:.2f} giây")
        
        return ImageSearchResponse(
            results=results,
            query_image_id=None
        )
    
    except HTTPException:
        raise
    except Exception as e:
        elapsed_time = time.time() - start_time
        logger.error(f"❌ Lỗi khi tìm kiếm ảnh sau {elapsed_time:.2f}s: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500, 
            detail=f"Error searching images: {str(e)}"
        )

@router.get("", response_model=List[ImageInfo])
async def get_images():
    """
    Lấy danh sách tất cả ảnh đã upload
    """
    try:
        vector_store = get_image_vector_store()
        documents = await vector_store.get_all_documents()
        
        # Filter chỉ lấy ảnh
        images = [
            doc for doc in documents 
            if doc.get('file_type', '').lower() in ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'image']
        ]
        
        logger.info(f"API get_images: Returning {len(images)} images")
        
        return [
            ImageInfo(
                image_id=img.get('file_id', ''),
                image_name=img.get('file_name', ''),
                file_type=img.get('file_type', ''),
                upload_date=img.get('upload_date', '')
            )
            for img in images
        ]
    except Exception as e:
        logger.error(f"Error in get_images: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{image_id}", response_model=ImageInfo)
async def get_image_info(image_id: str):
    """
    Lấy thông tin chi tiết của một ảnh
    """
    try:
        vector_store = get_image_vector_store()
        info = await vector_store.get_document_info(image_id)
        if not info:
            raise HTTPException(status_code=404, detail="Image not found")
        return ImageInfo(**info)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting image info: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{image_id}")
async def delete_image(image_id: str):
    """
    Xóa ảnh và embedding của nó khỏi vector database
    """
    try:
        vector_store = get_image_vector_store()
        await vector_store.delete_document(image_id)
        return {"message": "Image deleted successfully"}
    except Exception as e:
        logger.error(f"Error deleting image: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

