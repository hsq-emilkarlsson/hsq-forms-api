#!/bin/bash

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
RESOURCE_GROUP="rg-hsq-forms-dev"
FRONTDOOR_PROFILE_NAME="hsq-forms-frontdoor-dev"
ENDPOINT_NAME="hsq-forms-endpoint-dev"
ORIGIN_GROUP_NAME="hsq-forms-api-origin-group"
ORIGIN_NAME="hsq-forms-api-origin"
APP_SERVICE_NAME="hsq-forms-api-dev"
LOCATION="westeurope"

echo -e "${BLUE}==== Creating and Configuring Azure Front Door (Standard) ====${NC}"

# Check if Front Door profile exists
EXISTING_FD=$(az afd profile list --query "[?name=='$FRONTDOOR_PROFILE_NAME'].name" -o tsv)
if [ -n "$EXISTING_FD" ]; then
    echo -e "${YELLOW}Front Door profile $FRONTDOOR_PROFILE_NAME already exists. Skipping creation.${NC}"
else
    # Create Front Door profile
    echo -e "${BLUE}Creating Front Door profile: $FRONTDOOR_PROFILE_NAME${NC}"
    
    az afd profile create \
        --profile-name $FRONTDOOR_PROFILE_NAME \
        --resource-group $RESOURCE_GROUP \
        --sku Standard_AzureFrontDoor \
        --tags ApplicationMaster=APP1066 CostCenter=1881130 EnvironmentType=Dev
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to create Front Door profile${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Front Door profile created successfully!${NC}"
fi

# Get App Service URL
APP_SERVICE_URL=$(az webapp show --name $APP_SERVICE_NAME --resource-group $RESOURCE_GROUP --query "defaultHostName" -o tsv)
if [ -z "$APP_SERVICE_URL" ]; then
    echo -e "${RED}Error: Could not retrieve App Service URL${NC}"
    exit 1
fi

# Create endpoint if it doesn't exist
EXISTING_ENDPOINT=$(az afd endpoint list --profile-name $FRONTDOOR_PROFILE_NAME --resource-group $RESOURCE_GROUP --query "[?name=='$ENDPOINT_NAME'].name" -o tsv)
if [ -n "$EXISTING_ENDPOINT" ]; then
    echo -e "${YELLOW}Endpoint $ENDPOINT_NAME already exists. Skipping creation.${NC}"
else
    # Create endpoint
    echo -e "${BLUE}Creating Front Door endpoint: $ENDPOINT_NAME${NC}"
    
    az afd endpoint create \
        --endpoint-name $ENDPOINT_NAME \
        --profile-name $FRONTDOOR_PROFILE_NAME \
        --resource-group $RESOURCE_GROUP
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to create Front Door endpoint${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Front Door endpoint created successfully!${NC}"
fi

# Create origin group if it doesn't exist
EXISTING_ORIGIN_GROUP=$(az afd origin-group list --profile-name $FRONTDOOR_PROFILE_NAME --resource-group $RESOURCE_GROUP --query "[?name=='$ORIGIN_GROUP_NAME'].name" -o tsv)
if [ -n "$EXISTING_ORIGIN_GROUP" ]; then
    echo -e "${YELLOW}Origin group $ORIGIN_GROUP_NAME already exists. Skipping creation.${NC}"
else
    # Create origin group
    echo -e "${BLUE}Creating origin group: $ORIGIN_GROUP_NAME${NC}"
    
    az afd origin-group create \
        --origin-group-name $ORIGIN_GROUP_NAME \
        --profile-name $FRONTDOOR_PROFILE_NAME \
        --resource-group $RESOURCE_GROUP \
        --probe-request-type GET \
        --probe-path /health \
        --probe-protocol Http \
        --probe-interval-in-seconds 120 \
        --sample-size 4 \
        --successful-samples-required 3 \
        --additional-latency-in-milliseconds 50
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to create origin group${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Origin group created successfully!${NC}"
fi

# Create origin if it doesn't exist
EXISTING_ORIGIN=$(az afd origin list --origin-group-name $ORIGIN_GROUP_NAME --profile-name $FRONTDOOR_PROFILE_NAME --resource-group $RESOURCE_GROUP --query "[?name=='$ORIGIN_NAME'].name" -o tsv)
if [ -n "$EXISTING_ORIGIN" ]; then
    echo -e "${YELLOW}Origin $ORIGIN_NAME already exists. Skipping creation.${NC}"
else
    # Create origin
    echo -e "${BLUE}Creating origin: $ORIGIN_NAME with host $APP_SERVICE_URL${NC}"
    
    az afd origin create \
        --origin-name $ORIGIN_NAME \
        --origin-group-name $ORIGIN_GROUP_NAME \
        --profile-name $FRONTDOOR_PROFILE_NAME \
        --resource-group $RESOURCE_GROUP \
        --host-name $APP_SERVICE_URL \
        --origin-host-header $APP_SERVICE_URL \
        --priority 1 \
        --weight 1000 \
        --enabled-state Enabled \
        --http-port 80 \
        --https-port 443
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to create origin${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Origin created successfully!${NC}"
fi

# Create route if it doesn't exist
ROUTE_NAME="hsq-forms-api-route"
EXISTING_ROUTE=$(az afd route list --profile-name $FRONTDOOR_PROFILE_NAME --endpoint-name $ENDPOINT_NAME --resource-group $RESOURCE_GROUP --query "[?name=='$ROUTE_NAME'].name" -o tsv)
if [ -n "$EXISTING_ROUTE" ]; then
    echo -e "${YELLOW}Route $ROUTE_NAME already exists. Skipping creation.${NC}"
else
    # Create route
    echo -e "${BLUE}Creating route: $ROUTE_NAME${NC}"
    
    az afd route create \
        --route-name $ROUTE_NAME \
        --profile-name $FRONTDOOR_PROFILE_NAME \
        --endpoint-name $ENDPOINT_NAME \
        --resource-group $RESOURCE_GROUP \
        --origin-group $ORIGIN_GROUP_NAME \
        --supported-protocols Http Https \
        --patterns-to-match '/*' \
        --forwarding-protocol HttpsOnly \
        --https-redirect Enabled \
        --link-to-default-domain Enabled
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to create route${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Route created successfully!${NC}"
fi

# Update App Service to allow Front Door
echo -e "\n${BLUE}Configuring App Service to allow access from Front Door${NC}"

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

# Configure CORS for Static Web Apps
echo -e "\n${BLUE}Configuring CORS for Static Web Apps${NC}"

# Get Static Web App URLs
SWA_DOMAINS=$(az staticwebapp list --resource-group $RESOURCE_GROUP --query "[].defaultHostname" -o tsv)

# Prepare CORS headers
CORS_HEADERS="'https://*.azurestaticapps.net'"
for domain in $SWA_DOMAINS; do
    CORS_HEADERS="$CORS_HEADERS,'https://$domain'"
done

# Get Front Door endpoint URL
FRONTDOOR_ENDPOINT=$(az afd endpoint show --endpoint-name $ENDPOINT_NAME --profile-name $FRONTDOOR_PROFILE_NAME --resource-group $RESOURCE_GROUP --query "hostName" -o tsv)
if [ -n "$FRONTDOOR_ENDPOINT" ]; then
    CORS_HEADERS="$CORS_HEADERS,'https://$FRONTDOOR_ENDPOINT'"
fi

# Set CORS in App Service
az webapp cors add --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME --allowed-origins $CORS_HEADERS

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to configure CORS${NC}"
else
    echo -e "${GREEN}CORS configured successfully!${NC}"
fi

# Get Front Door endpoint URL
FRONTDOOR_URL=$(az afd endpoint show --endpoint-name $ENDPOINT_NAME --profile-name $FRONTDOOR_PROFILE_NAME --resource-group $RESOURCE_GROUP --query "hostName" -o tsv)

echo -e "\n${BLUE}Front Door URL: ${GREEN}https://$FRONTDOOR_URL${NC}"
echo -e "${YELLOW}It may take a few minutes for Front Door configuration to propagate${NC}"

echo -e "\n${BLUE}==== Front Door Setup Complete ====${NC}"
