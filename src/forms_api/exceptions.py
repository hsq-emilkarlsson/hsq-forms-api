"""
Custom exceptions for HSQ Forms API.

This module defines custom exceptions used throughout the application.
"""
from typing import Any, Dict, List, Optional, Union

from fastapi import HTTPException, status


class BaseAPIException(HTTPException):
    """Base exception for API errors."""
    
    def __init__(
        self, 
        detail: Union[str, Dict[str, Any], List[Dict[str, Any]]] = None,
        status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR,
        headers: Optional[Dict[str, str]] = None
    ):
        super().__init__(status_code=status_code, detail=detail, headers=headers)


class NotFoundException(BaseAPIException):
    """Raised when a resource is not found."""
    
    def __init__(
        self, 
        detail: str = "Requested resource not found",
        headers: Optional[Dict[str, str]] = None
    ):
        super().__init__(
            detail=detail,
            status_code=status.HTTP_404_NOT_FOUND,
            headers=headers
        )


class BadRequestException(BaseAPIException):
    """Raised for invalid request parameters."""
    
    def __init__(
        self, 
        detail: Union[str, Dict[str, Any], List[Dict[str, Any]]] = "Invalid request parameters",
        headers: Optional[Dict[str, str]] = None
    ):
        super().__init__(
            detail=detail,
            status_code=status.HTTP_400_BAD_REQUEST,
            headers=headers
        )


class ValidationException(BadRequestException):
    """Raised for data validation errors."""
    
    def __init__(
        self, 
        detail: Union[str, List[str], Dict[str, Any]] = "Validation error",
        headers: Optional[Dict[str, str]] = None
    ):
        # Convert list of errors to detail format
        if isinstance(detail, list):
            formatted_detail = {"message": "Validation failed", "errors": detail}
        else:
            formatted_detail = detail
            
        super().__init__(detail=formatted_detail, headers=headers)


class UnauthorizedException(BaseAPIException):
    """Raised when authentication fails."""
    
    def __init__(
        self, 
        detail: str = "Authentication required",
        headers: Optional[Dict[str, str]] = None
    ):
        super().__init__(
            detail=detail,
            status_code=status.HTTP_401_UNAUTHORIZED,
            headers=headers
        )


class ForbiddenException(BaseAPIException):
    """Raised when action is forbidden."""
    
    def __init__(
        self, 
        detail: str = "Access forbidden",
        headers: Optional[Dict[str, str]] = None
    ):
        super().__init__(
            detail=detail,
            status_code=status.HTTP_403_FORBIDDEN,
            headers=headers
        )


class StorageException(BaseAPIException):
    """Raised for storage-related errors."""
    
    def __init__(
        self,
        detail: str = "Storage operation failed",
        status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR,
        headers: Optional[Dict[str, str]] = None
    ):
        super().__init__(detail=detail, status_code=status_code, headers=headers)
