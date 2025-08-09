#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
RESOURCE_GROUP="rg-hsq-forms-dev"
FRONTDOOR_PROFILE_NAME="fd-hsq-forms-dev"
ENDPOINT_NAME="hsq-forms-dev"
APP_SERVICE_NAME="hsq-forms-api-dev"

echo -e "${BLUE}==== Testing Front Door Integration ====${NC}"

# Get Front Door URL
FRONTDOOR_URL=$(az afd endpoint show --endpoint-name $ENDPOINT_NAME --profile-name $FRONTDOOR_PROFILE_NAME --resource-group $RESOURCE_GROUP --query "hostName" -o tsv)
if [ -z "$FRONTDOOR_URL" ]; then
    echo -e "${RED}Error: Could not retrieve Front Door URL${NC}"
    exit 1
fi

echo -e "${BLUE}Front Door URL: ${GREEN}https://$FRONTDOOR_URL${NC}"

# Get App Service URL
APP_URL=$(az webapp show --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP --query "defaultHostName" -o tsv)
if [ -z "$APP_URL" ]; then
    echo -e "${RED}Error: Could not get App Service URL${NC}"
    exit 1
fi

echo -e "${BLUE}App Service URL: ${NC}https://$APP_URL"

# Test health endpoint through Front Door
echo -e "\n${BLUE}Testing health endpoint through Front Door:${NC}"
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://$FRONTDOOR_URL/health)
if [ "$HEALTH_RESPONSE" == "200" ]; then
    echo -e "${GREEN}Health endpoint accessible through Front Door: $HEALTH_RESPONSE${NC}"
else
    echo -e "${RED}Health endpoint not accessible through Front Door: $HEALTH_RESPONSE${NC}"
fi

# Test API endpoint through Front Door
echo -e "\n${BLUE}Testing API endpoint through Front Door:${NC}"
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://$FRONTDOOR_URL/api/v1/forms)
if [ "$API_RESPONSE" == "200" ]; then
    echo -e "${GREEN}API endpoint accessible through Front Door: $API_RESPONSE${NC}"
else
    echo -e "${RED}API endpoint not accessible through Front Door: $API_RESPONSE${NC}"
fi

# Get Static Web App URLs
echo -e "\n${BLUE}Static Web App URLs:${NC}"
az staticwebapp list --resource-group $RESOURCE_GROUP --query "[].{Name:name, URL:defaultHostname}" -o table

# Test CORS from Static Web Apps to Front Door
echo -e "\n${BLUE}Testing CORS from Static Web Apps to Front Door:${NC}"
SWA_DOMAINS=$(az staticwebapp list --resource-group $RESOURCE_GROUP --query "[].defaultHostname" -o tsv)

for domain in $SWA_DOMAINS; do
    echo -e "${YELLOW}Testing CORS from: https://$domain${NC}"
    CORS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Origin: https://$domain" \
                       -H "Access-Control-Request-Method: GET" \
                       -X OPTIONS https://$FRONTDOOR_URL/api/v1/forms)
    
    if [ "$CORS_RESPONSE" == "200" ] || [ "$CORS_RESPONSE" == "204" ]; then
        echo -e "${GREEN}CORS preflight successful: $CORS_RESPONSE${NC}"
    else
        echo -e "${RED}CORS preflight failed: $CORS_RESPONSE${NC}"
    fi
done

# Test Front Door routing
echo -e "\n${BLUE}Testing Front Door routing configuration:${NC}"
ROUTE_TEST=$(curl -s -I -X GET https://$FRONTDOOR_URL/health)
if echo "$ROUTE_TEST" | grep -q "X-Azure-Ref:"; then
    echo -e "${GREEN}Front Door routing correctly configured${NC}"
    echo -e "${YELLOW}Response headers:${NC}"
    echo "$ROUTE_TEST" | grep -E "(X-Azure|Content-Type|Server|Access-Control)" 
else
    echo -e "${RED}Front Door routing may not be correctly configured${NC}"
fi

echo -e "\n${BLUE}==== Integration Test Complete ====${NC}"
