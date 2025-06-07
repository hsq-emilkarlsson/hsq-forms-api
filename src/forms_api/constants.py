"""
Constants used throughout the HSQ Forms API.

This file contains constants that can be reused across the application.
They should not change during runtime.
"""

# API information
API_TITLE = "HSQ Forms API"
API_VERSION = "1.0.0"
API_DESCRIPTION = "API for flexible form handling"
API_PREFIX = "/api"

# Form constants
MAX_FORM_SIZE_KB = 2048  # 2MB for form data
MAX_FILE_SIZE_MB = 10  # 10MB per file
MAX_FILES_PER_SUBMISSION = 5
ALLOWED_FILE_TYPES = {
    "application/pdf",
    "image/jpeg",
    "image/png",
    "image/gif",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.ms-excel",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "text/plain",
    "text/csv"
}

# Database constants
CASCADE_DELETE = "all, delete-orphan"
DEFAULT_PAGE_SIZE = 50
MAX_PAGE_SIZE = 200

# Storage paths
DEFAULT_UPLOAD_DIR = "uploads"
TEMP_UPLOADS_DIR = "temp-uploads"

# Azure Storage constants
DEFAULT_CONTAINER_NAME = "forms-attachments"
TEMP_CONTAINER_NAME = "temp-uploads"

# Security constants
TOKEN_TYPE = "bearer"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
