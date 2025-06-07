"""
Security utilities for HSQ Forms API.

This module contains functions for authentication, authorization, and security.
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Union

from fastapi import Depends, HTTPException, Request, Security, status
from fastapi.security import APIKeyHeader, OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext

from src.forms_api.config import get_settings
from src.forms_api.exceptions import AuthenticationException, ForbiddenException

logger = logging.getLogger(__name__)

# Password handling
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 configuration for token-based auth
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token", auto_error=False)

# API Key configuration
settings = get_settings()
api_key_header = APIKeyHeader(name=settings.api_key_header_name, auto_error=False)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify that a plain password matches a hashed password.
    
    Args:
        plain_password: The plain text password
        hashed_password: The hashed password
        
    Returns:
        bool: True if the password matches, False otherwise
    """
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """
    Hash a password using bcrypt.
    
    Args:
        password: The password to hash
        
    Returns:
        str: The hashed password
    """
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Create an access token.
    
    Args:
        data: The data to encode in the token
        expires_delta: How long the token should be valid
        
    Returns:
        str: The encoded JWT token
    """
    settings = get_settings()
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.access_token_expire_minutes
        )
        
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm="HS256")
    return encoded_jwt


async def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Get the current user from a JWT token.
    
    This function is used as a dependency in protected routes.
    
    Args:
        token: JWT token from request
        
    Returns:
        dict: The user data from the token
        
    Raises:
        AuthenticationException: If the token is invalid
    """
    if not token:
        raise AuthenticationException(detail="Not authenticated")
    
    settings = get_settings()
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=["HS256"])
        username = payload.get("sub")
        if username is None:
            raise AuthenticationException(detail="Invalid token")
        # You would typically load user from database here
        return {"username": username}
    except JWTError:
        raise AuthenticationException(detail="Invalid token")


async def validate_api_key(api_key: str = Security(api_key_header)) -> str:
    """
    Validate an API key.
    
    Args:
        api_key: The API key from the request header
        
    Returns:
        str: The API key if valid
        
    Raises:
        AuthenticationException: If the API key is invalid
    """
    settings = get_settings()
    
    if not api_key:
        raise AuthenticationException(detail="API key required")
    
    allowed_keys = settings.allowed_api_keys
    if api_key not in allowed_keys:
        logger.warning(f"Invalid API key attempt: {api_key[:6]}...")
        raise AuthenticationException(detail="Invalid API key")
    
    return api_key


def check_permissions(required_permissions: List[str], user_permissions: List[str]) -> bool:
    """
    Check if a user has the required permissions.
    
    Args:
        required_permissions: Permissions required for an action
        user_permissions: Permissions the user has
        
    Returns:
        bool: True if the user has all required permissions, False otherwise
    """
    return all(perm in user_permissions for perm in required_permissions)
