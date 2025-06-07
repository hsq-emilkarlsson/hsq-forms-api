"""
Main entry point for the HSQ Forms API.

This module creates and configures the FastAPI application instance
with proper logging and settings.
"""
import os
import uvicorn

from src.forms_api.app import create_app
from src.forms_api.config import get_settings
from src.forms_api.utils.logging_config import configure_logging

# Configure logging first
configure_logging()

# Create the FastAPI application
app = create_app()

if __name__ == "__main__":
    settings = get_settings()
    port = int(os.getenv("PORT", "8000"))
    
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=port, 
        reload=settings.debug,
        log_level="debug" if settings.debug else "info"
    )
