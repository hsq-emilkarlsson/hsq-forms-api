"""
Generic blob storage interface for file storage.
"""
import os
import uuid
import logging
from abc import ABC, abstractmethod
from typing import BinaryIO, Optional, Tuple
from fastapi import UploadFile, HTTPException

logger = logging.getLogger(__name__)

class BlobStorageBase(ABC):
    """Abstract base class for blob storage implementations."""
    
    @abstractmethod
    async def upload_file(self, file: UploadFile, submission_id: str) -> Tuple[str, int, str]:
        """
        Upload file to storage
        
        Args:
            file: The file to upload
            submission_id: ID of the submission the file is attached to
        
        Returns:
            Tuple containing file ID, file size, and content type
        """
        pass
    
    @abstractmethod
    async def get_file(self, file_id: str, submission_id: str) -> Optional[Tuple[BinaryIO, str, int]]:
        """
        Get file from storage
        
        Args:
            file_id: ID of the file to retrieve
            submission_id: ID of the submission the file is attached to
        
        Returns:
            Tuple containing file content, content type, and file size
        """
        pass
    
    @abstractmethod
    async def delete_file(self, file_id: str, submission_id: str) -> bool:
        """
        Delete file from storage
        
        Args:
            file_id: ID of the file to delete
            submission_id: ID of the submission the file is attached to
        
        Returns:
            True if file was successfully deleted, False otherwise
        """
        pass
    
    def _generate_safe_filename(self, original_filename: str) -> str:
        """
        Generate a safe, unique filename for storage
        
        Args:
            original_filename: Original filename provided by the user
        
        Returns:
            Safe filename with UUID prefix
        """
        # Generate a UUID
        file_uuid = str(uuid.uuid4())
        
        # Get the file extension (if any)
        _, file_extension = os.path.splitext(original_filename)
        
        # Create a safe filename with UUID and original extension
        safe_filename = f"{file_uuid}{file_extension}"
        
        return safe_filename
    
    def _check_file_size(self, file_size: int, max_size_mb: int) -> None:
        """
        Check if file size is within allowed limits
        
        Args:
            file_size: Size of the file in bytes
            max_size_mb: Maximum allowed size in megabytes
            
        Raises:
            HTTPException: If file size exceeds the limit
        """
        max_size_bytes = max_size_mb * 1024 * 1024
        
        if file_size > max_size_bytes:
            raise HTTPException(
                status_code=413,
                detail=f"File size exceeds the maximum allowed size of {max_size_mb} MB"
            )
    
    def _validate_content_type(self, content_type: str, allowed_types: list) -> None:
        """
        Validate that the file's content type is allowed
        
        Args:
            content_type: The content type to validate
            allowed_types: List of allowed content types
            
        Raises:
            HTTPException: If content type is not allowed
        """
        if not content_type or content_type not in allowed_types:
            raise HTTPException(
                status_code=415,
                detail=f"Unsupported file type: {content_type}. Allowed types: {', '.join(allowed_types)}"
            )
