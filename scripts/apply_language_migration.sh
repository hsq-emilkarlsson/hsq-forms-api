#!/bin/bash
# Script to run the language support migration

# Get directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Navigate to project root (parent directory of scripts)
cd "$SCRIPT_DIR/.."

echo "Running Alembic migration for language support..."
alembic upgrade head

echo "Migration completed successfully!"
echo "The database now has multilingual support fields."
echo ""
echo "Next steps:"
echo "1. Update your form templates with translations"
echo "2. Rebuild frontend applications to include the language selector"
echo "3. Test forms in different languages"
