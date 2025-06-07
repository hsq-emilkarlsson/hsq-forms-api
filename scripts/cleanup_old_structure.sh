#!/bin/bash
# Script to clean up old structure after migration is complete
# After running tests and verifying the new structure works,
# run this script to remove old files

echo "=========================================="
echo "Cleaning up old project structure"
echo "=========================================="

# Check if new structure exists
if [ ! -d "src/forms_api" ]; then
    echo "❌ Error: New structure not found. Make sure you've migrated the code."
    exit 1
fi

# Backup the old structure
echo "📦 Creating backup of old structure..."
mkdir -p backups
BACKUP_DIR="backups/backup_old_structure_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup apps directory
if [ -d "apps" ]; then
    echo "- Backing up apps directory..."
    cp -r apps $BACKUP_DIR/
fi

# Backup migrations directory
if [ -d "src/migrations" ]; then
    echo "- Backing up src/migrations directory..."
    mkdir -p $BACKUP_DIR/src
    cp -r src/migrations $BACKUP_DIR/src/
fi

# Backup schemas directory
if [ -d "src/forms_api/schemas" ]; then
    echo "- Backing up src/forms_api/schemas directory..."
    mkdir -p $BACKUP_DIR/src/forms_api
    cp -r src/forms_api/schemas $BACKUP_DIR/src/forms_api/
fi

echo "✅ Backup created at $BACKUP_DIR"

# Remove old structure
echo "🗑️  Removing old files and directories..."

# Remove the apps directory (old structure)
if [ -d "apps" ]; then
    echo "- Removing apps directory..."
    rm -rf apps
fi

# Remove src/migrations (we use root alembic/)
if [ -d "src/migrations" ]; then
    echo "- Removing src/migrations directory..."
    rm -rf src/migrations
fi

# Remove schemas directory (now using schemas.py)
if [ -d "src/forms_api/schemas" ] && [ -f "src/forms_api/schemas.py" ]; then
    echo "- Removing src/forms_api/schemas directory (replaced by schemas.py)..."
    rm -rf src/forms_api/schemas
fi

# Remove any .pyc files and __pycache__ directories
echo "- Cleaning Python cache files..."
find . -type d -name "__pycache__" -exec rm -rf {} +
find . -type f -name "*.pyc" -delete
find . -type f -name "*.pyo" -delete
find . -type f -name "*.pyd" -delete

echo "✅ Old structure removed"

echo "=========================================="
echo "Cleanup completed successfully!"
echo "=========================================="
echo "If you need to restore the backup, run:"
echo "cp -r $BACKUP_DIR/* ."
echo "=========================================="
