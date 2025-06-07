#!/usr/bin/env python
"""
Main entry point for HSQ Forms API.
This is a convenience wrapper to run the application directly from the project root.
"""
import sys
import os
from pathlib import Path

# Add src to Python path
project_root = Path(__file__).parent.absolute()
sys.path.insert(0, str(project_root))

# Import and run the application
from src.main import app

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("src.main:app", host="0.0.0.0", port=8001, reload=True)
