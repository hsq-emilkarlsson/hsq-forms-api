#!/bin/bash
# Script to fix imports in the project
# Convert from "from forms_api..." to "from src.forms_api..."

echo "=================================="
echo "Fixing imports in Python files..."
echo "=================================="

# Find all Python files in the src directory
find src -type f -name "*.py" | while read -r file; do
    echo "Processing $file..."
    # Replace 'from forms_api' with 'from src.forms_api'
    sed -i '' 's/from forms_api/from src.forms_api/g' "$file"
    # Replace 'import forms_api' with 'import src.forms_api'
    sed -i '' 's/import forms_api/import src.forms_api/g' "$file"
done

echo "=================================="
echo "Import paths fixed successfully!"
echo "=================================="
