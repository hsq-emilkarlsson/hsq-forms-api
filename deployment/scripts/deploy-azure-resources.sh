#!/bin/bash
# HSQ Forms API - Azure Resource Deployment Script
# Skapar alla Azure-resurser för specificerad miljö

set -e

# Färger för output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
ENVIRONMENT=${1:-dev}
SKIP_ACR=${2:-false}

if [[ ! -f "deployment/environments/${ENVIRONMENT}.yml" ]]; then
    print_error "Environment file not found: deployment/environments/${ENVIRONMENT}.yml"
    exit 1
fi

print_status "🚀 Deploying HSQ Forms API to ${ENVIRONMENT} environment"

# Load environment configuration (simplified YAML parsing)
SUBSCRIPTION=$(grep "subscription:" deployment/environments/${ENVIRONMENT}.yml | cut -d' ' -f4)
RESOURCE_GROUP=$(grep "resourceGroup:" deployment/environments/${ENVIRONMENT}.yml | cut -d' ' -f4)
CONTAINER_REGISTRY=$(grep "containerRegistry:" deployment/environments/${ENVIRONMENT}.yml | cut -d' ' -f4)
CONTAINER_APP_ENV=$(grep "containerAppEnvironment:" deployment/environments/${ENVIRONMENT}.yml | cut -d' ' -f4)
CONTAINER_APP=$(grep "containerApp:" deployment/environments/${ENVIRONMENT}.yml | cut -d' ' -f4)

print_status "Configuration loaded:"
echo "  Subscription: $SUBSCRIPTION"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Container Registry: $CONTAINER_REGISTRY"
echo "  Container App: $CONTAINER_APP"

# Set Azure subscription
print_status "Setting Azure subscription..."
az account set --subscription "$SUBSCRIPTION"

# Create Resource Group
print_status "Creating Resource Group..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "westeurope" \
    --tags environment="$ENVIRONMENT" project="hsq-forms-api"

print_success "Resource Group created: $RESOURCE_GROUP"

# Create Container Registry
if [[ "$SKIP_ACR" != "true" ]]; then
    print_status "Creating Container Registry..."
    az acr create \
        --name "$CONTAINER_REGISTRY" \
        --resource-group "$RESOURCE_GROUP" \
        --location "westeurope" \
        --sku "Basic" \
        --admin-enabled true \
        --tags environment="$ENVIRONMENT" project="hsq-forms-api"

    print_success "Container Registry created: $CONTAINER_REGISTRY"
else
    print_warning "Skipping ACR creation (already exists)"
fi

# Create Container Apps Environment
print_status "Creating Container Apps Environment..."
az containerapp env create \
    --name "$CONTAINER_APP_ENV" \
    --resource-group "$RESOURCE_GROUP" \
    --location "westeurope" \
    --tags environment="$ENVIRONMENT" project="hsq-forms-api"

print_success "Container Apps Environment created: $CONTAINER_APP_ENV"

# Create Container App (placeholder)
print_status "Creating Container App..."
az containerapp create \
    --name "$CONTAINER_APP" \
    --resource-group "$RESOURCE_GROUP" \
    --environment "$CONTAINER_APP_ENV" \
    --image "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" \
    --target-port 80 \
    --ingress 'external' \
    --min-replicas 1 \
    --max-replicas $([ "$ENVIRONMENT" = "prod" ] && echo "10" || echo "3") \
    --cpu $([ "$ENVIRONMENT" = "prod" ] && echo "1.0" || echo "0.5") \
    --memory $([ "$ENVIRONMENT" = "prod" ] && echo "2.0Gi" || echo "1.0Gi") \
    --tags environment="$ENVIRONMENT" project="hsq-forms-api"

print_success "Container App created: $CONTAINER_APP"

# Get ACR credentials for Azure DevOps
print_status "Getting ACR credentials..."
ACR_USERNAME=$(az acr credential show --name "$CONTAINER_REGISTRY" --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name "$CONTAINER_REGISTRY" --query "passwords[0].value" -o tsv)

print_success "🎉 Deployment completed successfully!"
echo ""
print_status "📋 Next steps:"
echo "1. Add ACR credentials to Azure DevOps variables:"
echo "   - ACR_USERNAME_$(echo $ENVIRONMENT | tr '[:lower:]' '[:upper:]'): $ACR_USERNAME"
echo "   - ACR_PASSWORD_$(echo $ENVIRONMENT | tr '[:lower:]' '[:upper:]'): $ACR_PASSWORD"
echo ""
echo "2. Update pipeline to use these resources"
echo "3. Run pipeline to deploy application"

# Output resource URLs
echo ""
print_status "🔗 Resource URLs:"
echo "  - Resource Group: https://portal.azure.com/#@husqvarnagroup.onmicrosoft.com/resource/subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP"
echo "  - Container Registry: https://portal.azure.com/#@husqvarnagroup.onmicrosoft.com/resource/subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerRegistry/registries/$CONTAINER_REGISTRY"
echo "  - Container App: https://portal.azure.com/#@husqvarnagroup.onmicrosoft.com/resource/subscriptions/$SUBSCRIPTION/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/$CONTAINER_APP"
