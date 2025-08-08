#!/bin/bash
# Script to test deploying a specific infrastructure approach

# Set default values
APPROACH="01-default"
ENVIRONMENT="dev"
RESOURCE_GROUP="rg-hsq-forms-dev"
LOCATION="westeurope"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -a|--approach)
      APPROACH="$2"
      shift
      shift
      ;;
    -e|--environment)
      ENVIRONMENT="$2"
      shift
      shift
      ;;
    -g|--resource-group)
      RESOURCE_GROUP="$2"
      shift
      shift
      ;;
    -l|--location)
      LOCATION="$2"
      shift
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -a, --approach APPROACH    Infrastructure approach to deploy (default: 01-default)"
      echo "  -e, --environment ENV      Environment to deploy to (default: dev)"
      echo "  -g, --resource-group RG    Resource group name (default: rg-hsq-forms-dev)"
      echo "  -l, --location LOCATION    Azure region (default: westeurope)"
      echo "Available approaches:"
      echo "  01-default     - Default approach with Container Apps"
      echo "  02-minimal     - Minimal deployment approach"
      echo "  03-no-vnet     - Deployment without VNet integration"
      echo "  04-minimal-vnet - Minimal deployment with VNet"
      echo "  05-secure      - Secure deployment with enhanced security"
      echo "  06-avm         - Azure Verified Modules approach"
      echo "  07-ready       - Production-ready approach with VNet"
      echo "  08-appservice  - App Service alternative approach"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help to see available options"
      exit 1
      ;;
  esac
done

# Map approach number to actual file name prefix
case $APPROACH in
  01-default)
    BICEP_FILE="main"
    ;;
  02-minimal)
    BICEP_FILE="main-minimal"
    ;;
  03-no-vnet)
    BICEP_FILE="main-no-vnet"
    ;;
  04-minimal-vnet)
    BICEP_FILE="main-minimal-vnet"
    ;;
  05-secure)
    BICEP_FILE="main-secure"
    ;;
  06-avm)
    BICEP_FILE="main-avm"
    ;;
  07-ready)
    BICEP_FILE="main-ready"
    ;;
  08-appservice)
    BICEP_FILE="main-appservice"
    ;;
  *)
    echo "Invalid approach: $APPROACH"
    echo "Use --help to see available options"
    exit 1
    ;;
esac

# Prompt for database admin password (never store in scripts)
read -sp "Enter database admin password: " DB_PASSWORD
echo ""

# Confirm deployment
echo "=============================================="
echo "DEPLOYMENT SUMMARY"
echo "=============================================="
echo "Approach:        $APPROACH"
echo "Bicep file:      $BICEP_FILE.bicep"
echo "Environment:     $ENVIRONMENT"
echo "Resource Group:  $RESOURCE_GROUP"
echo "Location:        $LOCATION"
echo "=============================================="
read -p "Continue with deployment? (y/n): " CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
  echo "Deployment cancelled"
  exit 0
fi

# Check if resource group exists, create if not
echo "Checking if resource group exists..."
if ! az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echo "Creating resource group $RESOURCE_GROUP in $LOCATION..."
  az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
fi

# Deploy the infrastructure
echo "Deploying infrastructure using approach $APPROACH..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "infra/approaches/$APPROACH/$BICEP_FILE.bicep" \
  --parameters @"infra/approaches/$APPROACH/$BICEP_FILE.parameters.$ENVIRONMENT.json" \
  --parameters dbAdminPassword="$DB_PASSWORD"

# Check deployment status
if [ $? -eq 0 ]; then
  echo "Deployment completed successfully!"
else
  echo "Deployment failed!"
  exit 1
fi
