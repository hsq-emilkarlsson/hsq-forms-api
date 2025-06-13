#!/bin/bash
# Dev startup script för HSQ Forms API
# Usage: ./scripts/start-dev.sh

echo "🚀 Startar HSQ Forms API utvecklingsmiljö..."

# Kontrollera om Docker är igång
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker verkar inte vara igång. Starta Docker först."
  exit 1
fi

# Rensa tidigare cache-filer
echo "🧹 Rensar cache-filer..."
./tests/scripts/cleanup_cache.sh > /dev/null

# Starta utvecklingsmiljön med Docker Compose
echo "🐳 Startar containers med docker-compose..."
docker-compose up --build

# Scriptet når inte hit om docker-compose körs normalt (utan -d)
# men tillgängligt om någon ändrar kommandot ovan till att köra i bakgrund
echo "✅ HSQ Forms API är igång!"
echo "API finns på: http://localhost:8000"
echo "API-dokumentation: http://localhost:8000/docs"