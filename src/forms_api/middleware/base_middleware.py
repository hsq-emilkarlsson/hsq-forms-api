"""
Base middleware class for HSQ Forms API.

This module provides a base class for middleware with common functionality.
"""

import logging
from typing import Callable, Dict, Union

from fastapi import FastAPI, Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)


class BaseMiddleware(BaseHTTPMiddleware):
    """
    Base class for application middleware with common functionality.
    
    Inherit from this class to create middleware with access to common
    utility methods and a standardized structure.
    """
    
    def __init__(self, app: FastAPI):
        """
        Initialize middleware.
        
        Args:
            app: The FastAPI application
        """
        super().__init__(app)
        self.app = app
        logger.debug(f"Initialized {self.__class__.__name__}")
        
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Process a request before and after passing it to the next handler.
        
        Args:
            request: The request to process
            call_next: The next handler in the chain
            
        Returns:
            Response: The response from the next handler
        """
        # Run pre-processing
        await self.pre_process(request)
        
        # Call the next middleware or route handler
        response = await call_next(request)
        
        # Run post-processing
        await self.post_process(request, response)
        
        return response
    
    async def pre_process(self, request: Request) -> None:
        """
        Pre-process a request before it reaches the route handler.
        
        Override this method in subclasses to implement pre-processing logic.
        
        Args:
            request: The request to pre-process
        """
        pass
    
    async def post_process(self, request: Request, response: Response) -> None:
        """
        Post-process a response after it leaves the route handler.
        
        Override this method in subclasses to implement post-processing logic.
        
        Args:
            request: The original request
            response: The response from the route handler
        """
        pass
    
    @staticmethod
    def get_client_ip(request: Request) -> str:
        """
        Extract the client IP address from a request.
        
        Args:
            request: The request to extract the IP from
            
        Returns:
            str: The client IP address
        """
        forwarded = request.headers.get("X-Forwarded-For")
        if forwarded:
            return forwarded.split(",")[0]
        return request.client.host if request.client else "unknown"
    
    @staticmethod
    def get_route_name(request: Request) -> str:
        """
        Get the route name for a request.
        
        Args:
            request: The request to get the route for
            
        Returns:
            str: The route name or path
        """
        route = request.scope.get("route")
        if route and hasattr(route, "name") and route.name:
            return route.name
        return request.url.path
