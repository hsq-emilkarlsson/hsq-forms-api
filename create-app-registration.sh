#!/bin/bash

# Script för att skapa ny App Registration för GitHub Actions OIDC
# Kör detta script om din App Registration saknas

echo "Skapar ny App Registration för GitHub Actions OIDC..."

# Skapa App Registration
APP_REGISTRATION=$(az ad app create \
  --display-name "hsq-forms-github-actions" \
  --query "appId" \
  --output tsv)

echo "App Registration skapad med Client ID: $APP_REGISTRATION"

# Hämta Object ID för App Registration
OBJECT_ID=$(az ad app show --id $APP_REGISTRATION --query "id" --output tsv)

echo "Object ID: $OBJECT_ID"

# Skapa Service Principal
SERVICE_PRINCIPAL=$(az ad sp create --id $APP_REGISTRATION --query "appId" --output tsv)

echo "Service Principal skapad: $SERVICE_PRINCIPAL"

# Vänta lite för att Azure ska synkronisera
echo "Väntar på Azure synkronisering..."
sleep 10

# Skapa federated credentials för develop branch
echo "Skapar federated credential för develop branch..."
az ad app federated-credential create \
  --id $APP_REGISTRATION \
  --parameters '{
    "name": "github-actions-develop",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:hsq-emilkarlsson/hsq-forms-api:ref:refs/heads/develop",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Skapa federated credentials för main branch
echo "Skapar federated credential för main branch..."
az ad app federated-credential create \
  --id $APP_REGISTRATION \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:hsq-emilkarlsson/hsq-forms-api:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Skapa federated credentials för tags
echo "Skapar federated credential för tags..."
az ad app federated-credential create \
  --id $APP_REGISTRATION \
  --parameters '{
    "name": "github-actions-tags",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:hsq-emilkarlsson/hsq-forms-api:ref:refs/tags/*",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Hämta Tenant ID
TENANT_ID=$(az account show --query "tenantId" --output tsv)

echo ""
echo "=== RESULTAT ==="
echo "App Registration skapad framgångsrikt!"
echo ""
echo "Använd följande värden i GitHub Secrets:"
echo "AZURE_CLIENT_ID: $APP_REGISTRATION"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo ""
echo "Nästa steg:"
echo "1. Tilldela RBAC-roller till Service Principal"
echo "2. Uppdatera GitHub Secrets"
echo "3. Testa deployment"
