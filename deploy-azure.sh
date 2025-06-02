#!/bin/bash

# Deploy HSQ Forms Platform to Azure Container Apps
# Kör detta skript för att deploya hela plattformen till Azure

set -e  # Exit on any error

echo "🚀 Starting deployment of HSQ Forms Platform to Azure..."

# Färgkoder för output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funktion för färgad output
print_step() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Kontrollera att Azure CLI är installerat
if ! command -v az &> /dev/null; then
    print_error "Azure CLI är inte installerat. Installera med: brew install azure-cli"
    exit 1
fi

# Kontrollera att Docker är installerat
if ! command -v docker &> /dev/null; then
    print_error "Docker är inte installerat. Installera Docker Desktop."
    exit 1
fi

# Sätt variabler för bra Azure-struktur
RESOURCE_GROUP="rg-hsq-forms-prod-westeu"
LOCATION="westeurope"
ENVIRONMENT="hsq-forms-prod-env"
WORKSPACE="hsq-forms-logs-workspace"
ACR_NAME="hsqformsprodacr$(date +%s)"  # Lägg till timestamp för unikhet
DB_SERVER="hsq-forms-prod-db-$(date +%s)"
DB_NAME="formdb"
DB_USER="formuser"

# Generera säkert lösenord
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

print_step "1. Logga in på Azure"
az login

print_step "2. Skapa Resource Group med taggar"
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags \
    project="HSQ-Forms-Platform" \
    environment="production" \
    owner="Emil-Karlsson" \
    created="$(date +%Y-%m-%d)" \
    purpose="Forms-and-API-Platform"
print_success "Resource Group skapad: $RESOURCE_GROUP"

print_step "3. Skapa Log Analytics Workspace"
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE \
  --location $LOCATION

WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE \
  --query customerId --output tsv)

WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE \
  --query primarySharedKey --output tsv)

print_success "Log Analytics Workspace skapad"

print_step "4. Skapa Container Apps Environment"
az containerapp env create \
  --name $ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --logs-workspace-id $WORKSPACE_ID \
  --logs-workspace-key $WORKSPACE_KEY

print_success "Container Apps Environment skapad"

print_step "5. Skapa Azure Container Registry"
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic
az acr login --name $ACR_NAME
print_success "Container Registry skapad: $ACR_NAME"

print_step "6. Skapa PostgreSQL Database"
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_SERVER \
  --location $LOCATION \
  --admin-user $DB_USER \
  --admin-password $DB_PASSWORD \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 15 \
  --storage-size 32 \
  --public-access 0.0.0.0

az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $DB_SERVER \
  --database-name $DB_NAME

DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@$DB_SERVER.postgres.database.azure.com:5432/$DB_NAME"
print_success "PostgreSQL Database skapad"

print_step "7. Bygg och pusha Backend API"
cd apps/app
docker build -t $ACR_NAME.azurecr.io/hsq-forms-api:latest .
docker push $ACR_NAME.azurecr.io/hsq-forms-api:latest
cd ../..
print_success "Backend API pushad till registry"

print_step "8. Deploy Backend API"
az containerapp create \
  --name hsq-forms-api \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $ACR_NAME.azurecr.io/hsq-forms-api:latest \
  --target-port 8000 \
  --ingress external \
  --registry-server $ACR_NAME.azurecr.io \
  --env-vars DATABASE_URL="$DATABASE_URL" \
             ENVIRONMENT="production" \
  --min-replicas 1 \
  --max-replicas 3 \
  --cpu 0.5 \
  --memory 1Gi

API_URL=$(az containerapp show --name hsq-forms-api --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn --output tsv)
print_success "Backend API deployad: https://$API_URL"

print_step "9. Bygg och pusha Contact Form"
cd apps/form-contact
docker build -f Dockerfile.prod -t $ACR_NAME.azurecr.io/hsq-contact-form:latest .
docker push $ACR_NAME.azurecr.io/hsq-contact-form:latest
cd ../..
print_success "Contact Form pushad till registry"

print_step "10. Deploy Contact Form"
az containerapp create \
  --name hsq-contact-form \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $ACR_NAME.azurecr.io/hsq-contact-form:latest \
  --target-port 80 \
  --ingress external \
  --registry-server $ACR_NAME.azurecr.io \
  --min-replicas 1 \
  --max-replicas 2 \
  --cpu 0.25 \
  --memory 0.5Gi

CONTACT_URL=$(az containerapp show --name hsq-contact-form --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn --output tsv)
print_success "Contact Form deployad: https://$CONTACT_URL"

print_step "11. Bygg och pusha Support Form"
cd apps/form-support
docker build -f Dockerfile.prod -t $ACR_NAME.azurecr.io/hsq-support-form:latest .
docker push $ACR_NAME.azurecr.io/hsq-support-form:latest
cd ../..
print_success "Support Form pushad till registry"

print_step "12. Deploy Support Form"
az containerapp create \
  --name hsq-support-form \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image $ACR_NAME.azurecr.io/hsq-support-form:latest \
  --target-port 80 \
  --ingress external \
  --registry-server $ACR_NAME.azurecr.io \
  --min-replicas 1 \
  --max-replicas 2 \
  --cpu 0.25 \
  --memory 0.5Gi

SUPPORT_URL=$(az containerapp show --name hsq-support-form --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn --output tsv)
print_success "Support Form deployad: https://$SUPPORT_URL"

print_step "13. Uppdatera CORS-inställningar"
az containerapp update \
  --name hsq-forms-api \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars ALLOWED_ORIGINS="https://$CONTACT_URL,https://$SUPPORT_URL"

print_success "CORS-inställningar uppdaterade"

print_step "14. Kör databas-migreringar"
# Här skulle vi köra Alembic-migreringar, men vi hoppar över det för nu
print_warning "Kom ihåg att köra databas-migreringar manuellt"

echo ""
echo "🎉 Deployment slutförd!"
echo ""
echo "📋 Deployment-sammanfattning:"
echo "=========================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Database Server: $DB_SERVER"
echo "Database Password: $DB_PASSWORD"
echo ""
echo "🌐 URL:er:"
echo "API: https://$API_URL"
echo "Contact Form: https://$CONTACT_URL"
echo "Support Form: https://$SUPPORT_URL"
echo ""
echo "💰 Uppskattad kostnad: ~1000-1500 SEK/månad"
echo ""
echo "🔧 Nästa steg:"
echo "1. Kör databas-migreringar"
echo "2. Testa alla formulär"
echo "3. Konfigurera custom domains (valfritt)"
echo "4. Sätt upp monitoring och alerts"

# Spara konfiguration till fil
cat > deployment-info.txt << EOF
HSQ Forms Platform Deployment Information
========================================
Deployment Date: $(date)
Resource Group: $RESOURCE_GROUP
Location: $LOCATION

Database:
---------
Server: $DB_SERVER
Database: $DB_NAME
User: $DB_USER
Password: $DB_PASSWORD
Connection String: $DATABASE_URL

Container Registry:
------------------
Name: $ACR_NAME
Server: $ACR_NAME.azurecr.io

URLs:
-----
API: https://$API_URL
Contact Form: https://$CONTACT_URL
Support Form: https://$SUPPORT_URL

Cleanup Command:
---------------
az group delete --name $RESOURCE_GROUP --yes --no-wait
EOF

print_success "Deployment-information sparad i deployment-info.txt"
