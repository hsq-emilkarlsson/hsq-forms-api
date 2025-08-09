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
FORMS_DIR="/workspaces/hsq-forms-api/forms"

echo -e "${BLUE}==== Updating Forms with Front Door URL ====${NC}"

# Get Front Door URL
FRONTDOOR_URL=$(az afd endpoint show --endpoint-name $ENDPOINT_NAME --profile-name $FRONTDOOR_PROFILE_NAME --resource-group $RESOURCE_GROUP --query "hostName" -o tsv)
if [ -z "$FRONTDOOR_URL" ]; then
    echo -e "${RED}Error: Could not retrieve Front Door URL${NC}"
    exit 1
fi

echo -e "${BLUE}Front Door URL: ${GREEN}https://$FRONTDOOR_URL${NC}"

# Update all forms with Front Door URL
echo -e "\n${BLUE}Updating forms with Front Door URL${NC}"

# Find all form directories
FORM_DIRS=$(find $FORMS_DIR -type d -name "hsq-forms-container-*")
for form_dir in $FORM_DIRS; do
    form_name=$(basename $form_dir)
    echo -e "${YELLOW}Updating form: $form_name${NC}"
    
    # Check for .env file
    ENV_FILE="$form_dir/.env"
    if [ -f "$ENV_FILE" ]; then
        echo -e "  ${BLUE}Updating .env file${NC}"
        # Update API URL with Front Door URL
        if grep -q "VITE_API_URL" "$ENV_FILE"; then
            sed -i "s|VITE_API_URL=.*|VITE_API_URL=https://$FRONTDOOR_URL|g" "$ENV_FILE"
            echo -e "  ${GREEN}Updated VITE_API_URL in .env file${NC}"
        else
            echo -e "VITE_API_URL=https://$FRONTDOOR_URL" >> "$ENV_FILE"
            echo -e "  ${GREEN}Added VITE_API_URL to .env file${NC}"
        fi
    else
        echo -e "  ${BLUE}Creating .env file${NC}"
        echo "VITE_API_URL=https://$FRONTDOOR_URL" > "$ENV_FILE"
        echo -e "  ${GREEN}Created .env file with VITE_API_URL${NC}"
    fi
    
    # Check for .env.local file
    ENV_LOCAL_FILE="$form_dir/.env.local"
    if [ -f "$ENV_LOCAL_FILE" ]; then
        echo -e "  ${BLUE}Updating .env.local file${NC}"
        # Update API URL with Front Door URL
        if grep -q "VITE_API_URL" "$ENV_LOCAL_FILE"; then
            sed -i "s|VITE_API_URL=.*|VITE_API_URL=https://$FRONTDOOR_URL|g" "$ENV_LOCAL_FILE"
            echo -e "  ${GREEN}Updated VITE_API_URL in .env.local file${NC}"
        else
            echo -e "VITE_API_URL=https://$FRONTDOOR_URL" >> "$ENV_LOCAL_FILE"
            echo -e "  ${GREEN}Added VITE_API_URL to .env.local file${NC}"
        fi
    else
        echo -e "  ${BLUE}Creating .env.local file${NC}"
        echo "VITE_API_URL=https://$FRONTDOOR_URL" > "$ENV_LOCAL_FILE"
        echo -e "  ${GREEN}Created .env.local file with VITE_API_URL${NC}"
    fi
    
    # Add debugger script to index.html if not already added
    INDEX_HTML="$form_dir/index.html"
    if [ -f "$INDEX_HTML" ]; then
        if ! grep -q "hsq-forms-debugger.js" "$INDEX_HTML"; then
            echo -e "  ${BLUE}Adding debugger script to index.html${NC}"
            # Find the closing head tag and add the script before it
            sed -i "s|</head>|    <script src=\"/scripts/hsq-forms-debugger.js\"></script>\n</head>|g" "$INDEX_HTML"
            echo -e "  ${GREEN}Added debugger script to index.html${NC}"
        else
            echo -e "  ${YELLOW}Debugger script already added to index.html${NC}"
        fi
    else
        echo -e "  ${YELLOW}No index.html found in form directory${NC}"
    fi
done

echo -e "\n${BLUE}==== Forms Update Complete ====${NC}"
echo -e "${YELLOW}Don't forget to rebuild and redeploy the forms!${NC}"
