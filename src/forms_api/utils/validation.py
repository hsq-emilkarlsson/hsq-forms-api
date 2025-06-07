"""
Validation utilities for HSQ Forms API.

This module contains functions for validating data.
"""

import re
from typing import Dict, List, Optional, Any


def validate_email(email: str) -> bool:
    """Validate email format."""
    pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    return bool(re.match(pattern, email))


def validate_phone(phone: str) -> bool:
    """Validate phone number format."""
    # Remove spaces, dashes, parentheses
    cleaned = re.sub(r"[\s\-\(\)]", "", phone)
    # Allow +46 prefix, or 07 prefix, followed by 8-10 digits
    pattern = r"^(\+46|0)[0-9]{8,10}$"
    return bool(re.match(pattern, cleaned))


def validate_form_submission(form_data: Dict[str, Any], schema: Dict[str, Any]) -> List[str]:
    """
    Validate form submission data against a schema.
    
    Returns a list of validation errors, empty if validation passes.
    """
    errors = []
    required_fields = [field["name"] for field in schema.get("fields", []) 
                    if field.get("required", False)]
    
    # Check required fields
    for field_name in required_fields:
        if field_name not in form_data or not form_data[field_name]:
            errors.append(f"Field '{field_name}' is required")
    
    # Validate field types
    for field in schema.get("fields", []):
        field_name = field.get("name")
        field_type = field.get("type")
        
        if field_name in form_data and form_data[field_name]:
            value = form_data[field_name]
            
            # Email validation
            if field_type == "email" and not validate_email(value):
                errors.append(f"Field '{field_name}' must be a valid email address")
            
            # Number validation
            if field_type == "number" and not isinstance(value, (int, float)):
                try:
                    float(value)
                except (ValueError, TypeError):
                    errors.append(f"Field '{field_name}' must be a valid number")
    
    return errors
