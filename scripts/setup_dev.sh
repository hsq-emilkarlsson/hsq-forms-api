#!/usr/bin/env bash
# Script to initialize development environment for HSQ Forms API

# Exit immediately if any command fails
set -e

echo "=============================="
echo "HSQ Forms API - Dev Setup"
echo "=============================="

# Create necessary directories
echo "[1/6] Creating directories..."
mkdir -p uploads/temp
mkdir -p logs
mkdir -p backups

# Check if .env file exists, if not create it from example
if [ ! -f .env ]; then
    echo "[2/6] Creating .env file from .env-example..."
    cp .env-example .env
    echo "  Created .env from template. Please update with your settings."
else
    echo "[2/6] .env file already exists."
fi

# Create Python virtual environment if it doesn't exist
if [ ! -d venv ]; then
    echo "[3/6] Creating Python virtual environment..."
    python3 -m venv venv
    echo "  Virtual environment created."
else
    echo "[3/6] Virtual environment already exists."
fi

# Activate the virtual environment
echo "[4/6] Activating virtual environment..."
source venv/bin/activate

# Install Python dependencies
echo "[5/6] Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Set permissions on scripts
echo "[6/6] Setting permissions on scripts..."
chmod +x scripts/*.sh

echo "=============================="
echo "Setup Complete! 🚀"
echo ""
echo "To activate the virtual environment:"
echo "  source venv/bin/activate"
echo ""
echo "To start the development server:"
echo "  make start-dev"
echo ""
echo "To run tests:"
echo "  make test"
echo "=============================="
