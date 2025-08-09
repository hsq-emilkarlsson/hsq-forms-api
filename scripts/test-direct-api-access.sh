#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get App Service details
APP_SERVICE_NAME="hsq-forms-api-dev"
RESOURCE_GROUP="rg-hsq-forms-dev"

echo -e "${BLUE}==== Testing Direct API Access ====${NC}"
echo -e "${YELLOW}This script tests direct access to the API from various sources${NC}"

# Get App Service URL
APP_URL=$(az webapp show --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP --query "defaultHostName" -o tsv)
if [ -z "$APP_URL" ]; then
    echo -e "${RED}Error: Could not get App Service URL${NC}"
    exit 1
fi

echo -e "${BLUE}App Service URL: ${NC}https://$APP_URL"

# Test health endpoint
echo -e "\n${BLUE}Testing health endpoint direct access:${NC}"
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://$APP_URL/health)
if [ "$HEALTH_RESPONSE" == "200" ]; then
    echo -e "${GREEN}Health endpoint accessible: $HEALTH_RESPONSE${NC}"
else
    echo -e "${RED}Health endpoint not accessible: $HEALTH_RESPONSE${NC}"
fi

# Test API endpoint
echo -e "\n${BLUE}Testing API endpoint direct access:${NC}"
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://$APP_URL/api/v1/forms)
if [ "$API_RESPONSE" == "200" ]; then
    echo -e "${GREEN}API endpoint accessible: $API_RESPONSE${NC}"
else
    echo -e "${RED}API endpoint not accessible: $API_RESPONSE${NC}"
fi

# Get Static Web App URLs
echo -e "\n${BLUE}Static Web App URLs:${NC}"
az staticwebapp list --resource-group $RESOURCE_GROUP --query "[].{Name:name, URL:defaultHostname}" -o table

# Test CORS with actual Static Web App origins
echo -e "\n${BLUE}Testing CORS from Static Web Apps to API:${NC}"
SWA_DOMAINS=$(az staticwebapp list --resource-group $RESOURCE_GROUP --query "[].defaultHostname" -o tsv)

for domain in $SWA_DOMAINS; do
    echo -e "${YELLOW}Testing CORS from: https://$domain${NC}"
    CORS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Origin: https://$domain" \
                       -H "Access-Control-Request-Method: GET" \
                       -X OPTIONS https://$APP_URL/api/v1/forms)
    
    if [ "$CORS_RESPONSE" == "200" ] || [ "$CORS_RESPONSE" == "204" ]; then
        echo -e "${GREEN}CORS preflight successful: $CORS_RESPONSE${NC}"
    else
        echo -e "${RED}CORS preflight failed: $CORS_RESPONSE${NC}"
    fi
done

echo -e "\n${BLUE}==== Direct Access Test Complete ====${NC}"
