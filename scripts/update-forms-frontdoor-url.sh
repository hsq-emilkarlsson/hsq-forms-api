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
    
    # Find all HTML and JS files
    HTML_FILES=$(find $form_dir -type f -name "*.html")
    JS_FILES=$(find $form_dir -type f -name "*.js")
    
    # Update API URL in HTML files
    for file in $HTML_FILES; do
        echo -e "  ${BLUE}Updating file: $(basename $file)${NC}"
        
        # Check if file contains API URL configuration
        if grep -q "apiBaseUrl" $file; then
            # Update API URL with Front Door URL
            sed -i "s|apiBaseUrl:.*|apiBaseUrl: \"https://$FRONTDOOR_URL\",|g" $file
            echo -e "  ${GREEN}Updated API URL in $(basename $file)${NC}"
        else
            echo -e "  ${YELLOW}No API URL configuration found in $(basename $file)${NC}"
        fi
        
        # Add debugger script if not already added
        if ! grep -q "hsq-forms-debugger.js" $file; then
            echo -e "  ${BLUE}Adding debugger script to $(basename $file)${NC}"
            
            # Find the closing head tag and add the script before it
            sed -i "s|</head>|    <script src=\"/scripts/hsq-forms-debugger.js\"></script>\n</head>|g" $file
            echo -e "  ${GREEN}Added debugger script to $(basename $file)${NC}"
        else
            echo -e "  ${YELLOW}Debugger script already added to $(basename $file)${NC}"
        fi
    done
    
    # Update API URL in JS files
    for file in $JS_FILES; do
        echo -e "  ${BLUE}Updating file: $(basename $file)${NC}"
        
        # Check if file contains API URL configuration
        if grep -q "apiBaseUrl" $file; then
            # Update API URL with Front Door URL
            sed -i "s|apiBaseUrl:.*|apiBaseUrl: \"https://$FRONTDOOR_URL\",|g" $file
            sed -i "s|const apiBaseUrl =.*|const apiBaseUrl = \"https://$FRONTDOOR_URL\";|g" $file
            echo -e "  ${GREEN}Updated API URL in $(basename $file)${NC}"
        else
            echo -e "  ${YELLOW}No API URL configuration found in $(basename $file)${NC}"
        fi
    done
done

echo -e "\n${BLUE}==== Forms Update Complete ====${NC}"
echo -e "${YELLOW}Don't forget to commit and push your changes!${NC}"
