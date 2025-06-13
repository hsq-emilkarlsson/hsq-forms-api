#!/bin/bash

# 🛑 Stop All B2B Support Form Containers

echo "🛑 Stopping B2B Support Form Container Solution"
echo "==============================================="

cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api

# Stop backend services
echo "🔧 Stopping backend services..."
docker-compose down

# Stop frontend container
echo "🎨 Stopping frontend container..."
cd forms/hsq-forms-container-b2b-support
docker-compose down

cd ../..

# Show final status
echo ""
echo "📊 Remaining containers:"
docker ps --filter "name=hsq-forms" --format "table {{.Names}}\t{{.Status}}" || echo "No hsq-forms containers running"

echo ""
echo "✅ All B2B support form containers stopped"
