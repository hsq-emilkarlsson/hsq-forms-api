#!/bin/bash

# HSQ Forms - Container Form Copy Script
# This script copies an existing container form to create a new one

set -e

echo "📋 HSQ Forms - Container Form Copier"
echo "===================================="

# Check if source and target names are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "❌ Please provide source and target form names"
    echo "Usage: ./scripts/copy-container-form.sh <source-form> <new-form-name>"
    echo ""
    echo "Available source forms:"
    ls -1 forms/ | grep hsq-forms-container- | sed 's/^/  - /'
    exit 1
fi

SOURCE_FORM="$1"
NEW_FORM_NAME="$2"
FORMS_DIR="forms"
SOURCE_DIR="$FORMS_DIR/$SOURCE_FORM"
TARGET_DIR="$FORMS_DIR/$NEW_FORM_NAME"

# Validate source form exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Source form not found: $SOURCE_DIR"
    echo ""
    echo "Available forms:"
    ls -1 forms/ | grep hsq-forms-container- | sed 's/^/  - /'
    exit 1
fi

# Check if target form already exists
if [ -d "$TARGET_DIR" ]; then
    echo "❌ Target form already exists: $TARGET_DIR"
    exit 1
fi

echo "📁 Source: $SOURCE_DIR"
echo "🎯 Target: $TARGET_DIR"
echo ""

# Copy the source form
echo "📦 Copying form structure..."
cp -r "$SOURCE_DIR" "$TARGET_DIR"

# Clean up copied files that shouldn't be duplicated
echo "🧹 Cleaning up copied files..."
rm -rf "$TARGET_DIR/node_modules" 2>/dev/null || true
rm -rf "$TARGET_DIR/dist" 2>/dev/null || true
rm -f "$TARGET_DIR/package-lock.json" 2>/dev/null || true
rm -f "$TARGET_DIR/.env" 2>/dev/null || true

# Update package.json name
echo "📝 Updating package.json..."
if command -v jq >/dev/null 2>&1; then
    # Use jq if available
    jq --arg name "$NEW_FORM_NAME" '.name = $name' "$TARGET_DIR/package.json" > "$TARGET_DIR/package.json.tmp"
    mv "$TARGET_DIR/package.json.tmp" "$TARGET_DIR/package.json"
else
    # Fallback to sed
    sed -i.bak "s/\"name\": \"$SOURCE_FORM\"/\"name\": \"$NEW_FORM_NAME\"/" "$TARGET_DIR/package.json"
    rm "$TARGET_DIR/package.json.bak" 2>/dev/null || true
fi

# Create new .env file
echo "🔧 Creating environment file..."
cat > "$TARGET_DIR/.env" << EOF
# Environment configuration for $NEW_FORM_NAME
VITE_API_BASE_URL=http://localhost:8000
VITE_FORM_NAME=$NEW_FORM_NAME
NODE_ENV=development
EOF

# Update README.md
echo "📖 Creating README..."
cat > "$TARGET_DIR/README.md" << EOF
# $NEW_FORM_NAME

A React-based form application using the HSQ Forms API backend.
Based on the $SOURCE_FORM template.

## Features
- React Hook Form with Zod validation
- Multi-language support (Swedish, English, German)
- Responsive design with Tailwind CSS
- Docker containerization ready
- HSQ Forms API integration

## Quick Start

1. Install dependencies:
\`\`\`bash
cd $TARGET_DIR
npm install
\`\`\`

2. Start development server:
\`\`\`bash
npm run dev
\`\`\`

3. Open browser at http://localhost:5173

## Customization

- **Form Fields**: Edit \`src/components/Form.tsx\`
- **Translations**: Update \`src/i18n.js\`
- **Styling**: Modify Tailwind CSS classes
- **API Integration**: Update \`src/services/api.js\`

## Production Deployment

1. Build the application:
\`\`\`bash
npm run build
\`\`\`

2. Use Docker for containerized deployment:
\`\`\`bash
docker-compose up --build
\`\`\`

## Form Configuration

Remember to update the following for your specific form:
- Form field definitions in the main component
- Translation strings for all supported languages
- Validation schema (Zod)
- API endpoint configuration
EOF

echo ""
echo "✅ Form copied successfully!"
echo ""
echo "Next steps:"
echo "1. cd $TARGET_DIR"
echo "2. npm install"
echo "3. npm run dev"
echo "4. Customize the form components as needed"
echo ""
echo "📁 New form location: $TARGET_DIR"
