"""
File handling utilities for HSQ Forms API.

This module contains utility functions for file operations.
"""

import logging
import os
from typing import List, Optional, Tuple
from uuid import uuid4

from fastapi import UploadFile

from src.forms_api.constants import ALLOWED_FILE_TYPES, MAX_FILE_SIZE_MB
from src.forms_api.exceptions import ValidationException

logger = logging.getLogger(__name__)


async def save_uploaded_file(
    upload_file: UploadFile, 
    directory: str, 
    allowed_types: Optional[List[str]] = None,
    max_size_mb: Optional[int] = None
) -> Tuple[str, str]:
    """
    Save an uploaded file to the specified directory with validation.
    
    Args:
        upload_file: The file to save
        directory: Directory where the file should be saved
        allowed_types: List of allowed MIME types (default: uses ALLOWED_FILE_TYPES constant)
        max_size_mb: Maximum file size in MB (default: uses MAX_FILE_SIZE_MB constant)
        
    Returns:
        Tuple[str, str]: A tuple of (filename, file_path)
        
    Raises:
        ValidationException: If file validation fails
    """
    # Use values from constants if not provided
    if allowed_types is None:
        allowed_types = list(ALLOWED_FILE_TYPES)
    if max_size_mb is None:
        max_size_mb = MAX_FILE_SIZE_MB

    # Validate file type
    if upload_file.content_type not in allowed_types:
        raise ValidationException(
            detail=f"Unsupported file type: {upload_file.content_type}. Allowed types: {', '.join(allowed_types)}"
        )
    
    # Validate file size
    file_size = await get_file_size(upload_file)
    max_size_bytes = max_size_mb * 1024 * 1024
    if file_size > max_size_bytes:
        raise ValidationException(
            detail=f"File is too large: {file_size / (1024 * 1024):.2f} MB. Maximum size allowed: {max_size_mb} MB"
        )
    
    # Create a unique filename to avoid collisions
    filename = f"{uuid4().hex}_{upload_file.filename}"
    file_path = os.path.join(directory, filename)
    
    # Ensure directory exists
    os.makedirs(directory, exist_ok=True)
    
    # Save the file
    with open(file_path, "wb") as buffer:
        # Reset file to beginning after size check
        await upload_file.seek(0)
        content = await upload_file.read()
        buffer.write(content)
    
    logger.info(f"File saved: {file_path}")
    return filename, file_path


async def get_file_size(upload_file: UploadFile) -> int:
    """
    Get the size of an UploadFile in bytes.
    
    Args:
        upload_file: The file to check
        
    Returns:
        int: Size of the file in bytes
    """
    await upload_file.seek(0, 2)  # Move to the end of the file
    size = upload_file.tell()     # Get current position (size)
    await upload_file.seek(0)     # Reset file position
    return size


def is_safe_filepath(filepath: str) -> bool:
    """
    Check if a filepath is safe (no directory traversal).
    
    Args:
        filepath: The filepath to check
        
    Returns:
        bool: True if the filepath is safe, False otherwise
    """
    normalized = os.path.normpath(filepath)
    return not (
        "../" in normalized or 
        normalized.startswith("/") or 
        normalized.startswith("\\")
    )
