#!/bin/zsh

# Quick Start Script för HSQ Forms B2B Support
# Plattformsspecifik för macOS med zsh

echo "🚀 HSQ Forms B2B Support - Quick Start"
echo "======================================"
echo ""

# Kontrollera om Docker Desktop körs
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker Desktop körs inte!"
    echo "💡 Starta Docker Desktop och försök igen."
    exit 1
fi

# Navigera till rätt katalog
cd "$(dirname "$0")"

# Kontrollera om containern redan körs
if docker ps | grep -q "hsq-forms-b2b-support"; then
    echo "✅ B2B Support Form körs redan!"
    echo "🌐 Tillgänglig på: http://localhost:3003"
    
    # Fråga om användaren vill öppna i webbläsaren
    echo ""
    read "response?Vill du öppna formuläret i webbläsaren? (y/n): "
    if [[ "$response" =~ ^[Yy]$ ]]; then
        open http://localhost:3003
        echo "🌐 Öppnade formuläret i webbläsaren!"
    fi
else
    echo "⏳ Startar B2B Support Form container..."
    
    # Starta containern
    if docker-compose up -d; then
        echo ""
        echo "✅ Container startad framgångsrikt!"
        echo "⏳ Väntar på att applikationen ska bli redo..."
        
        # Vänta på att health check blir grön
        sleep 5
        
        # Kontrollera health status
        for i in {1..12}; do
            if curl -s http://localhost:3003 >/dev/null 2>&1; then
                echo "✅ Applikationen är redo!"
                echo "🌐 Tillgänglig på: http://localhost:3003"
                echo ""
                
                # Öppna automatiskt i webbläsaren
                read "response?Vill du öppna formuläret i webbläsaren? (y/n): "
                if [[ "$response" =~ ^[Yy]$ ]]; then
                    open http://localhost:3003
                    echo "🌐 Öppnade formuläret i webbläsaren!"
                fi
                
                echo ""
                echo "📋 Användbara kommandon:"
                echo "  ./container.sh status    - Visa container status"
                echo "  ./container.sh logs      - Visa logs"
                echo "  ./container.sh test      - Testa API integration"
                echo "  ./container.sh stop      - Stoppa container"
                echo ""
                exit 0
            fi
            
            echo "⏳ Väntar på applikation... ($i/12)"
            sleep 5
        done
        
        echo "⚠️  Applikationen svarar inte på förväntad tid"
        echo "🔍 Kontrollera logs: ./container.sh logs"
    else
        echo "❌ Misslyckades att starta container!"
        echo "🔍 Kontrollera Docker Desktop och försök igen."
        exit 1
    fi
fi
