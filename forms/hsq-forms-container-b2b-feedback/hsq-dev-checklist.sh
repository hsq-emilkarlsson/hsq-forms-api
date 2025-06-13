#!/bin/zsh

# HSQ Forms B2B Feedback - Development Checklista
# Spara denna fil som ~/Desktop/hsq-dev-checklist.sh och kör: chmod +x ~/Desktop/hsq-dev-checklist.sh

echo "🚀 HSQ Forms B2B Feedback - Development Checklist"
echo "=================================================="

PROJECT_DIR="/Users/emilkarlsson/Documents/Dev/hsq-forms-api/forms/hsq-forms-container-b2b-feedback"

echo ""
echo "📁 Current Directory: $(pwd)"
echo "📂 Project Directory: $PROJECT_DIR"

if [ "$PWD" != "$PROJECT_DIR" ]; then
    echo ""
    echo "⚠️  You're not in the project directory!"
    echo "🔧 Run: cd $PROJECT_DIR"
    echo ""
fi

echo ""
echo "🔧 Available Commands:"
echo "  ./dev-helper.sh quick    # Snabb rebuild"
echo "  ./dev-helper.sh dev      # Development mode"
echo "  ./dev-helper.sh status   # Kontrollera status"
echo "  ./dev-helper.sh stop     # Stoppa allt"
echo ""

echo "🌐 URLs:"
echo "  App: http://localhost:3001"
echo "  API: http://localhost:8000"
echo ""

echo "📝 Typical Workflow:"
echo "  1. cd $PROJECT_DIR"
echo "  2. Gör ändringar i kod"
echo "  3. ./dev-helper.sh quick"
echo "  4. Testa på http://localhost:3001"
echo "  5. Upprepa tills nöjd"
echo ""

echo "🚨 Problem? Prova:"
echo "  ./dev-helper.sh clean    # Clean rebuild"
echo "  docker-compose logs      # Se vad som händer"
echo ""

# Om användaren vill navigera direkt
read -p "🚀 Vill du navigera till projektmappen? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$PROJECT_DIR"
    echo "✅ Nu är du i: $(pwd)"
    echo ""
    echo "Kör: ./dev-helper.sh status för att se vad som händer"
fi
