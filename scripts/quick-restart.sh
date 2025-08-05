#!/bin/bash

# 🧹 HSQ Forms - Quick Clean & Restart
# Detta script rensar alla containers och startar om full miljö

set -e

echo "🧹 HSQ Forms - Quick Clean & Restart"
echo ""

# Stoppa och ta bort alla containers
echo "🛑 Stopping all containers..."
docker-compose -f docker-compose.full.yml down --remove-orphans 2>/dev/null || true
docker-compose -f docker-compose.dev.yml down --remove-orphans 2>/dev/null || true
docker-compose -f docker-compose.yml down --remove-orphans 2>/dev/null || true

# Ta bort dangling images
echo "🧹 Cleaning up dangling images..."
docker image prune -f

# Kontrollera Docker-status
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Skapa nätverk
echo "📶 Creating network..."
docker network create hsq-forms 2>/dev/null || true

echo ""
echo "🚀 Starting full environment..."
echo ""
echo "Services that will be started:"
echo "  📊 API Server        → http://localhost:8000"
echo "  📊 Dashboard         → http://localhost:3005"
echo "  📝 B2B Feedback      → http://localhost:3001"
echo "  📦 B2B Returns       → http://localhost:3002"
echo "  🛠️  B2B Support       → http://localhost:3003"
echo "  🔄 B2C Returns       → http://localhost:3004"
echo "  🗄️  PostgreSQL        → localhost:5432"
echo ""

# Starta alla containers
docker-compose -f docker-compose.full.yml up --build -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 15

# Visa status
echo ""
echo "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "✅ Full environment is running!"
echo ""
echo "🌐 Quick Links:"
echo "  API Documentation: http://localhost:8000/docs"
echo "  API Health Check:  http://localhost:8000/health"
echo "  Dashboard:         http://localhost:3005"
echo ""
echo "💡 To stop everything: docker-compose -f docker-compose.full.yml down"
