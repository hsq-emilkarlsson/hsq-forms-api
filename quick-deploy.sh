#!/bin/bash

# 🚀 HSQ Forms - Quick Full Restart
# Exakt som din Docker Desktop visade - startar alla containers

set -e

echo "🚀 HSQ Forms - Full Environment Quick Restart"
echo ""

# Stoppa och rensa HSQ Forms projektet
echo "🛑 Stopping HSQ Forms project..."
docker-compose -f docker-compose.full.yml down 2>/dev/null || true

# Rensa gamla images (endast dangling)
echo "🧹 Cleaning up..."
docker image prune -f > /dev/null 2>&1

echo ""
echo "🏗️ Building and starting all containers..."
echo ""
echo "Will start:"
echo "  📊 API Server (hsq-forms-api)     → http://localhost:8000"
echo "  🗄️  PostgreSQL (postgres-1)       → localhost:5432"
echo "   B2B Feedback (b2b-feedback-1)  → http://localhost:3001"
echo "  📦 B2B Returns (b2b-returns-1)    → http://localhost:3002"
echo "  🛠️  B2B Support (b2b-support-1)    → http://localhost:3003"
echo "  🔄 B2C Returns (b2c-returns-1)    → http://localhost:3004"
echo ""

# Starta fullständig miljö
docker-compose -f docker-compose.full.yml up --build -d

echo ""
echo "⏳ Waiting for containers to initialize..."
sleep 20

echo ""
echo "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Containers starting..."

echo ""
echo "✅ Full environment restarted!"
echo ""
echo "🌐 Quick Links:"
echo "  API:           http://localhost:8000"
echo "  API Docs:      http://localhost:8000/docs"
echo "  B2B Feedback:  http://localhost:3001"
echo "  B2B Returns:   http://localhost:3002"
echo "  B2B Support:   http://localhost:3003"
echo "  B2C Returns:   http://localhost:3004"
echo ""
echo "💡 To stop everything: docker-compose -f docker-compose.full.yml down"
