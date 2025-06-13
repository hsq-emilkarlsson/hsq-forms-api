#!/bin/bash

# Simple HSQ Forms API Deployment Script
# För snabb backend-uppdatering till Azure Container Apps

set -e  # Exit on any error

echo "🚀 Deploying HSQ Forms API..."

# Azure resurser (anpassa dessa om du har andra namn)
RESOURCE_GROUP="rg-hsq-forms-prod"
ACR_NAME="hsqformsprodacr"
APP_NAME="hsq-forms-api"

# Färgkoder för output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Kontrollera att vi är inloggade på Azure
if ! az account show &>/dev/null; then
    print_step "Logga in på Azure"
    az login
fi

print_step "1. Logga in på Container Registry"
az acr login --name $ACR_NAME

print_step "2. Bygg och pusha Docker image"
docker build -t $ACR_NAME.azurecr.io/$APP_NAME:latest .
docker push $ACR_NAME.azurecr.io/$APP_NAME:latest

print_step "3. Uppdatera Container App"
az containerapp update \
  --name $APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --image $ACR_NAME.azurecr.io/$APP_NAME:latest

# Hämta API URL
API_URL=$(az containerapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn --output tsv)

echo ""
print_success "Backend API uppdaterad!"
echo ""
echo "🌐 API URL: https://$API_URL"
echo "🔧 Testa API: https://$API_URL/docs"
echo "🧪 Kör verifiering: python test_azure_deployment.py --api-url https://$API_URL"
echo ""
echo "💡 Tips: Kör 'az containerapp logs show --name $APP_NAME --resource-group $RESOURCE_GROUP --follow' för att se logs"
