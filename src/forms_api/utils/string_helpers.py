"""
String manipulation utilities for HSQ Forms API.

This module contains functions for string operations.
"""

import random
import re
import string
from typing import List, Optional


def camel_to_snake(name: str) -> str:
    """
    Convert camelCase string to snake_case.
    
    Args:
        name: The camelCase string to convert
        
    Returns:
        str: The snake_case string
    """
    name = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', name).lower()


def snake_to_camel(name: str) -> str:
    """
    Convert snake_case string to camelCase.
    
    Args:
        name: The snake_case string to convert
        
    Returns:
        str: The camelCase string
    """
    components = name.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


def generate_random_string(length: int = 10) -> str:
    """
    Generate a random string of fixed length.
    
    Args:
        length: Length of the string (default: 10)
        
    Returns:
        str: Random string
    """
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for _ in range(length))


def truncate_string(text: str, max_length: int = 100, suffix: str = '...') -> str:
    """
    Truncate a string to a specific length and append a suffix if needed.
    
    Args:
        text: The string to truncate
        max_length: Maximum length of the string (default: 100)
        suffix: Suffix to append if truncated (default: '...')
        
    Returns:
        str: Truncated string
    """
    if len(text) <= max_length:
        return text
    return text[:max_length - len(suffix)] + suffix


def safe_str_to_bool(value: Optional[str]) -> bool:
    """
    Convert a string to a boolean safely.
    
    Args:
        value: The string to convert
        
    Returns:
        bool: True if the string is 'true', 'yes', 'y', '1' (case insensitive)
    """
    if not value:
        return False
    return value.lower() in ('true', 'yes', 'y', '1', 'on')


def extract_error_message(error: Exception) -> str:
    """
    Extract a readable error message from an exception.
    
    Args:
        error: The exception
        
    Returns:
        str: A readable error message
    """
    if hasattr(error, 'detail'):
        return str(error.detail)
    return str(error)


def normalize_whitespace(text: str) -> str:
    """
    Normalize whitespace in a string by replacing
    multiple whitespace characters with a single space.
    
    Args:
        text: The string to normalize
        
    Returns:
        str: Normalized string
    """
    return ' '.join(text.split())


def split_and_strip(text: str, delimiter: str = ',') -> List[str]:
    """
    Split a string by delimiter and strip whitespace from each item.
    
    Args:
        text: The string to split
        delimiter: The delimiter to split on (default: ',')
        
    Returns:
        List[str]: List of stripped strings
    """
    if not text:
        return []
    return [item.strip() for item in text.split(delimiter)]
