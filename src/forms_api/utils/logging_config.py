"""
Logging configuration for HSQ Forms API.

This module sets up logging for the application with different handlers
and formatters based on the environment.
"""

import logging
import os
import sys
from typing import Dict, Optional

from src.forms_api.config import get_settings

# Log levels
LOG_LEVELS = {
    "debug": logging.DEBUG,
    "info": logging.INFO,
    "warning": logging.WARNING,
    "error": logging.ERROR,
    "critical": logging.CRITICAL,
}


def configure_logging() -> None:
    """
    Configure logging for the application.
    
    This sets up console and file logging based on the environment.
    """
    settings = get_settings()
    log_level_name = settings.log_level.lower()
    log_level = LOG_LEVELS.get(log_level_name, logging.INFO)
    
    # Create logs directory if it doesn't exist
    log_dir = "logs"
    os.makedirs(log_dir, exist_ok=True)
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)
    
    # Clear existing handlers to avoid duplicate logs
    if root_logger.handlers:
        for handler in root_logger.handlers:
            root_logger.removeHandler(handler)
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(log_level)
    console_formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    console_handler.setFormatter(console_formatter)
    root_logger.addHandler(console_handler)
    
    # File handler (only in non-test environments)
    if not settings.testing:
        file_handler = logging.FileHandler(f"{log_dir}/forms_api.log")
        file_handler.setLevel(log_level)
        file_formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
        file_handler.setFormatter(file_formatter)
        root_logger.addHandler(file_handler)
    
    # Set specific log levels for noisy libraries
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    
    # Log startup message
    logging.info(f"Logging configured with level: {log_level_name}")


def get_logger(name: str) -> logging.Logger:
    """
    Get a logger with the given name.
    
    Args:
        name: The name of the logger
        
    Returns:
        logging.Logger: A configured logger
    """
    return logging.getLogger(name)
