#!/bin/bash

echo "🔍 HSQ Forms - Container Status Check"
echo "======================================="

# Check if docker-compose.full.yml containers are running
echo ""
echo "📊 Container Status:"
docker-compose -f docker-compose.full.yml ps

echo ""
echo "🌐 Port Status:"
echo "Checking if services are responding..."

# Check API
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ API Server (port 8000) - HEALTHY"
else
    echo "❌ API Server (port 8000) - NOT RESPONDING"
fi

# Check form containers
for port in 3001 3002 3003 3004; do
    if curl -s http://localhost:$port > /dev/null 2>&1; then
        echo "✅ Form Container (port $port) - RUNNING"
    else
        echo "❌ Form Container (port $port) - NOT RESPONDING"
    fi
done

echo ""
echo "🔄 Running Containers:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep -E "(hsq|postgres|NAME)"

echo ""
echo "💡 Quick Commands:"
echo "   Start full environment: ./quick-deploy.sh"
echo "   Stop all containers:    docker-compose -f docker-compose.full.yml down"
echo "   View logs:              docker-compose -f docker-compose.full.yml logs -f [service-name]"
echo "   Restart single service: docker-compose -f docker-compose.full.yml restart [service-name]"
