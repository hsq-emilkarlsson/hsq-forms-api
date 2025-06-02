# Azure Container Apps Deployment Guide

## Förutsättningar

1. **Azure CLI installerat**
   ```bash
   brew install azure-cli
   az login
   ```

2. **Container Apps Extension**
   ```bash
   az extension add --name containerapp --upgrade
   ```

3. **Resource Group och Environment**
   ```bash
   # Sätt variabler
   export RESOURCE_GROUP="hsq-forms-rg"
   export LOCATION="swedencentral"
   export ENVIRONMENT="hsq-forms-env"
   export WORKSPACE="hsq-forms-workspace"
   
   # Skapa resource group
   az group create --name $RESOURCE_GROUP --location $LOCATION
   
   # Skapa Log Analytics workspace
   az monitor log-analytics workspace create \
     --resource-group $RESOURCE_GROUP \
     --workspace-name $WORKSPACE \
     --location $LOCATION
   
   # Hämta workspace ID och key
   export WORKSPACE_ID=$(az monitor log-analytics workspace show \
     --resource-group $RESOURCE_GROUP \
     --workspace-name $WORKSPACE \
     --query customerId --output tsv)
   
   export WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
     --resource-group $RESOURCE_GROUP \
     --workspace-name $WORKSPACE \
     --query primarySharedKey --output tsv)
   
   # Skapa Container Apps Environment
   az containerapp env create \
     --name $ENVIRONMENT \
     --resource-group $RESOURCE_GROUP \
     --location $LOCATION \
     --logs-workspace-id $WORKSPACE_ID \
     --logs-workspace-key $WORKSPACE_KEY
   ```

## PostgreSQL Database

1. **Skapa Azure Database for PostgreSQL**
   ```bash
   export DB_SERVER="hsq-forms-db"
   export DB_NAME="formdb"
   export DB_USER="formuser"
   export DB_PASSWORD="SecurePassword123!"
   
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
   
   # Skapa databas
   az postgres flexible-server db create \
     --resource-group $RESOURCE_GROUP \
     --server-name $DB_SERVER \
     --database-name $DB_NAME
   
   # Hämta connection string
   export DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@$DB_SERVER.postgres.database.azure.com:5432/$DB_NAME"
   ```

## Deploy Backend API

1. **Bygg och pusha backend-image**
   ```bash
   # Logga in på Azure Container Registry (eller använd Docker Hub)
   export ACR_NAME="hsqformsacr"
   az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic
   az acr login --name $ACR_NAME
   
   # Bygg och pusha API-image
   cd apps/app
   docker build -t $ACR_NAME.azurecr.io/hsq-forms-api:latest .
   docker push $ACR_NAME.azurecr.io/hsq-forms-api:latest
   ```

2. **Deploy API Container App**
   ```bash
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
               ALLOWED_ORIGINS="https://hsq-contact-form.proudhill-12345678.swedencentral.azurecontainerapps.io,https://hsq-support-form.proudhill-12345678.swedencentral.azurecontainerapps.io" \
     --min-replicas 1 \
     --max-replicas 3 \
     --cpu 0.5 \
     --memory 1Gi
   ```

## Deploy Frontend Applications

1. **Contact Form**
   ```bash
   cd ../form-contact
   docker build -t $ACR_NAME.azurecr.io/hsq-contact-form:latest .
   docker push $ACR_NAME.azurecr.io/hsq-contact-form:latest
   
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
   ```

2. **Support Form**
   ```bash
   cd ../form-support
   docker build -t $ACR_NAME.azurecr.io/hsq-support-form:latest .
   docker push $ACR_NAME.azurecr.io/hsq-support-form:latest
   
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
   ```

## Uppdatera CORS efter deployment

Efter att alla apps är deployade, uppdatera API:et med de riktiga URL:erna:

```bash
# Hämta URL:er för frontend-appar
export CONTACT_URL=$(az containerapp show --name hsq-contact-form --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn --output tsv)
export SUPPORT_URL=$(az containerapp show --name hsq-support-form --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn --output tsv)

# Uppdatera API med nya CORS-inställningar
az containerapp update \
  --name hsq-forms-api \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars ALLOWED_ORIGINS="https://$CONTACT_URL,https://$SUPPORT_URL"
```

## Produktions-URL:er

Efter deployment kommer du att ha:
- **API**: `https://hsq-forms-api.proudhill-12345678.swedencentral.azurecontainerapps.io`
- **Contact Form**: `https://hsq-contact-form.proudhill-12345678.swedencentral.azurecontainerapps.io`
- **Support Form**: `https://hsq-support-form.proudhill-12345678.swedencentral.azurecontainerapps.io`

## Monitoring och Logs

```bash
# Visa logs för API
az containerapp logs show --name hsq-forms-api --resource-group $RESOURCE_GROUP --follow

# Visa metrics
az monitor metrics list --resource /subscriptions/<subscription-id>/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/hsq-forms-api
```

## Kostnadskontroll

- **API**: ~200-400 SEK/månad (beroende på trafik)
- **Frontend apps**: ~100-200 SEK/månad vardera
- **PostgreSQL**: ~500-800 SEK/månad
- **Log Analytics**: ~50-100 SEK/månad

**Total uppskattad kostnad**: ~1000-1700 SEK/månad för full produktion.
