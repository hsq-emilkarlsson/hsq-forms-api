#!/bin/bash

# 🚀 HSQ Forms - Start Full Container Environment
# Detta script startar alla formulär-containers för lokal utveckling

set -e

echo "🚀 Starting HSQ Forms Full Container Environment..."
echo ""

# Kontrollera att Docker körs
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

# Skapa nätverk om det inte finns
if ! docker network ls | grep -q hsq-forms; then
    echo "📶 Creating hsq-forms network..."
    docker network create hsq-forms
fi

# Starta alla services
echo "🏗️ Building and starting all containers..."
echo ""
echo "Services that will be started:"
echo "  📊 API Server      → http://localhost:8000"
echo "  📝 B2B Feedback    → http://localhost:3001"
echo "  📦 B2B Returns     → http://localhost:3002"
echo "  🛠️  B2B Support     → http://localhost:3003"
echo "  🔄 B2C Returns     → http://localhost:3004"
echo "  🗄️  PostgreSQL      → localhost:5432"
echo ""

# Fråga användaren
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Starta containers
docker-compose -f docker-compose.full.yml up --build -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Kontrollera status
echo ""
echo "📊 Container Status:"
docker-compose -f docker-compose.full.yml ps

echo ""
echo "🔍 Health Checks:"

# Kontrollera API
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ API Server (http://localhost:8000) - OK"
else
    echo "❌ API Server (http://localhost:8000) - Not responding"
fi

# Kontrollera formulär
for port in 3001 3002 3003 3004; do
    if curl -s http://localhost:$port > /dev/null; then
        echo "✅ Form Container (http://localhost:$port) - OK"
    else
        echo "❌ Form Container (http://localhost:$port) - Not responding"
    fi
done

echo ""
echo "🎉 All services started successfully!"
echo ""
echo "🌐 Quick Links:"
echo "  API Documentation: http://localhost:8000/docs"
echo "  B2B Feedback:      http://localhost:3001"
echo "  B2B Returns:       http://localhost:3002"
echo "  B2B Support:       http://localhost:3003"
echo "  B2C Returns:       http://localhost:3004"
echo ""
echo "📝 Useful Commands:"
echo "  View logs:         docker-compose -f docker-compose.full.yml logs -f"
echo "  Stop all:          docker-compose -f docker-compose.full.yml down"
echo "  Restart service:   docker-compose -f docker-compose.full.yml restart [service]"
echo ""
echo "Happy coding! 🚀"
