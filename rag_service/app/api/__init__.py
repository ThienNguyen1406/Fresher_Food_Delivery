# API package
from fastapi import APIRouter
from app.api.routes import document, query, function, health

router = APIRouter()

# Include routes
router.include_router(document.router, prefix="/documents", tags=["Documents"])
router.include_router(query.router, prefix="/query", tags=["Query"])
router.include_router(function.router, prefix="/functions", tags=["Functions"])
router.include_router(health.router, prefix="/health", tags=["Health"])

