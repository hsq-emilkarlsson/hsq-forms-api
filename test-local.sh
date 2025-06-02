#!/bin/bash

# Test HSQ Forms Platform lokalt innan deployment
echo "🧪 Testar HSQ Forms Platform lokalt..."

# Kontrollera att alla containers körs
echo "📋 Kontrollerar Docker containers..."
cd docker

# Starta alla services
echo "🚀 Startar alla services..."
docker-compose up -d

echo "⏳ Väntar på att services ska starta..."
sleep 30

# Testa API health
echo "🔍 Testar API health..."
if curl -f http://localhost:8000/ > /dev/null 2>&1; then
    echo "✅ API fungerar"
else
    echo "❌ API svarar inte"
    exit 1
fi

# Testa contact form
echo "🔍 Testar contact form..."
if curl -f http://localhost:5173/ > /dev/null 2>&1; then
    echo "✅ Contact form fungerar"
else
    echo "❌ Contact form svarar inte"
fi

# Testa support form  
echo "🔍 Testar support form..."
if curl -f http://localhost:3002/ > /dev/null 2>&1; then
    echo "✅ Support form fungerar"
else
    echo "❌ Support form svarar inte"
fi

# Testa databas-anslutning
echo "🔍 Testar databas..."
if docker-compose exec -T postgres pg_isready -U formuser -d formdb > /dev/null 2>&1; then
    echo "✅ PostgreSQL fungerar"
else
    echo "❌ PostgreSQL svarar inte"
fi

# Testa formulär-submission
echo "🔍 Testar formulär-submission..."
response=$(curl -s -X POST http://localhost:8000/submit \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com", 
    "message": "Test message",
    "form_type": "contact"
  }')

if echo "$response" | grep -q "success"; then
    echo "✅ Formulär-submission fungerar"
else
    echo "❌ Formulär-submission misslyckades"
    echo "Response: $response"
fi

echo ""
echo "🎉 Lokal testning slutförd!"
echo ""
echo "🌐 Lokala URL:er:"
echo "API: http://localhost:8000"
echo "API Docs: http://localhost:8000/docs"
echo "Contact Form: http://localhost:5173"
echo "Support Form: http://localhost:3002"
echo ""
echo "🚀 Redo för deployment till Azure? Kör: ./deploy-azure.sh"
