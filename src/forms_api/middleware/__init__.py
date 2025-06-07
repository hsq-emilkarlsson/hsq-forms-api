"""
Middleware module for HSQ Forms API.

This module contains middleware functions that can be applied to the FastAPI application.
"""

import logging
import time
from typing import Callable, Dict

from fastapi import FastAPI, Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)


class LoggingMiddleware(BaseHTTPMiddleware):
    """Middleware for logging requests and responses."""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        start_time = time.time()
        
        # Get client details
        client_host = request.client.host if request.client else "unknown"
        method = request.method
        path = request.url.path
        query = request.url.query
        path_query = f"{path}?{query}" if query else path
        
        # Log request
        logger.info(f"Request: {method} {path_query} from {client_host}")
        
        try:
            # Process the request
            response = await call_next(request)
            
            # Log response
            process_time = time.time() - start_time
            status_code = response.status_code
            logger.info(f"Response: {method} {path} - {status_code} - {process_time:.3f}s")
            
            return response
        except Exception as e:
            # Log exceptions
            process_time = time.time() - start_time
            logger.error(f"Error processing {method} {path}: {str(e)} - {process_time:.3f}s")
            raise


def setup_middlewares(app: FastAPI) -> None:
    """Add all middleware to the FastAPI app."""
    app.add_middleware(LoggingMiddleware)
