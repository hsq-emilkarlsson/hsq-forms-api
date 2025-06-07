"""
FastAPI application factory for HSQ Forms API.

This module creates and configures the FastAPI application with
middleware, routes, and exception handlers.
"""
import logging
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from src.forms_api import __version__
from src.forms_api.api.routes import forms, submit, enhanced_forms
from src.forms_api.api.routes.files_router import router as files_router
from src.forms_api.constants import API_TITLE, API_DESCRIPTION
from src.forms_api.middleware import setup_middlewares
from src.forms_api.handlers import setup_exception_handlers
from src.forms_api.config import get_settings
from src.forms_api.utils.string_helpers import split_and_strip

logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    """
    Create and configure the FastAPI application.
    
    This factory function sets up the FastAPI app with all necessary
    middleware, routes, and exception handlers.
    
    Returns:
        FastAPI: The configured FastAPI application
    """
    settings = get_settings()
    
    app = FastAPI(
        title=settings.api_title,
        description=settings.api_description,
        version=__version__,
        docs_url=settings.api_docs_url,
        redoc_url=settings.api_redoc_url,
        openapi_url=f"{settings.api_prefix}/openapi.json" if settings.api_prefix else "/openapi.json",
        debug=settings.debug
    )

    # Configure CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=settings.cors_allow_credentials,
        allow_methods=split_and_strip(settings.cors_allow_methods),
        allow_headers=split_and_strip(settings.cors_allow_headers),
    )
    
    # Mount static files directory if it exists
    uploads_dir = os.path.abspath(settings.local_storage_path)
    if os.path.isdir(uploads_dir):
        app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")
    
    # Set up application middleware
    setup_middlewares(app)
    
    # Configure exception handlers
    setup_exception_handlers(app)

    # Include routers with API prefix
    api_prefix = settings.api_prefix
    app.include_router(forms.router, prefix=f"{api_prefix}/forms", tags=["Forms"])
    app.include_router(submit.router, prefix=api_prefix, tags=["Legacy Forms"])
    app.include_router(files_router, prefix=f"{api_prefix}/files", tags=["Files"])
    app.include_router(enhanced_forms.router, prefix=f"{api_prefix}/forms", tags=["Enhanced Forms"])
    
    # Create directories if they don't exist
    os.makedirs(settings.local_storage_path, exist_ok=True)
    os.makedirs(settings.temp_upload_dir, exist_ok=True)
    
    logger.info(f"Application created with {settings.environment} configuration")

    @app.get("/", tags=["Health"])
    async def root():
        """Root endpoint that returns API health information."""
        return {"message": "HSQ Forms API is running", "version": __version__}

    return app
