"""
API route handlers.
"""
from src.forms_api.api.routes import forms, submit, enhanced_forms

# Files routes are imported directly in app.py
__all__ = ["forms", "submit", "enhanced_forms"]
