#!/bin/bash
# deploy-infra.sh - Script för att testa olika Bicep-approaches direkt från terminalen
# Använd: ./deploy-infra.sh <approach-nummer> [dev|prod]

# Färger för output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default-värden
APPROACH="01-default"
ENVIRONMENT="dev"
RESOURCE_GROUP="rg-hsq-forms-dev"
LOCATION="westeurope"

# Hantera argument
if [ $# -ge 1 ]; then
  APPROACH=$1
fi

if [ $# -ge 2 ]; then
  ENVIRONMENT=$2
  if [ "$ENVIRONMENT" == "prod" ]; then
    RESOURCE_GROUP="rg-hsq-forms-prod"
  fi
fi

# Validera approach
if [[ ! "$APPROACH" =~ ^(0[1-8]-[a-z-]+)$ ]]; then
  echo -e "${RED}Felaktigt approach-format. Använd formatet '01-default', '02-minimal', etc.${NC}"
  echo -e "${YELLOW}Tillgängliga approaches:${NC}"
  ls -1 infra/approaches/
  exit 1
fi

# Hitta Bicep-fil och parameterfil
APPROACH_DIR="infra/approaches/$APPROACH"
if [ ! -d "$APPROACH_DIR" ]; then
  echo -e "${RED}Kunde inte hitta approach: $APPROACH_DIR${NC}"
  echo -e "${YELLOW}Tillgängliga approaches:${NC}"
  ls -1 infra/approaches/
  exit 1
fi

# Hitta Bicep-fil
BICEP_FILE=$(find $APPROACH_DIR -name "*.bicep" | head -n 1)
if [ -z "$BICEP_FILE" ]; then
  echo -e "${RED}Kunde inte hitta någon Bicep-fil i $APPROACH_DIR${NC}"
  exit 1
fi

# Hitta parameterfil
PARAMS_FILE=$(find $APPROACH_DIR -name "*parameters.$ENVIRONMENT.json" | head -n 1)
if [ -z "$PARAMS_FILE" ]; then
  echo -e "${YELLOW}Varning: Kunde inte hitta specifik parameterfil för miljö '$ENVIRONMENT', använder standardfil${NC}"
  PARAMS_FILE=$(find $APPROACH_DIR -name "*parameters*.json" | head -n 1)
  
  if [ -z "$PARAMS_FILE" ]; then
    echo -e "${RED}Kunde inte hitta någon parameterfil i $APPROACH_DIR${NC}"
    exit 1
  fi
fi

# Visa information
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}HSQ Forms API - Infrastruktur Deployment${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "${YELLOW}Approach:${NC} $APPROACH"
echo -e "${YELLOW}Environment:${NC} $ENVIRONMENT"
echo -e "${YELLOW}Resource Group:${NC} $RESOURCE_GROUP"
echo -e "${YELLOW}Location:${NC} $LOCATION"
echo -e "${YELLOW}Bicep File:${NC} $BICEP_FILE"
echo -e "${YELLOW}Parameters File:${NC} $PARAMS_FILE"
echo -e "${BLUE}============================================${NC}"

# Fråga efter lösenord om det behövs
read -sp "Ange databas admin lösenord (eller tryck Enter för att använda 'TemporaryDevPassword123!'): " DB_PASSWORD
echo ""
if [ -z "$DB_PASSWORD" ]; then
  DB_PASSWORD="TemporaryDevPassword123!"
  echo -e "${YELLOW}Använder default lösenord för utveckling. ANVÄND INTE I PRODUKTION!${NC}"
fi

# Skapa resursgrupp om den inte finns
echo -e "${BLUE}Kontrollerar/skapar resursgrupp...${NC}"
az group create --name $RESOURCE_GROUP --location $LOCATION

# Validera mallen först
echo -e "${BLUE}Validerar Bicep-mall...${NC}"
az deployment group validate \
  --resource-group $RESOURCE_GROUP \
  --template-file "$BICEP_FILE" \
  --parameters @"$PARAMS_FILE" \
  --parameters dbAdminPassword="$DB_PASSWORD"

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Validering misslyckades! Se felmeddelanden ovan.${NC}"
  exit 1
fi

# Förhandsgranska ändringar (What-if)
echo -e "${BLUE}Förhandsgranskar ändringar (What-if)...${NC}"
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file "$BICEP_FILE" \
  --parameters @"$PARAMS_FILE" \
  --parameters dbAdminPassword="$DB_PASSWORD"

# Fråga om fortsättning
read -p "Vill du fortsätta med deployment? (y/n): " CONTINUE
if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Deployment avbruten.${NC}"
  exit 0
fi

# Starta deployment
echo -e "${BLUE}Startar deployment...${NC}"
DEPLOYMENT_NAME="hsq-forms-$APPROACH-$(date +%Y%m%d%H%M%S)"

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file "$BICEP_FILE" \
  --parameters @"$PARAMS_FILE" \
  --parameters dbAdminPassword="$DB_PASSWORD" \
  --name $DEPLOYMENT_NAME

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Deployment slutförd!${NC}"
  
  # Visa outputs
  echo -e "${BLUE}Deployment outputs:${NC}"
  az deployment group show \
    --resource-group $RESOURCE_GROUP \
    --name $DEPLOYMENT_NAME \
    --query properties.outputs \
    --output json
    
  # Lista resurser
  echo -e "${BLUE}Deployade resurser:${NC}"
  az resource list --resource-group $RESOURCE_GROUP --output table
else
  echo -e "${RED}❌ Deployment misslyckades! Se felmeddelanden ovan.${NC}"
  exit 1
fi
