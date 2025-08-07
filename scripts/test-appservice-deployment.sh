#!/bin/bash
# test-appservice-deployment.sh
# Detta script verifierar en App Service-deployment för HSQ Forms API

set -e

# Färger för output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Hämta parametrar
RESOURCE_GROUP=${1:-""}
APP_SERVICE_NAME=${2:-""}
ENVIRONMENT=${3:-"dev"}

if [ -z "$RESOURCE_GROUP" ] || [ -z "$APP_SERVICE_NAME" ]; then
    echo -e "${RED}Användning: $0 <resource-group-name> <app-service-name> [environment]${NC}"
    echo -e "${YELLOW}Exempel: $0 rg-hsq-forms-dev hsq-forms-dev-app dev${NC}"
    exit 1
fi

echo -e "${BLUE}=== HSQ Forms API - App Service Deployment Test ===${NC}"
echo -e "${BLUE}Resource Group: ${YELLOW}$RESOURCE_GROUP${NC}"
echo -e "${BLUE}App Service: ${YELLOW}$APP_SERVICE_NAME${NC}"
echo -e "${BLUE}Environment: ${YELLOW}$ENVIRONMENT${NC}"

# Kontrollera att Azure CLI är installerat
if ! command -v az &> /dev/null; then
    echo -e "${RED}Azure CLI är inte installerat. Installera det först.${NC}"
    exit 1
fi

# Kontrollera att användaren är inloggad i Azure
echo -e "${BLUE}Kontrollerar Azure-inloggning...${NC}"
az account show > /dev/null 2>&1 || { 
    echo -e "${RED}Du är inte inloggad i Azure. Kör 'az login' först.${NC}"
    exit 1
}

# Steg 1: Kontrollera att resursgruppen finns
echo -e "${BLUE}Kontrollerar resursgrupp...${NC}"
if az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Resursgrupp $RESOURCE_GROUP finns${NC}"
else
    echo -e "${RED}✗ Resursgrupp $RESOURCE_GROUP finns inte${NC}"
    exit 1
fi

# Steg 2: Kontrollera att App Service finns
echo -e "${BLUE}Kontrollerar App Service...${NC}"
if az webapp show --name "$APP_SERVICE_NAME" --resource-group "$RESOURCE_GROUP" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ App Service $APP_SERVICE_NAME finns${NC}"
else
    echo -e "${RED}✗ App Service $APP_SERVICE_NAME finns inte${NC}"
    exit 1
fi

# Steg 3: Kontrollera App Service-status
echo -e "${BLUE}Kontrollerar App Service-status...${NC}"
STATE=$(az webapp show --name "$APP_SERVICE_NAME" --resource-group "$RESOURCE_GROUP" --query "state" -o tsv)
if [ "$STATE" == "Running" ]; then
    echo -e "${GREEN}✓ App Service är igång (Status: $STATE)${NC}"
else
    echo -e "${RED}✗ App Service är inte igång (Status: $STATE)${NC}"
fi

# Steg 4: Kontrollera viktiga app-inställningar
echo -e "${BLUE}Kontrollerar app-inställningar...${NC}"
SETTINGS=$(az webapp config appsettings list --name "$APP_SERVICE_NAME" --resource-group "$RESOURCE_GROUP" -o json)

check_setting() {
    local SETTING_NAME=$1
    local SETTING_VALUE=$(echo $SETTINGS | jq -r ".[] | select(.name==\"$SETTING_NAME\") | .value")
    
    if [ -n "$SETTING_VALUE" ] && [ "$SETTING_VALUE" != "null" ]; then
        if [ "$SETTING_NAME" == "SQLALCHEMY_DATABASE_URI" ] || [ "$SETTING_NAME" == "AZURE_STORAGE_ACCOUNT_KEY" ]; then
            # Dölj känsliga värden
            echo -e "${GREEN}✓ $SETTING_NAME är konfigurerad${NC}"
        else
            echo -e "${GREEN}✓ $SETTING_NAME: $SETTING_VALUE${NC}"
        fi
    else
        echo -e "${RED}✗ $SETTING_NAME saknas${NC}"
    fi
}

# Kontrollera viktiga inställningar
check_setting "SQLALCHEMY_DATABASE_URI"
check_setting "ENVIRONMENT"
check_setting "AZURE_STORAGE_ACCOUNT_NAME"
check_setting "AZURE_STORAGE_CONTAINER_NAME"
check_setting "AZURE_CLIENT_ID"
check_setting "STARTUP_COMMAND"

# Steg 5: Kontrollera att App Service är tillgänglig
echo -e "${BLUE}Kontrollerar App Service-tillgänglighet...${NC}"
APP_URL=$(az webapp show --name "$APP_SERVICE_NAME" --resource-group "$RESOURCE_GROUP" --query "defaultHostName" -o tsv)

if [ -n "$APP_URL" ]; then
    echo -e "${BLUE}Kontrollerar URL: https://$APP_URL/docs${NC}"
    if curl -s -o /dev/null -w "%{http_code}" "https://$APP_URL/docs" | grep -q "200\|301\|302"; then
        echo -e "${GREEN}✓ API är tillgänglig på https://$APP_URL/docs${NC}"
    else
        echo -e "${RED}✗ API är inte tillgänglig på https://$APP_URL/docs${NC}"
    fi
else
    echo -e "${RED}✗ Kunde inte hämta App Service URL${NC}"
fi

# Steg 6: Visa deployment-information
echo -e "${BLUE}Hämtar senaste deployment...${NC}"
az webapp deployment list --resource-group "$RESOURCE_GROUP" --name "$APP_SERVICE_NAME" --query "[0]" -o table

# Steg 7: Visa resurser i resursgruppen
echo -e "${BLUE}Alla resurser i resursgruppen:${NC}"
az resource list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Type:type, Location:location}" -o table

echo -e "${BLUE}=== Test slutfört ===${NC}"
