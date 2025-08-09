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
FORMS_DIR="/workspaces/hsq-forms-api/forms"

echo -e "${BLUE}==== Updating Forms with Existing Front Door URL ====${NC}"

# Get Front Door URL
FRONTDOOR_URL=$(az afd endpoint show --endpoint-name $ENDPOINT_NAME --profile-name $FRONTDOOR_PROFILE_NAME --resource-group $RESOURCE_GROUP --query "hostName" -o tsv)
if [ -z "$FRONTDOOR_URL" ]; then
    echo -e "${RED}Error: Could not retrieve Front Door URL${NC}"
    exit 1
fi

echo -e "${BLUE}Front Door URL: ${GREEN}https://$FRONTDOOR_URL${NC}"

# Find form source files with fetch calls
FORM_FILES=$(find $FORMS_DIR -type f -name "*.tsx" -o -name "*.ts" | xargs grep -l "fetch(" | sort)

if [ -z "$FORM_FILES" ]; then
    echo -e "${RED}No form files with fetch calls found${NC}"
    exit 1
fi

echo -e "\n${BLUE}Found ${#FORM_FILES[@]} form files with API calls${NC}"

# Update API URLs in form files
for file in $FORM_FILES; do
    echo -e "${YELLOW}Processing file: $file${NC}"
    
    # Check for existing URL patterns
    if grep -q "https://[^/]*\.azurewebsites\.net" "$file"; then
        echo -e "  ${BLUE}Found Azure Web App URL, replacing with Front Door URL${NC}"
        sed -i "s|https://[^/]*\.azurewebsites\.net|https://$FRONTDOOR_URL|g" "$file"
        echo -e "  ${GREEN}Replaced Azure Web App URL with Front Door URL${NC}"
    elif grep -q "https://[^/]*\.azurefd\.net" "$file"; then
        echo -e "  ${BLUE}Found existing Front Door URL, updating if needed${NC}"
        sed -i "s|https://[^/]*\.azurefd\.net|https://$FRONTDOOR_URL|g" "$file"
        echo -e "  ${GREEN}Updated Front Door URL${NC}"
    else
        # Find fetch URLs that might not have the full URL pattern
        FETCH_LINES=$(grep -n "fetch(" "$file" | cut -d: -f1)
        if [ -n "$FETCH_LINES" ]; then
            echo -e "  ${BLUE}Found fetch calls, checking for URL patterns${NC}"
            for line in $FETCH_LINES; do
                # Extract 5 lines before and after for context
                CONTEXT_START=$((line - 5))
                if [ $CONTEXT_START -lt 1 ]; then
                    CONTEXT_START=1
                fi
                CONTEXT_END=$((line + 5))
                
                CONTEXT=$(sed -n "${CONTEXT_START},${CONTEXT_END}p" "$file")
                
                # Check if URL pattern is relative (starting with /)
                if echo "$CONTEXT" | grep -q "fetch(\s*['\"]\/"; then
                    echo -e "  ${BLUE}Found relative API URL at line $line${NC}"
                    # Insert code to use the Front Door URL for relative paths
                    LINE_BEFORE=$((line - 1))
                    if ! grep -q "const API_BASE_URL" "$file"; then
                        # Add API base URL constant if it doesn't exist
                        sed -i "${LINE_BEFORE}i const API_BASE_URL = \"https://$FRONTDOOR_URL\";" "$file"
                        echo -e "  ${GREEN}Added API_BASE_URL constant${NC}"
                        
                        # Update fetch calls to use API_BASE_URL
                        sed -i "s|fetch(\s*[\'\"]\/|fetch(API_BASE_URL + \'/|g" "$file"
                        echo -e "  ${GREEN}Updated fetch calls to use API_BASE_URL${NC}"
                    fi
                fi
            done
        fi
    fi
    
    # Add debugger script to HTML files
    if [[ "$file" == *"/index.tsx" || "$file" == *"/main.tsx" ]]; then
        echo -e "  ${BLUE}Finding related HTML file for $file${NC}"
        FORM_DIR=$(dirname "$(dirname "$file")")
        HTML_FILE="$FORM_DIR/index.html"
        
        if [ -f "$HTML_FILE" ]; then
            echo -e "  ${BLUE}Found HTML file: $HTML_FILE${NC}"
            
            # Add debugger script if not already added
            if ! grep -q "hsq-forms-debugger.js" "$HTML_FILE"; then
                echo -e "  ${BLUE}Adding debugger script to $HTML_FILE${NC}"
                
                # Find the closing head tag and add the script before it
                sed -i "s|</head>|    <script src=\"/scripts/hsq-forms-debugger.js\"></script>\n</head>|g" "$HTML_FILE"
                echo -e "  ${GREEN}Added debugger script to $HTML_FILE${NC}"
            else
                echo -e "  ${YELLOW}Debugger script already added to $HTML_FILE${NC}"
            fi
        fi
    fi
done

# Create an environment file for forms to use
echo -e "\n${BLUE}Creating environment files with Front Door URL${NC}"

for form_dir in $(find $FORMS_DIR -type d -name "hsq-forms-container-*"); do
    ENV_FILE="$form_dir/.env"
    ENV_LOCAL_FILE="$form_dir/.env.local"
    
    echo -e "${YELLOW}Creating environment file: $ENV_FILE${NC}"
    echo "VITE_API_BASE_URL=https://$FRONTDOOR_URL" > "$ENV_FILE"
    
    echo -e "${YELLOW}Creating local environment file: $ENV_LOCAL_FILE${NC}"
    echo "VITE_API_BASE_URL=https://$FRONTDOOR_URL" > "$ENV_LOCAL_FILE"
    
    echo -e "${GREEN}Created environment files for $(basename "$form_dir")${NC}"
done

echo -e "\n${BLUE}==== Forms Update Complete ====${NC}"
echo -e "${YELLOW}Don't forget to commit and push your changes!${NC}"
