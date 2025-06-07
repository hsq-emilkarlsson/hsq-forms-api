"""
Storage service implementations.
"""
import os
import logging
from typing import Tuple, Any

logger = logging.getLogger(__name__)

def get_storage_service() -> Tuple[Any, bool]:
    """
    Factory function to get the appropriate storage service based on configuration.
    Returns a tuple of (storage_service, is_azure)
    """
    try:
        from src.forms_api.config import get_settings
        settings = get_settings()
        
        # Check if Azure Blob Storage is configured
        if settings.AZURE_STORAGE_CONNECTION_STRING:
            try:
                from src.forms_api.services.storage.azure_storage import AzureStorageService
                logger.info("Using Azure Blob Storage for file operations")
                return AzureStorageService(), True
            except ImportError:
                logger.warning("Failed to import AzureStorageService, falling back to local storage")
        else:
            logger.info("Azure Storage not configured, using local storage")
            
        # Fallback to local storage
        from src.forms_api.services.storage.local_storage import LocalFileStorageService
        logger.info("Using Local File Storage for file operations")
        return LocalFileStorageService(), False
        
    except Exception as e:
        logger.error(f"Error configuring storage service: {str(e)}")
        
        # Final fallback to local storage with no dependencies
        from src.forms_api.services.storage.local_storage import LocalFileStorageService
        return LocalFileStorageService(), False
