#!/bin/bash

# HSQ Forms - B2B Support Container Management Script
# Enkla kommandon för att hantera B2B Support Form-containern

CONTAINER_NAME="hsq-forms-b2b-support"
IMAGE_NAME="hsq-forms-container-b2b-support:latest"
PORT="3003"

case "$1" in
    start)
        echo "🚀 Startar $CONTAINER_NAME container..."
        docker-compose up -d
        echo "✅ Container startad! Tillgänglig på http://localhost:$PORT"
        ;;
    stop)
        echo "🛑 Stoppar $CONTAINER_NAME container..."
        docker-compose down
        echo "✅ Container stoppad!"
        ;;
    restart)
        echo "🔄 Startar om $CONTAINER_NAME container..."
        docker-compose restart
        echo "✅ Container omstartad! Tillgänglig på http://localhost:$PORT"
        ;;
    status)
        echo "📊 Container status:"
        docker ps | grep $CONTAINER_NAME
        echo ""
        echo "🏥 Health status:"
        docker inspect $CONTAINER_NAME --format='{{.State.Health.Status}}' 2>/dev/null || echo "Health check ej tillgänglig"
        ;;
    logs)
        echo "📋 Senaste logs från $CONTAINER_NAME:"
        docker logs --tail 50 $CONTAINER_NAME
        ;;
    logs-live)
        echo "📋 Live logs från $CONTAINER_NAME (Ctrl+C för att avsluta):"
        docker logs -f $CONTAINER_NAME
        ;;
    rebuild)
        echo "🔨 Bygger om $IMAGE_NAME..."
        docker build -t $IMAGE_NAME .
        echo "🔄 Startar om container med ny image..."
        docker-compose down
        docker-compose up -d
        echo "✅ Container ombyggd och omstartad!"
        ;;
    open)
        echo "🌐 Öppnar formuläret i webbläsaren..."
        open http://localhost:$PORT
        ;;
    test)
        echo "🧪 Kör API integration tests..."
        node test-api-integration.js
        ;;
    clean)
        echo "🧹 Rensar upp oanvända Docker resurser..."
        docker system prune -f
        echo "✅ Cleanup genomförd!"
        ;;
    *)
        echo "HSQ Forms - B2B Support Container Management"
        echo "============================================"
        echo ""
        echo "Användning: $0 {start|stop|restart|status|logs|logs-live|rebuild|open|test|clean}"
        echo ""
        echo "Kommandon:"
        echo "  start      - Starta containern"
        echo "  stop       - Stoppa containern"
        echo "  restart    - Starta om containern"
        echo "  status     - Visa container status"
        echo "  logs       - Visa senaste logs"
        echo "  logs-live  - Följ logs i realtid"
        echo "  rebuild    - Bygg om och starta om containern"
        echo "  open       - Öppna formuläret i webbläsaren"
        echo "  test       - Kör API integration tests"
        echo "  clean      - Rensa upp oanvända Docker resurser"
        echo ""
        echo "Container: $CONTAINER_NAME"
        echo "Port: $PORT"
        echo "URL: http://localhost:$PORT"
        exit 1
        ;;
esac
