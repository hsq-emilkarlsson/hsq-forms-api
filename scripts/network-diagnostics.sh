#!/bin/bash
# ========================================================================
# HSQ Forms - Nätverk & Front Door Diagnostik
# Detta skript analyserar nätverkskonfiguration och Front Door-relaterade problem
# Uppdaterad: 2025-08-09
# ========================================================================

# Färger för bättre läsbarhet
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Standard API och Web App URLs
API_DIRECT_URL="https://hsq-forms-api-dev.azurewebsites.net"
API_FRONT_DOOR_URL="https://hsq-forms-dev-e8g5hhgpfwgabsg5.a03.azurefd.net"
STATIC_WEB_APP_B2C_URL="https://purple-moss-0b1b7b303.3.azurestaticapps.net"
RESOURCE_GROUP="rg-hsq-forms-dev"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HSQ Forms Nätverk & Front Door Diagnostik  ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Kontrollera nödvändiga verktyg
command -v curl >/dev/null 2>&1 || { echo -e "${RED}Curl krävs men är inte installerat. Installera med 'apt-get install curl'.${NC}"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${YELLOW}jq rekommenderas för bättre JSON-formatering. Installera med 'apt-get install jq'.${NC}"; }
command -v az >/dev/null 2>&1 || { echo -e "${RED}Azure CLI krävs men är inte installerat. Installera med 'curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash'.${NC}"; exit 1; }

# Kontrollera om användaren är inloggad i Azure CLI
az account show > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Du är inte inloggad i Azure CLI. Loggar in...${NC}"
    az login
    if [ $? -ne 0 ]; then
        echo -e "${RED}Kunde inte logga in i Azure CLI. Avbryter.${NC}"
        exit 1
    fi
fi

# Funktion för att utföra nätverksdiagnostik
network_diagnosis() {
    echo -e "${CYAN}Utför nätverksdiagnostik...${NC}"
    
    # Kontrollera DNS-upplösning
    echo -e "${BLUE}Kontrollerar DNS-upplösning...${NC}"
    
    # Extrahera domännamnen från URLerna
    API_DIRECT_DOMAIN=$(echo $API_DIRECT_URL | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    API_FRONT_DOOR_DOMAIN=$(echo $API_FRONT_DOOR_URL | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    STATIC_WEB_APP_DOMAIN=$(echo $STATIC_WEB_APP_B2C_URL | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    
    echo -e "API Direct Domain: $API_DIRECT_DOMAIN"
    echo -e "API Front Door Domain: $API_FRONT_DOOR_DOMAIN"
    echo -e "Static Web App Domain: $STATIC_WEB_APP_DOMAIN"
    echo ""
    
    # Utför nslookup på domänerna
    echo -e "${BLUE}DNS-upplösning för API Direct:${NC}"
    nslookup $API_DIRECT_DOMAIN
    echo ""
    
    echo -e "${BLUE}DNS-upplösning för API Front Door:${NC}"
    nslookup $API_FRONT_DOOR_DOMAIN
    echo ""
    
    echo -e "${BLUE}DNS-upplösning för Static Web App:${NC}"
    nslookup $STATIC_WEB_APP_DOMAIN
    echo ""
    
    # Kontrollera om IP-adresserna är i samma VNet/subnet
    echo -e "${BLUE}Kontrollerar om domänerna är åtkomliga...${NC}"
    
    echo -e "Ping API Direct:"
    ping -c 3 $API_DIRECT_DOMAIN
    API_DIRECT_PING_RESULT=$?
    
    echo -e "\nPing API Front Door:"
    ping -c 3 $API_FRONT_DOOR_DOMAIN
    API_FRONT_DOOR_PING_RESULT=$?
    
    echo -e "\nPing Static Web App:"
    ping -c 3 $STATIC_WEB_APP_DOMAIN
    STATIC_WEB_APP_PING_RESULT=$?
    
    # Sammanfatta ping-resultaten
    echo -e "\n${BLUE}Ping-resultat:${NC}"
    
    if [ $API_DIRECT_PING_RESULT -eq 0 ]; then
        echo -e "${GREEN}✓ API Direct svarar på ping${NC}"
    else
        echo -e "${YELLOW}⚠ API Direct svarar inte på ping (normalt för Azure App Service)${NC}"
    fi
    
    if [ $API_FRONT_DOOR_PING_RESULT -eq 0 ]; then
        echo -e "${GREEN}✓ API Front Door svarar på ping${NC}"
    else
        echo -e "${YELLOW}⚠ API Front Door svarar inte på ping (förväntat för Azure Front Door)${NC}"
    fi
    
    if [ $STATIC_WEB_APP_PING_RESULT -eq 0 ]; then
        echo -e "${GREEN}✓ Static Web App svarar på ping${NC}"
    else
        echo -e "${YELLOW}⚠ Static Web App svarar inte på ping (förväntat för Azure Static Web Apps)${NC}"
    fi
    
    echo -e "\n${BLUE}HTTP-test av endpointerna:${NC}"
    
    # Testa HTTP-anslutning till endpointerna
    echo -e "GET $API_DIRECT_URL/api/health"
    DIRECT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $API_DIRECT_URL/api/health)
    
    if [[ "$DIRECT_RESPONSE" == "200" || "$DIRECT_RESPONSE" == "401" || "$DIRECT_RESPONSE" == "403" ]]; then
        echo -e "${GREEN}✓ API Direct svarar med statuskod $DIRECT_RESPONSE${NC}"
    else
        echo -e "${RED}✗ API Direct svarar med statuskod $DIRECT_RESPONSE${NC}"
    fi
    
    echo -e "\nGET $API_FRONT_DOOR_URL/api/health"
    FRONT_DOOR_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $API_FRONT_DOOR_URL/api/health)
    
    if [[ "$FRONT_DOOR_RESPONSE" == "200" || "$FRONT_DOOR_RESPONSE" == "401" || "$FRONT_DOOR_RESPONSE" == "403" ]]; then
        echo -e "${GREEN}✓ API Front Door svarar med statuskod $FRONT_DOOR_RESPONSE${NC}"
    else
        echo -e "${RED}✗ API Front Door svarar med statuskod $FRONT_DOOR_RESPONSE${NC}"
    fi
    
    echo -e "\nGET $STATIC_WEB_APP_B2C_URL"
    SWA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $STATIC_WEB_APP_B2C_URL)
    
    if [[ "$SWA_RESPONSE" == "200" ]]; then
        echo -e "${GREEN}✓ Static Web App svarar med statuskod $SWA_RESPONSE${NC}"
    else
        echo -e "${RED}✗ Static Web App svarar med statuskod $SWA_RESPONSE${NC}"
    fi
}

# Funktion för att analysera Azure Front Door-konfiguration
analyze_front_door() {
    echo -e "${CYAN}Analyserar Azure Front Door-konfiguration...${NC}"
    
    # Hämta lista över Front Door-resurser i resursgruppen
    echo -e "${BLUE}Söker efter Front Door-resurser i resursgruppen $RESOURCE_GROUP...${NC}"
    FRONT_DOORS=$(az network front-door list --resource-group $RESOURCE_GROUP --query "[].name" -o tsv 2>/dev/null)
    
    if [ -z "$FRONT_DOORS" ]; then
        echo -e "${RED}Inga Front Door-resurser hittades i resursgruppen $RESOURCE_GROUP.${NC}"
        return
    fi
    
    echo -e "${GREEN}Hittade följande Front Door-resurser: $FRONT_DOORS${NC}"
    
    for FD in $FRONT_DOORS; do
        echo -e "\n${BLUE}Analyserar Front Door: $FD${NC}"
        
        # Hämta frontend-endpoints
        echo -e "${BLUE}Frontend Endpoints:${NC}"
        az network front-door frontend-endpoint list --front-door-name $FD --resource-group $RESOURCE_GROUP --query "[].{Name:name, HostName:hostName}" -o table
        
        # Hämta backend pools
        echo -e "\n${BLUE}Backend Pools:${NC}"
        az network front-door backend-pool list --front-door-name $FD --resource-group $RESOURCE_GROUP --query "[].{Name:name, Backends:backends[].{Address:address}}" -o json | jq -r '.[] | "Namn: \(.Name)\nBackends: \(.Backends | map(.Address) | join(", "))"'
        
        # Hämta routing-regler
        echo -e "\n${BLUE}Routing Rules:${NC}"
        az network front-door routing-rule list --front-door-name $FD --resource-group $RESOURCE_GROUP --query "[].{Name:name, FrontendEndpoints:frontendEndpoints, BackendPool:backendPool.id, AcceptedProtocols:acceptedProtocols, PatternsToMatch:patternsToMatch}" -o json | jq -r '.[] | "Namn: \(.Name)\nFrontend Endpoints: \(.FrontendEndpoints | join(", "))\nBackend Pool: \(.BackendPool | split("/") | last)\nAccepted Protocols: \(.AcceptedProtocols | join(", "))\nPatterns to Match: \(.PatternsToMatch | join(", "))"'
    done
}

# Funktion för att analysera VNet-konfiguration
analyze_vnet() {
    echo -e "${CYAN}Analyserar VNet-konfiguration...${NC}"
    
    # Hämta lista över VNet-resurser i resursgruppen
    echo -e "${BLUE}Söker efter VNet-resurser i resursgruppen $RESOURCE_GROUP...${NC}"
    VNETS=$(az network vnet list --resource-group $RESOURCE_GROUP --query "[].name" -o tsv 2>/dev/null)
    
    if [ -z "$VNETS" ]; then
        echo -e "${RED}Inga VNet-resurser hittades i resursgruppen $RESOURCE_GROUP.${NC}"
        return
    fi
    
    echo -e "${GREEN}Hittade följande VNet-resurser: $VNETS${NC}"
    
    for VNET in $VNETS; do
        echo -e "\n${BLUE}Analyserar VNet: $VNET${NC}"
        
        # Hämta VNet-detaljer
        echo -e "${BLUE}VNet-detaljer:${NC}"
        az network vnet show --name $VNET --resource-group $RESOURCE_GROUP --query "{Name:name, AddressSpace:addressSpace.addressPrefixes, Subnets:subnets[].{Name:name, AddressPrefix:addressPrefix}}" -o json | jq
        
        # Hämta NSG-regler för varje subnet
        SUBNETS=$(az network vnet subnet list --vnet-name $VNET --resource-group $RESOURCE_GROUP --query "[].name" -o tsv)
        
        for SUBNET in $SUBNETS; do
            echo -e "\n${BLUE}NSG-regler för subnet $SUBNET:${NC}"
            NSG_ID=$(az network vnet subnet show --name $SUBNET --vnet-name $VNET --resource-group $RESOURCE_GROUP --query "networkSecurityGroup.id" -o tsv 2>/dev/null)
            
            if [ -z "$NSG_ID" ] || [ "$NSG_ID" == "null" ]; then
                echo -e "${YELLOW}Ingen NSG kopplad till denna subnet.${NC}"
                continue
            fi
            
            NSG_NAME=$(echo $NSG_ID | awk -F'/' '{print $NF}')
            
            az network nsg rule list --nsg-name $NSG_NAME --resource-group $RESOURCE_GROUP --query "[].{Name:name, Priority:priority, Direction:direction, Access:access, Protocol:protocol, SourceAddressPrefix:sourceAddressPrefix, DestinationAddressPrefix:destinationAddressPrefix, SourcePortRange:sourcePortRange, DestinationPortRange:destinationPortRange}" -o table
        done
    done
}

# Funktion för att analysera App Service-konfiguration
analyze_app_service() {
    echo -e "${CYAN}Analyserar App Service-konfiguration...${NC}"
    
    # Hämta lista över App Service-resurser i resursgruppen
    echo -e "${BLUE}Söker efter App Service-resurser i resursgruppen $RESOURCE_GROUP...${NC}"
    APP_SERVICES=$(az webapp list --resource-group $RESOURCE_GROUP --query "[].name" -o tsv 2>/dev/null)
    
    if [ -z "$APP_SERVICES" ]; then
        echo -e "${RED}Inga App Service-resurser hittades i resursgruppen $RESOURCE_GROUP.${NC}"
        return
    fi
    
    echo -e "${GREEN}Hittade följande App Service-resurser: $APP_SERVICES${NC}"
    
    for APP in $APP_SERVICES; do
        echo -e "\n${BLUE}Analyserar App Service: $APP${NC}"
        
        # Hämta App Service-detaljer
        echo -e "${BLUE}App Service-detaljer:${NC}"
        az webapp show --name $APP --resource-group $RESOURCE_GROUP --query "{Name:name, DefaultHostName:defaultHostName, HttpsOnly:httpsOnly, State:state}" -o table
        
        # Hämta VNet-integration
        echo -e "\n${BLUE}VNet-integration:${NC}"
        VNET_INFO=$(az webapp vnet-integration list --name $APP --resource-group $RESOURCE_GROUP -o json 2>/dev/null)
        
        if [ -z "$VNET_INFO" ] || [ "$VNET_INFO" == "[]" ]; then
            echo -e "${YELLOW}Ingen VNet-integration konfigurerad.${NC}"
        else
            echo "$VNET_INFO" | jq
        fi
        
        # Hämta Access Restrictions
        echo -e "\n${BLUE}Access Restrictions:${NC}"
        az webapp config access-restriction show --name $APP --resource-group $RESOURCE_GROUP -o json | jq -r '.ipSecurityRestrictions[] | "Action: \(.action)\nPriority: \(.priority)\nName: \(.name)\nIP Address: \(.ipAddress)"'
        
        # Hämta CORS-konfiguration
        echo -e "\n${BLUE}CORS-konfiguration:${NC}"
        CORS_INFO=$(az webapp cors show --name $APP --resource-group $RESOURCE_GROUP -o json)
        
        if [ -z "$CORS_INFO" ] || [ "$CORS_INFO" == "{}" ]; then
            echo -e "${YELLOW}Ingen CORS-konfiguration hittades.${NC}"
        else
            echo "$CORS_INFO" | jq
        fi
        
        # Kontrollera om App Service är i ett VNet
        echo -e "\n${BLUE}App Service i VNet?${NC}"
        VNET_STATUS=$(az webapp vnet-integration list --name $APP --resource-group $RESOURCE_GROUP --query "length([*])" -o tsv 2>/dev/null)
        
        if [ "$VNET_STATUS" -gt 0 ]; then
            echo -e "${GREEN}✓ App Service är integrerad med ett VNet.${NC}"
            
            # Kontrollera private endpoint
            echo -e "\n${BLUE}Private Endpoint-konfiguration:${NC}"
            PRIVATE_ENDPOINTS=$(az network private-endpoint-connection list --resource-group $RESOURCE_GROUP --name $APP --type Microsoft.Web/sites -o json 2>/dev/null)
            
            if [ -z "$PRIVATE_ENDPOINTS" ] || [ "$PRIVATE_ENDPOINTS" == "[]" ]; then
                echo -e "${YELLOW}Inga private endpoints konfigurerade.${NC}"
            else
                echo "$PRIVATE_ENDPOINTS" | jq
            fi
        else
            echo -e "${YELLOW}App Service är inte integrerad med ett VNet.${NC}"
        fi
    done
}

# Funktion för att analysera Static Web App-konfiguration
analyze_static_web_app() {
    echo -e "${CYAN}Analyserar Static Web App-konfiguration...${NC}"
    
    # Hämta lista över Static Web App-resurser i resursgruppen
    echo -e "${BLUE}Söker efter Static Web App-resurser i resursgruppen $RESOURCE_GROUP...${NC}"
    STATIC_WEB_APPS=$(az staticwebapp list --resource-group $RESOURCE_GROUP --query "[].name" -o tsv 2>/dev/null)
    
    if [ -z "$STATIC_WEB_APPS" ]; then
        echo -e "${RED}Inga Static Web App-resurser hittades i resursgruppen $RESOURCE_GROUP.${NC}"
        return
    fi
    
    echo -e "${GREEN}Hittade följande Static Web App-resurser: $STATIC_WEB_APPS${NC}"
    
    for SWA in $STATIC_WEB_APPS; do
        echo -e "\n${BLUE}Analyserar Static Web App: $SWA${NC}"
        
        # Hämta Static Web App-detaljer
        echo -e "${BLUE}Static Web App-detaljer:${NC}"
        az staticwebapp show --name $SWA --resource-group $RESOURCE_GROUP --query "{Name:name, DefaultHostname:defaultHostname, Status:status}" -o table
        
        # Hämta custom domains
        echo -e "\n${BLUE}Custom Domains:${NC}"
        DOMAINS=$(az staticwebapp hostname list --name $SWA --resource-group $RESOURCE_GROUP -o json 2>/dev/null)
        
        if [ -z "$DOMAINS" ] || [ "$DOMAINS" == "[]" ]; then
            echo -e "${YELLOW}Inga custom domains konfigurerade.${NC}"
        else
            echo "$DOMAINS" | jq
        fi
        
        # Hämta API-backend
        echo -e "\n${BLUE}API Backend-konfiguration:${NC}"
        API_CONFIG=$(az staticwebapp show --name $SWA --resource-group $RESOURCE_GROUP --query "linkedBackends" -o json 2>/dev/null)
        
        if [ -z "$API_CONFIG" ] || [ "$API_CONFIG" == "null" ] || [ "$API_CONFIG" == "[]" ]; then
            echo -e "${YELLOW}Ingen API backend konfigurerad.${NC}"
        else
            echo "$API_CONFIG" | jq
        fi
    done
}

# Funktion för att kontrollera VNet integration och DNS-konfiguration
test_vnet_dns() {
    echo -e "${CYAN}Analyserar DNS och VNet-kommunikation...${NC}"
    
    # Kontrollera front door tillgänglighet
    echo -e "${BLUE}Kontrollerar Front Door-tillgänglighet från Static Web App till API:${NC}"
    
    # Testa HTTP-anslutning från direkta URL:er
    echo -e "\n${BLUE}Test av direkta HTTP-anrop:${NC}"
    
    # Simulera anrop från Static Web App till Front Door
    echo -e "GET $API_FRONT_DOOR_URL/api/v1/forms med Origin: $STATIC_WEB_APP_B2C_URL"
    CORS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Origin: $STATIC_WEB_APP_B2C_URL" \
        -H "X-API-Key: dev-api-key-1" \
        "$API_FRONT_DOOR_URL/api/v1/forms")
    
    if [[ "$CORS_RESPONSE" == "200" || "$CORS_RESPONSE" == "204" ]]; then
        echo -e "${GREEN}✓ CORS-anrop från Static Web App till Front Door fungerar (statuskod: $CORS_RESPONSE)${NC}"
    else
        echo -e "${RED}✗ CORS-anrop från Static Web App till Front Door fungerar inte (statuskod: $CORS_RESPONSE)${NC}"
    fi
    
    # Simulera CORS preflight
    echo -e "\nOPTIONS $API_FRONT_DOOR_URL/api/v1/forms (CORS preflight)"
    OPTIONS_RESPONSE=$(curl -s -o cors_headers.txt -w "%{http_code}" -X OPTIONS \
        -H "Origin: $STATIC_WEB_APP_B2C_URL" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type, X-API-Key" \
        "$API_FRONT_DOOR_URL/api/v1/forms")
    
    if [[ "$OPTIONS_RESPONSE" == "200" || "$OPTIONS_RESPONSE" == "204" ]]; then
        echo -e "${GREEN}✓ CORS preflight-anrop fungerar (statuskod: $OPTIONS_RESPONSE)${NC}"
        
        # Visa CORS headers
        echo -e "\n${BLUE}CORS-headers från API via Front Door:${NC}"
        grep -i "access-control" cors_headers.txt
    else
        echo -e "${RED}✗ CORS preflight-anrop fungerar inte (statuskod: $OPTIONS_RESPONSE)${NC}"
    fi
    
    # Testa direkt anslutning till App Service (som troligen är begränsad)
    echo -e "\nGET $API_DIRECT_URL/api/v1/forms (direkt till App Service)"
    DIRECT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Origin: $STATIC_WEB_APP_B2C_URL" \
        -H "X-API-Key: dev-api-key-1" \
        "$API_DIRECT_URL/api/v1/forms")
    
    if [[ "$DIRECT_RESPONSE" == "200" || "$DIRECT_RESPONSE" == "204" ]]; then
        echo -e "${GREEN}✓ Direkt anrop till App Service fungerar (statuskod: $DIRECT_RESPONSE)${NC}"
        echo -e "${YELLOW}⚠ Notera att detta kan vara ett säkerhetsproblem om App Service ska vara begränsad till VNet${NC}"
    else
        echo -e "${YELLOW}⚠ Direkt anrop till App Service är begränsat (statuskod: $DIRECT_RESPONSE)${NC}"
        echo -e "${GREEN}✓ Detta är förväntat om App Service är korrekt begränsad till VNet${NC}"
    fi
}

# Funktion för att föreslå lösningar baserat på diagnosresultat
suggest_solutions() {
    echo -e "${CYAN}Föreslår möjliga lösningar baserat på diagnostikresultat...${NC}"
    
    # Kontrollera om Front Door är korrekt konfigurerad
    FRONT_DOOR_WORKS=0
    curl -s -o /dev/null -w "%{http_code}" "$API_FRONT_DOOR_URL/api/health" | grep -q "2[0-9][0-9]\|3[0-9][0-9]" && FRONT_DOOR_WORKS=1
    
    # Kontrollera om direktåtkomst till App Service fungerar
    APP_SERVICE_DIRECT_WORKS=0
    curl -s -o /dev/null -w "%{http_code}" "$API_DIRECT_URL/api/health" | grep -q "2[0-9][0-9]\|3[0-9][0-9]" && APP_SERVICE_DIRECT_WORKS=1
    
    # Kontrollera om CORS-preflight fungerar
    CORS_WORKS=0
    curl -s -o /dev/null -X OPTIONS \
        -H "Origin: $STATIC_WEB_APP_B2C_URL" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type, X-API-Key" \
        -w "%{http_code}" "$API_FRONT_DOOR_URL/api/v1/forms" | grep -q "2[0-9][0-9]" && CORS_WORKS=1
    
    echo -e "\n${BLUE}Diagnostikresultat:${NC}"
    
    if [ $FRONT_DOOR_WORKS -eq 1 ]; then
        echo -e "${GREEN}✓ Front Door är tillgänglig och svarar korrekt${NC}"
    else
        echo -e "${RED}✗ Front Door svarar inte korrekt${NC}"
        echo -e "  ${YELLOW}Förslag:${NC}"
        echo -e "  - Kontrollera att Azure Front Door är korrekt konfigurerad"
        echo -e "  - Verifiera att backend pool pekar på rätt App Service"
        echo -e "  - Kontrollera att routing rules är korrekt konfigurerade"
        echo -e "  - Säkerställ att hälsosonderna är konfigurerade korrekt"
    fi
    
    if [ $APP_SERVICE_DIRECT_WORKS -eq 1 ]; then
        echo -e "${GREEN}✓ App Service är direkt tillgänglig${NC}"
        
        if [ $FRONT_DOOR_WORKS -eq 0 ]; then
            echo -e "  ${YELLOW}Förslag:${NC}"
            echo -e "  - App Service är tillgänglig men Front Door fungerar inte, kontrollera Front Door-konfigurationen"
        fi
    else
        echo -e "${YELLOW}⚠ App Service är inte direkt tillgänglig${NC}"
        echo -e "  ${BLUE}Detta kan vara förväntat om App Service är begränsad till VNet${NC}"
        
        if [ $FRONT_DOOR_WORKS -eq 0 ]; then
            echo -e "  ${RED}Både App Service och Front Door är otillgängliga${NC}"
            echo -e "  ${YELLOW}Förslag:${NC}"
            echo -e "  - Kontrollera att App Service är igång och kör"
            echo -e "  - Verifiera att VNet-integrationerna är korrekt konfigurerade"
            echo -e "  - Kontrollera att private endpoints är korrekt konfigurerade"
            echo -e "  - Säkerställ att Front Door har korrekt tillgång till App Service"
        fi
    fi
    
    if [ $CORS_WORKS -eq 1 ]; then
        echo -e "${GREEN}✓ CORS-konfigurationen fungerar korrekt${NC}"
    else
        echo -e "${RED}✗ CORS-konfigurationen fungerar inte korrekt${NC}"
        echo -e "  ${YELLOW}Förslag:${NC}"
        echo -e "  - Kontrollera att CORS är konfigurerat i App Service med rätt ursprung"
        echo -e "  - Verifiera att Front Door vidarebefordrar CORS-headers"
        echo -e "  - Säkerställ att följande origins är tillåtna: $STATIC_WEB_APP_B2C_URL"
        echo -e "  - Kontrollera att Access-Control-Allow-Headers inkluderar 'X-API-Key'"
    fi
    
    echo -e "\n${BLUE}Övergripande rekommendationer:${NC}"
    
    if [ $FRONT_DOOR_WORKS -eq 0 ] || [ $CORS_WORKS -eq 0 ]; then
        echo -e "${YELLOW}1. Front Door-konfiguration:${NC}"
        echo -e "   - Säkerställ att Azure Front Door har korrekt backend pool som pekar på din App Service"
        echo -e "   - Kontrollera att routing rules är konfigurerade för att skicka trafik till rätt backend pool"
        echo -e "   - Verifiera att hälsosonderna är konfigurerade korrekt"
        echo -e "   - Se till att Front Door är godkänd av din organisations IT-policy"
        
        echo -e "\n${YELLOW}2. CORS-konfiguration:${NC}"
        echo -e "   - I App Service, lägg till följande origins i CORS-inställningarna:"
        echo -e "     * $STATIC_WEB_APP_B2C_URL"
        echo -e "     * https://*.azurestaticapps.net"
        echo -e "   - Säkerställ att 'Access-Control-Allow-Headers' inkluderar 'Content-Type, X-API-Key'"
        echo -e "   - Kontrollera att 'Access-Control-Allow-Methods' inkluderar 'GET, POST, OPTIONS'"
        
        echo -e "\n${YELLOW}3. VNet-konfiguration:${NC}"
        echo -e "   - Verifiera att App Service är korrekt integrerad med VNet"
        echo -e "   - Kontrollera att private endpoints är korrekt konfigurerade"
        echo -e "   - Säkerställ att NSG-regler tillåter trafik från Front Door till App Service"
        echo -e "   - Kontrollera att DNS-upplösning fungerar korrekt för private endpoints"
        
        echo -e "\n${YELLOW}4. Front Door-specifika rekommendationer:${NC}"
        echo -e "   - Aktivera 'Send Custom Host Header' i backend pool-inställningarna"
        echo -e "   - Använd 'Forward host header' för att säkerställa att App Service får rätt host header"
        echo -e "   - Kontrollera att cache-inställningarna är korrekta"
        echo -e "   - Verifiera att WAF-inställningar (om aktiverade) inte blockerar legitim trafik"
    else
        echo -e "${GREEN}✓ Diagnostiken indikerar att grundläggande kommunikation fungerar.${NC}"
        echo -e "  Om du fortfarande upplever problem, kontrollera:"
        echo -e "  - Specifika API-anrop från formulären"
        echo -e "  - Autentisering med API-nyckel"
        echo -e "  - Specifika CORS-problem med vissa HTTP-metoder"
        echo -e "  - Formulärens konfiguration av API-URL och API-nyckel"
    fi
}

# Huvudprogramloop
while true; do
    echo -e "${BLUE}Välj ett diagnostiktest att köra:${NC}"
    echo "1) Utför nätverksdiagnostik"
    echo "2) Analysera Front Door-konfiguration"
    echo "3) Analysera VNet-konfiguration"
    echo "4) Analysera App Service-konfiguration"
    echo "5) Analysera Static Web App-konfiguration"
    echo "6) Testa VNet och DNS-konfiguration"
    echo "7) Få rekommenderade lösningar"
    echo "8) Kör alla tester"
    echo "9) Ändra resursgruppsnamn (nuvarande: $RESOURCE_GROUP)"
    echo "q) Avsluta"
    
    read -p "Välj alternativ: " option
    echo ""
    
    case $option in
        1)
            network_diagnosis
            ;;
        2)
            analyze_front_door
            ;;
        3)
            analyze_vnet
            ;;
        4)
            analyze_app_service
            ;;
        5)
            analyze_static_web_app
            ;;
        6)
            test_vnet_dns
            ;;
        7)
            suggest_solutions
            ;;
        8)
            network_diagnosis
            analyze_front_door
            analyze_vnet
            analyze_app_service
            analyze_static_web_app
            test_vnet_dns
            suggest_solutions
            ;;
        9)
            read -p "Ange nytt resursgruppsnamn: " new_rg
            if [ -n "$new_rg" ]; then
                RESOURCE_GROUP=$new_rg
                echo -e "${GREEN}Resursgruppsnamn uppdaterat till: $RESOURCE_GROUP${NC}"
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
