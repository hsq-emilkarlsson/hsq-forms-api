"""
Utility functions for HSQ Forms API.

This module contains helper functions that can be used across the application.
"""

import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


def filter_none_values(data: Dict[str, Any]) -> Dict[str, Any]:
    """Remove None values from a dictionary."""
    return {k: v for k, v in data.items() if v is not None}


def safe_get(data: Dict[str, Any], key: str, default: Any = None) -> Any:
    """Safely get a value from a dictionary."""
    return data.get(key, default)


def truncate_string(text: str, max_length: int = 100) -> str:
    """Truncate a string to a maximum length."""
    if not text or len(text) <= max_length:
        return text
    return f"{text[:max_length-3]}..."


def format_log_message(message: str, context: Optional[Dict[str, Any]] = None) -> str:
    """Format a log message with context."""
    if not context:
        return message
    
    context_str = ", ".join(f"{k}={v}" for k, v in context.items())
    return f"{message} [{context_str}]"
