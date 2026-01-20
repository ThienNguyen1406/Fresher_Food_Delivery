# API package
from fastapi import APIRouter
from app.api.routes import document, query

router = APIRouter()

# Include routes
router.include_router(document.router, prefix="/documents", tags=["Documents"])
router.include_router(query.router, prefix="/query", tags=["Query"])

