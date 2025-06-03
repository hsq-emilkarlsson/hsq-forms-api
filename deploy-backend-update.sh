#!/bin/bash

# Uppdatera endast backend-kod och containerapp, skapa INTE nya resurser!
# Kör detta script när du gjort kodändringar och vill deploya backend-API till Azure.

set -e

# Variabler (uppdatera om du byter namn på resurser)
RESOURCE_GROUP="rg-hsq-forms-prod-westeu"
ACR_NAME="hsqformsprodacr"
CONTAINERAPP_NAME="hsq-forms-api"

# Bygg och pusha backend-container
cd apps/app
az acr login --name $ACR_NAME

docker build -t $ACR_NAME.azurecr.io/hsq-forms-api:latest .
docker push $ACR_NAME.azurecr.io/hsq-forms-api:latest
cd ../..

echo "✅ Backend container pushad till $ACR_NAME.azurecr.io/hsq-forms-api:latest"

# Uppdatera containerapp med senaste image (och ev. miljövariabler)
az containerapp update \
  --name $CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --image $ACR_NAME.azurecr.io/hsq-forms-api:latest

echo "✅ Backend API uppdaterad och redeployad!"
