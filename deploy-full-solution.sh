#!/bin/bash

# 🚀 Full Container Deployment Script
# Deploys complete B2B support form solution

echo "🚀 Deploying B2B Support Form Container Solution"
echo "================================================"

# Set working directory
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -ti:$port > /dev/null 2>&1; then
        echo "⚠️  Port $port is in use. Stopping processes..."
        lsof -ti:$port | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# Check and free up ports
echo "🔍 Checking ports..."
check_port 3003
check_port 8000
check_port 5432

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose down 2>/dev/null || true
cd forms/hsq-forms-container-b2b-support
docker-compose down 2>/dev/null || true
cd ../..

# Create network if it doesn't exist
echo "🌐 Setting up Docker network..."
docker network create hsq-forms-network 2>/dev/null || echo "Network already exists"

# Start backend services
echo "🔧 Starting backend services..."
docker-compose up -d --build

# Wait for backend to be ready
echo "⏳ Waiting for backend to start..."
for i in {1..30}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ Backend is ready!"
        break
    fi
    echo "   Waiting... ($i/30)"
    sleep 2
done

# Start frontend container
echo "🎨 Starting frontend container..."
cd forms/hsq-forms-container-b2b-support
docker-compose up -d --build

# Wait for frontend to be ready
echo "⏳ Waiting for frontend to start..."
cd ../..
for i in {1..30}; do
    if curl -s http://localhost:3003 > /dev/null 2>&1; then
        echo "✅ Frontend is ready!"
        break
    fi
    echo "   Waiting... ($i/30)"
    sleep 2
done

# Verify deployment
echo ""
echo "🧪 Running verification tests..."
sleep 5  # Give containers time to fully initialize

# Run comprehensive test
if ./test-full-container-solution.sh | grep -q "✅ Full containerized solution is working"; then
    echo ""
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo "========================"
    echo "✅ Frontend: http://localhost:3003"
    echo "✅ Backend: http://localhost:8000"
    echo "✅ API Docs: http://localhost:8000/docs"
    echo "✅ caseOriginCode: 115000008 (ready for CRM routing)"
    echo ""
    echo "📊 Container Status:"
    docker ps --filter "name=hsq-forms" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo ""
    echo "❌ DEPLOYMENT VERIFICATION FAILED"
    echo "Please check container logs:"
    echo "  docker logs hsq-forms-b2b-support"
    echo "  docker logs hsq-forms-api-api-1"
    exit 1
fi

echo ""
echo "🚀 Ready for production use!"
