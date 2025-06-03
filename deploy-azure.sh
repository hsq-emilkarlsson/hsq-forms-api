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
# Sätt fasta namn på resurser (ingen timestamp)
ACR_NAME="hsqformsprodacr"
DB_SERVER="hsq-forms-prod-db"
DB_NAME="formdb"
DB_USER="formuser"

# Generera säkert lösenord
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

print_step "1. Logga in på Azure"
az login

# Skapa Resource Group om den inte finns
if ! az group show --name $RESOURCE_GROUP &>/dev/null; then
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
else
  print_success "Resource Group finns redan: $RESOURCE_GROUP"
fi

# Skapa Log Analytics Workspace om den inte finns
if ! az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP --workspace-name $WORKSPACE &>/dev/null; then
  print_step "3. Skapa Log Analytics Workspace"
  az monitor log-analytics workspace create \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $WORKSPACE \
    --location $LOCATION
  print_success "Log Analytics Workspace skapad"
else
  print_success "Log Analytics Workspace finns redan: $WORKSPACE"
fi

WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE \
  --query customerId --output tsv)

WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE \
  --query primarySharedKey --output tsv)

# Skapa Container Apps Environment om den inte finns
if ! az containerapp env show --name $ENVIRONMENT --resource-group $RESOURCE_GROUP &>/dev/null; then
  print_step "4. Skapa Container Apps Environment"
  az containerapp env create \
    --name $ENVIRONMENT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --logs-workspace-id $WORKSPACE_ID \
    --logs-workspace-key $WORKSPACE_KEY
  print_success "Container Apps Environment skapad"
else
  print_success "Container Apps Environment finns redan: $ENVIRONMENT"
fi

# Skapa Azure Container Registry om den inte finns
if ! az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP &>/dev/null; then
  print_step "5. Skapa Azure Container Registry"
  az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic
  az acr login --name $ACR_NAME
  print_success "Container Registry skapad: $ACR_NAME"
else
  print_success "Container Registry finns redan: $ACR_NAME"
fi

# Skapa PostgreSQL Database Server om den inte finns
if ! az postgres flexible-server show --resource-group $RESOURCE_GROUP --name $DB_SERVER &>/dev/null; then
  print_step "6. Skapa PostgreSQL Database Server"
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
  print_success "PostgreSQL Database Server skapad: $DB_SERVER"
else
  print_success "PostgreSQL Database Server finns redan: $DB_SERVER"
fi

# Skapa databas om den inte finns
if ! az postgres flexible-server db show --resource-group $RESOURCE_GROUP --server-name $DB_SERVER --database-name $DB_NAME &>/dev/null; then
  az postgres flexible-server db create \
    --resource-group $RESOURCE_GROUP \
    --server-name $DB_SERVER \
    --database-name $DB_NAME
  print_success "PostgreSQL Database skapad: $DB_NAME"
else
  print_success "PostgreSQL Database finns redan: $DB_NAME"
fi

DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@$DB_SERVER.postgres.database.azure.com:5432/$DB_NAME"

# Spara DB credentials till .azure-secrets.env (skapas/uppdateras, git-ignorera denna fil!)
cat > .azure-secrets.env << EOF
# Azure PostgreSQL credentials (auto-generated)
DB_SERVER=$DB_SERVER
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DATABASE_URL=$DATABASE_URL
EOF
print_success ".azure-secrets.env skapad/uppdaterad med DB credentials (lägg till i .gitignore om ej redan)"

# Bygg och pusha Backend API
print_step "7. Bygg och pusha Backend API"
cd apps/app
docker build -t $ACR_NAME.azurecr.io/hsq-forms-api:latest .
docker push $ACR_NAME.azurecr.io/hsq-forms-api:latest
cd ../..
print_success "Backend API pushad till registry"

# Deploy Backend API: använd az containerapp create/update beroende på om den finns
if az containerapp show --name hsq-forms-api --resource-group $RESOURCE_GROUP &>/dev/null; then
  print_step "8. Uppdaterar Backend API (containerapp update)"
  az containerapp update \
    --name hsq-forms-api \
    --resource-group $RESOURCE_GROUP \
    --image $ACR_NAME.azurecr.io/hsq-forms-api:latest \
    --set-env-vars DATABASE_URL="$DATABASE_URL" ENVIRONMENT="production"
  print_success "Backend API uppdaterad"
else
  print_step "8. Deploy Backend API (containerapp create)"
  az containerapp create \
    --name hsq-forms-api \
    --resource-group $RESOURCE_GROUP \
    --environment $ENVIRONMENT \
    --image $ACR_NAME.azurecr.io/hsq-forms-api:latest \
    --target-port 8000 \
    --ingress external \
    --registry-server $ACR_NAME.azurecr.io \
    --env-vars DATABASE_URL="$DATABASE_URL" ENVIRONMENT="production" \
    --min-replicas 1 \
    --max-replicas 3 \
    --cpu 0.5 \
    --memory 1Gi
  print_success "Backend API deployad"
fi

API_URL=$(az containerapp show --name hsq-forms-api --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn --output tsv)

print_step "9. Bygg och pusha Feedback Form"
print_warning "Feedback Form deployas nu via Azure Static Web Apps (SWA) och GitHub Actions. Ingen container-deployment längre."

print_step "10. Bygg och pusha Support Form"
print_warning "Support Form deployas nu via Azure Static Web Apps (SWA) och GitHub Actions. Ingen container-deployment längre."

# Ta bort containerapp deployment för feedback och support-formulär
# print_step "10. Deploy Feedback Form"
# az containerapp create ...
# print_step "12. Deploy Support Form"
# az containerapp create ...

# Ange SWA-URL:er manuellt eller via env om du vill använda dem i CORS
SWA_FEEDBACK_URL="https://icy-flower-030d4ac03.6.azurestaticapps.net"
SWA_SUPPORT_URL="https://din-support-swa-url.azurestaticapps.net"

print_step "13. Uppdatera CORS-inställningar"
az containerapp update \
  --name hsq-forms-api \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars ALLOWED_ORIGINS="$SWA_FEEDBACK_URL,$SWA_SUPPORT_URL"

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
echo "Feedback Form: https://$SWA_FEEDBACK_URL"
echo "Support Form: https://$SWA_SUPPORT_URL"
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
Feedback Form: https://$SWA_FEEDBACK_URL
Support Form: https://$SWA_SUPPORT_URL

Cleanup Command:
---------------
az group delete --name $RESOURCE_GROUP --yes --no-wait
EOF

print_success "Deployment-information sparad i deployment-info.txt"
