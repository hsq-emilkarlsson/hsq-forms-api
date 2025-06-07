#!/bin/bash
# Script to clean up Python cache files

echo "Cleaning up Python cache files..."

# Find and remove __pycache__ directories
find . -type d -name "__pycache__" -print -exec rm -rf {} +

# Find and remove .pyc files
find . -type f -name "*.pyc" -delete
find . -type f -name "*.pyo" -delete
find . -type f -name "*.pyd" -delete

echo "✅ Python cache files cleaned up!"
