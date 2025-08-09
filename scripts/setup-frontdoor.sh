#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
RESOURCE_GROUP="rg-hsq-forms-dev"
FRONTDOOR_NAME="hsq-forms-frontdoor-dev"
APP_SERVICE_NAME="hsq-forms-api-dev"
LOCATION="westeurope"

echo -e "${BLUE}==== Creating and Configuring Azure Front Door ====${NC}"

# Check if Front Door exists
EXISTING_FD=$(az network front-door list --query "[?name=='$FRONTDOOR_NAME'].name" -o tsv)
if [ -n "$EXISTING_FD" ]; then
    echo -e "${YELLOW}Front Door $FRONTDOOR_NAME already exists. Skipping creation.${NC}"
else
    # Get App Service URL
    APP_SERVICE_URL=$(az webapp show --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP --query "defaultHostName" -o tsv)
    if [ -z "$APP_SERVICE_URL" ]; then
        echo -e "${RED}Error: Could not retrieve App Service URL${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Creating Front Door: $FRONTDOOR_NAME${NC}"
    
    # Create Front Door with basic configuration
    az network front-door create \
        --name $FRONTDOOR_NAME \
        --resource-group $RESOURCE_GROUP \
        --backend-address $APP_SERVICE_URL \
        --tags ApplicationMaster=APP1066 CostCenter=1881130 EnvironmentType=Dev
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to create Front Door${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Front Door created successfully!${NC}"
fi

# Update App Service to allow Front Door
echo -e "\n${BLUE}Configuring App Service to allow access from Front Door${NC}"

# Get the current access restrictions
CURRENT_RESTRICTIONS=$(az webapp config access-restriction show --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME --query "ipSecurityRestrictions" -o json)

# Check if "AzureFrontDoor.Backend" rule already exists
FD_RULE_EXISTS=$(echo $CURRENT_RESTRICTIONS | grep -c "AzureFrontDoor.Backend" || true)

if [ "$FD_RULE_EXISTS" -gt 0 ]; then
    echo -e "${YELLOW}Front Door access rule already exists for App Service${NC}"
else
    # Add Front Door service tag rule
    az webapp config access-restriction add \
        --resource-group $RESOURCE_GROUP \
        --name $APP_SERVICE_NAME \
        --rule-name "Allow-FrontDoor" \
        --action Allow \
        --priority 100 \
        --service-tag AzureFrontDoor.Backend
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to add Front Door access rule to App Service${NC}"
    else
        echo -e "${GREEN}Front Door access rule added to App Service${NC}"
    fi
fi

# Configure CORS for Static Web Apps
echo -e "\n${BLUE}Configuring CORS for Static Web Apps${NC}"

# Get Static Web App URLs
SWA_DOMAINS=$(az staticwebapp list --resource-group $RESOURCE_GROUP --query "[].defaultHostname" -o tsv)

# Prepare CORS headers
CORS_HEADERS="'https://*.azurestaticapps.net'"
for domain in $SWA_DOMAINS; do
    CORS_HEADERS="$CORS_HEADERS,'https://$domain'"
done

# Set CORS in App Service
az webapp cors add --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME --allowed-origins $CORS_HEADERS

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to configure CORS${NC}"
else
    echo -e "${GREEN}CORS configured successfully!${NC}"
fi

# Get Front Door URL
FRONTDOOR_URL=$(az network front-door show --name $FRONTDOOR_NAME --resource-group $RESOURCE_GROUP --query "frontendEndpoints[0].hostName" -o tsv)

echo -e "\n${BLUE}Front Door URL: ${GREEN}https://$FRONTDOOR_URL${NC}"
echo -e "${YELLOW}It may take a few minutes for Front Door configuration to propagate${NC}"

echo -e "\n${BLUE}==== Front Door Setup Complete ====${NC}"
