#!/bin/bash

# HSQ Forms - New Form Creation Script
# This script creates a new form based on the react-form-template

set -e

echo "🎯 HSQ Forms - New Form Creator"
echo "==============================="

# Check if form name is provided
if [ -z "$1" ]; then
    echo "❌ Please provide a form name"
    echo "Usage: ./scripts/create-new-form.sh <form-name>"
    echo "Example: ./scripts/create-new-form.sh hsq-contact-form"
    exit 1
fi

FORM_NAME="$1"
TEMPLATE_DIR="templates/react-form-template"
FORMS_DIR="forms"
NEW_FORM_DIR="$FORMS_DIR/$FORM_NAME"

# Check if template exists
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "❌ Template directory not found: $TEMPLATE_DIR"
    exit 1
fi

# Check if form already exists
if [ -d "$NEW_FORM_DIR" ]; then
    echo "❌ Form already exists: $NEW_FORM_DIR"
    exit 1
fi

# Create forms directory if it doesn't exist
mkdir -p "$FORMS_DIR"

echo "📁 Creating new form: $FORM_NAME"
echo "📋 Template: $TEMPLATE_DIR"
echo "🎯 Destination: $NEW_FORM_DIR"
echo ""

# Copy template
echo "📦 Copying template..."
cp -r "$TEMPLATE_DIR" "$NEW_FORM_DIR"

# Update package.json name
echo "📝 Updating package.json..."
if command -v jq >/dev/null 2>&1; then
    # Use jq if available
    jq --arg name "$FORM_NAME" '.name = $name' "$NEW_FORM_DIR/package.json" > "$NEW_FORM_DIR/package.json.tmp"
    mv "$NEW_FORM_DIR/package.json.tmp" "$NEW_FORM_DIR/package.json"
else
    # Fallback to sed
    sed -i.bak "s/\"name\": \"react-form-template\"/\"name\": \"$FORM_NAME\"/" "$NEW_FORM_DIR/package.json"
    rm "$NEW_FORM_DIR/package.json.bak" 2>/dev/null || true
fi

# Update README.md
echo "📖 Updating README..."
cat > "$NEW_FORM_DIR/README.md" << EOF
# $FORM_NAME

A React-based form application using the HSQ Forms API backend.

## Features
- React Hook Form with Zod validation
- Multi-language support (Swedish, English, German)
- Responsive design with Tailwind CSS
- Docker containerization
- HSQ Forms API integration

## Development

1. Install dependencies:
\`\`\`bash
npm install
\`\`\`

2. Start development server:
\`\`\`bash
npm run dev
\`\`\`

3. Open browser at http://localhost:5173

## Production Deployment

1. Build and run with Docker:
\`\`\`bash
docker-compose up --build
\`\`\`

2. Access at http://localhost:3000

## Customization

- **Form Fields**: Edit \`src/components/Form.tsx\`
- **Translations**: Update \`src/i18n.js\`
- **Styling**: Modify Tailwind CSS classes
- **API Config**: Update \`.env\` file

## API Integration

This form submits data to the HSQ Forms API. Make sure the API is running:

\`\`\`bash
# From the main project directory
./scripts/deploy-container.sh local
\`\`\`

The form will be available at:
- Development: http://localhost:5173
- Production: http://localhost:3000
EOF

echo "🔧 Setting up environment..."
# Ensure .env file exists with default values
if [ ! -f "$NEW_FORM_DIR/.env" ]; then
    cat > "$NEW_FORM_DIR/.env" << EOF
VITE_API_URL=http://localhost:8000
VITE_FORM_TEMPLATE_NAME=$FORM_NAME
EOF
fi

echo ""
echo "✅ New form created successfully!"
echo ""
echo "📁 Form location: $NEW_FORM_DIR"
echo ""
echo "🚀 Next steps:"
echo "1. cd $NEW_FORM_DIR"
echo "2. npm install"
echo "3. npm run dev"
echo ""
echo "🎨 Customize your form:"
echo "- Edit src/components/Form.tsx for form fields"
echo "- Update src/i18n.js for translations"
echo "- Modify .env for API configuration"
echo ""
echo "🐳 For production deployment:"
echo "- docker-compose up --build"
