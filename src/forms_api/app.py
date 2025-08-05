"""
HSQ Forms API application
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import uvicorn
import os

from src.forms_api.db import engine, Base
from src.forms_api import models  # Import models to register them
from src.forms_api.routes import router
from src.forms_api.config import get_settings

# Create tables
Base.metadata.create_all(bind=engine)

# Get settings
settings = get_settings()

# Create rate limiter
limiter = Limiter(key_func=get_remote_address)

# Create FastAPI app with environment-based configuration
app = FastAPI(
    title=settings.api_title,
    description=settings.api_description,
    version=settings.api_version,
    docs_url=settings.api_docs_url,  # None in production
    redoc_url=settings.api_redoc_url,  # None in production
    openapi_url="/openapi.json" if settings.environment != "production" else None
)

# Add rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Add secure CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,  # Environment-specific origins
    allow_credentials=False,  # More secure without credentials
    allow_methods=["GET", "POST", "OPTIONS"],  # Specific methods only
    allow_headers=["Content-Type", "Authorization", "X-API-Key"],  # Specific headers
)

# Include routes
app.include_router(router, prefix="/api")

@app.get("/")
def read_root():
    return {"message": "HSQ Forms API", "version": "2.0.0"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
