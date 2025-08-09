#!/bin/bash
# ========================================================================
# API Diagnostikverktyg för HSQ Forms
# Detta skript hjälper till att diagnosticera anslutningsproblem mellan formulär och API
# Uppdaterad: 2025-08-09
# ========================================================================

# Färger för bättre läsbarhet
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# API URL (ändra vid behov)
API_URL="https://hsq-forms-dev-e8g5hhgpfwgabsg5.a03.azurefd.net"
API_KEY="dev-api-key-1"  # Bör matcha värdet i .env.production för formulären

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HSQ Forms API Diagnostikverktyg  ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Kontrollera nödvändiga verktyg
command -v curl >/dev/null 2>&1 || { echo -e "${RED}Curl krävs men är inte installerat. Installera med 'apt-get install curl'.${NC}"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${YELLOW}jq rekommenderas för bättre JSON-formatering. Installera med 'apt-get install jq'.${NC}"; }

# Funktion för att kontrollera API-tillgänglighet
check_api_availability() {
    echo -e "${CYAN}Kontrollerar API-tillgänglighet...${NC}"
    
    # Testa grundläggande anslutning till API:et
    echo -e "GET $API_URL/docs"
    RESPONSE=$(curl -s -o response.txt -w "%{http_code}" $API_URL/docs)
    
    if [ "$RESPONSE" == "200" ] || [ "$RESPONSE" == "401" ] || [ "$RESPONSE" == "403" ]; then
        echo -e "${GREEN}✓ API svarar med statuskod $RESPONSE.${NC}"
        
        # Kontrollera om Swagger-dokumentationen är tillgänglig
        if [ "$RESPONSE" == "200" ]; then
            echo -e "${GREEN}✓ Swagger-dokumentation är tillgänglig.${NC}"
        else
            echo -e "${YELLOW}⚠ Swagger-dokumentation kräver autentisering.${NC}"
        fi
    else
        echo -e "${RED}✗ API svarar inte korrekt. Statuskod: $RESPONSE${NC}"
        
        # Försök ping för att se om det är nätverksrelaterat
        echo -e "${YELLOW}Testar nätverksanslutning till API-domänen...${NC}"
        API_DOMAIN=$(echo $API_URL | sed -e 's|^[^/]*//||' -e 's|/.*$||')
        ping -c 3 $API_DOMAIN
    fi
    
    echo ""
}

# Funktion för att testa CORS-konfiguration
test_cors() {
    echo -e "${CYAN}Testar CORS-konfiguration...${NC}"
    
    # Anropa API med OPTIONS-metoden för att simulera CORS preflight
    echo -e "OPTIONS $API_URL/api/v1/forms"
    CORS_RESPONSE=$(curl -s -o cors_response.txt -w "%{http_code}" -X OPTIONS \
        -H "Origin: https://purple-moss-0b1b7b303.3.azurestaticapps.net" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type, X-API-Key" \
        $API_URL/api/v1/forms)
    
    if [ "$CORS_RESPONSE" == "200" ] || [ "$CORS_RESPONSE" == "204" ]; then
        echo -e "${GREEN}✓ CORS preflight svarar med statuskod $CORS_RESPONSE.${NC}"
        
        # Kontrollera CORS-headers
        ALLOW_ORIGIN=$(grep -i "Access-Control-Allow-Origin" cors_response.txt | head -1)
        ALLOW_METHODS=$(grep -i "Access-Control-Allow-Methods" cors_response.txt | head -1)
        ALLOW_HEADERS=$(grep -i "Access-Control-Allow-Headers" cors_response.txt | head -1)
        
        if [ -n "$ALLOW_ORIGIN" ]; then
            echo -e "${GREEN}✓ $ALLOW_ORIGIN${NC}"
        else
            echo -e "${RED}✗ Access-Control-Allow-Origin header saknas.${NC}"
        fi
        
        if [ -n "$ALLOW_METHODS" ]; then
            echo -e "${GREEN}✓ $ALLOW_METHODS${NC}"
        else
            echo -e "${RED}✗ Access-Control-Allow-Methods header saknas.${NC}"
        fi
        
        if [ -n "$ALLOW_HEADERS" ]; then
            echo -e "${GREEN}✓ $ALLOW_HEADERS${NC}"
        else
            echo -e "${RED}✗ Access-Control-Allow-Headers header saknas.${NC}"
        fi
    else
        echo -e "${RED}✗ CORS preflight svarar inte korrekt. Statuskod: $CORS_RESPONSE${NC}"
        echo "Svar innehåll:"
        cat cors_response.txt
    fi
    
    echo ""
}

# Funktion för att testa API-autentisering
test_authentication() {
    echo -e "${CYAN}Testar API-autentisering...${NC}"
    
    # Anropa API utan API-nyckel
    echo -e "GET $API_URL/api/v1/forms (utan API-nyckel)"
    NO_AUTH_RESPONSE=$(curl -s -o no_auth_response.txt -w "%{http_code}" \
        $API_URL/api/v1/forms)
    
    if [ "$NO_AUTH_RESPONSE" == "401" ] || [ "$NO_AUTH_RESPONSE" == "403" ]; then
        echo -e "${GREEN}✓ API kräver autentisering. Statuskod: $NO_AUTH_RESPONSE${NC}"
    else
        echo -e "${YELLOW}⚠ API svarar med statuskod $NO_AUTH_RESPONSE utan autentisering.${NC}"
    fi
    
    # Anropa API med API-nyckel
    echo -e "GET $API_URL/api/v1/forms (med API-nyckel)"
    AUTH_RESPONSE=$(curl -s -o auth_response.txt -w "%{http_code}" \
        -H "X-API-Key: $API_KEY" \
        $API_URL/api/v1/forms)
    
    if [ "$AUTH_RESPONSE" == "200" ]; then
        echo -e "${GREEN}✓ API-autentisering fungerar. Statuskod: $AUTH_RESPONSE${NC}"
        echo -e "${BLUE}Lista över tillgängliga formulär:${NC}"
        if command -v jq >/dev/null 2>&1; then
            cat auth_response.txt | jq .
        else
            cat auth_response.txt
        fi
    else
        echo -e "${RED}✗ API-autentisering misslyckades. Statuskod: $AUTH_RESPONSE${NC}"
        echo "Svar innehåll:"
        cat auth_response.txt
    fi
    
    echo ""
}

# Funktion för att testa formulärsinlämning
test_form_submission() {
    echo -e "${CYAN}Testar formulärsinlämning...${NC}"
    
    # Skapa testdata för formulärinlämning
    FORM_ID="b2c-returns"
    cat > test_payload.json << EOF
{
  "formId": "$FORM_ID",
  "data": {
    "customerName": "Test Person",
    "email": "test@example.com",
    "orderNumber": "TEST-12345",
    "reason": "Diagnostiktest",
    "comments": "Detta är en testinlämning från diagnostikskriptet"
  },
  "language": "sv",
  "metadata": {
    "userAgent": "Diagnostikskript/1.0",
    "source": "api-test-script"
  }
}
EOF
    
    echo -e "POST $API_URL/api/v1/submissions"
    SUBMISSION_RESPONSE=$(curl -s -o submission_response.txt -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $API_KEY" \
        -H "Origin: https://purple-moss-0b1b7b303.3.azurestaticapps.net" \
        -d @test_payload.json \
        $API_URL/api/v1/submissions)
    
    if [ "$SUBMISSION_RESPONSE" == "200" ] || [ "$SUBMISSION_RESPONSE" == "201" ]; then
        echo -e "${GREEN}✓ Formulärsinlämning lyckades. Statuskod: $SUBMISSION_RESPONSE${NC}"
        echo -e "${BLUE}Svar från API:${NC}"
        if command -v jq >/dev/null 2>&1; then
            cat submission_response.txt | jq .
        else
            cat submission_response.txt
        fi
    else
        echo -e "${RED}✗ Formulärsinlämning misslyckades. Statuskod: $SUBMISSION_RESPONSE${NC}"
        echo "Svar innehåll:"
        cat submission_response.txt
    fi
    
    echo ""
}

# Funktion för att samla in information om API-konfiguration
collect_api_config() {
    echo -e "${CYAN}Samlar in information om API-konfiguration...${NC}"
    
    # Kontrollera health-endpoint om sådan finns
    echo -e "GET $API_URL/api/health"
    HEALTH_RESPONSE=$(curl -s -o health_response.txt -w "%{http_code}" \
        $API_URL/api/health)
    
    if [ "$HEALTH_RESPONSE" == "200" ]; then
        echo -e "${GREEN}✓ Health-endpoint tillgänglig. Statuskod: $HEALTH_RESPONSE${NC}"
        echo -e "${BLUE}Hälsoinformation:${NC}"
        if command -v jq >/dev/null 2>&1; then
            cat health_response.txt | jq .
        else
            cat health_response.txt
        fi
    else
        echo -e "${YELLOW}⚠ Health-endpoint inte tillgänglig eller kräver autentisering. Statuskod: $HEALTH_RESPONSE${NC}"
    fi
    
    echo ""
}

# Huvudprogramloop
while true; do
    echo -e "${BLUE}Välj ett diagnostiktest att köra:${NC}"
    echo "1) Kontrollera API-tillgänglighet"
    echo "2) Testa CORS-konfiguration"
    echo "3) Testa API-autentisering"
    echo "4) Testa formulärsinlämning"
    echo "5) Samla in API-konfiguration"
    echo "6) Kör alla tester"
    echo "7) Ändra API URL (nuvarande: $API_URL)"
    echo "8) Ändra API-nyckel (nuvarande: $API_KEY)"
    echo "q) Avsluta"
    
    read -p "Välj alternativ: " option
    echo ""
    
    case $option in
        1)
            check_api_availability
            ;;
        2)
            test_cors
            ;;
        3)
            test_authentication
            ;;
        4)
            test_form_submission
            ;;
        5)
            collect_api_config
            ;;
        6)
            check_api_availability
            test_cors
            test_authentication
            test_form_submission
            collect_api_config
            ;;
        7)
            read -p "Ange ny API URL: " new_api_url
            if [ -n "$new_api_url" ]; then
                API_URL=$new_api_url
                echo -e "${GREEN}API URL uppdaterad till: $API_URL${NC}"
            fi
            ;;
        8)
            read -p "Ange ny API-nyckel: " new_api_key
            if [ -n "$new_api_key" ]; then
                API_KEY=$new_api_key
                echo -e "${GREEN}API-nyckel uppdaterad till: $API_KEY${NC}"
            fi
            ;;
        q|Q)
            echo -e "${BLUE}Avslutar diagnostikverktyget. Hej då!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Ogiltigt val, försök igen.${NC}"
            ;;
    esac
    
    echo -e "${BLUE}----------------------------------------${NC}"
    echo ""
done
