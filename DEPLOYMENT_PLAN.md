# 📋 HSQ Forms API - Infrastructure & Deployment Plan

## 🎯 Overview
Complete infrastructure setup och deployment plan för HSQ Forms API med automatiserad CI/CD genom Azure DevOps.

## 🏗️ Infrastructure Architecture

### Azure Resources per Environment

**DEV Environment (HAZE-01AA-APP1066-Dev-Martechlab)**
- **Subscription ID**: `c0b03b12-570f-4442-b337-c9175ad4037f`
- **Resource Group**: `rg-hsq-forms-dev`
- **Container Registry**: `hsqformsdevacr.azurecr.io`
- **Container App Environment**: Auto-generated name via Bicep
- **PostgreSQL Server**: Auto-generated name via Bicep
- **Storage Account**: Auto-generated name via Bicep
- **Log Analytics**: Auto-generated name via Bicep

**PROD Environment (HAZE-00B9-APP1066-PROD-Martech-SharedServices)**
- **Subscription ID**: TBD (provided by IT)
- **Resource Group**: `rg-hsq-forms-prod`
- **Container Registry**: `hsqformsprodacr.azurecr.io`
- **Container App Environment**: Auto-generated name via Bicep
- **PostgreSQL Server**: Auto-generated name via Bicep
- **Storage Account**: Auto-generated name via Bicep
- **Log Analytics**: Auto-generated name via Bicep

## 🔧 Infrastructure as Code

### Bicep Templates
- **Location**: `/infra/main.bicep`
- **Parameters**: Environment-specific parameter files
  - `main.parameters.dev.json` - DEV environment
  - `main.parameters.prod.json` - PROD environment

### Included Resources
1. **Container Apps Environment** - Hosting för API
2. **PostgreSQL Flexible Server** - Database
3. **Storage Account** - File uploads med containers:
   - `form-uploads` - Permanent files
   - `temp-uploads` - Temporary files
4. **Log Analytics Workspace** - Monitoring
5. **Managed Identity** - Säker åtkomst till resources

## 🚀 CI/CD Pipeline

### Pipeline Stages
1. **Test Stage** - Python tests och validering
2. **Infrastructure Stage** - Bicep deployment
3. **BuildAndDeployDev** - Container build + deploy till DEV
4. **BuildAndDeployProd** - Container build + deploy till PROD

### Branch Strategy
- **develop** → Deploys automatiskt till DEV
- **main** → Deploys automatiskt till PROD

## 🔑 Required Setup

### Service Connections
Följande Service Connections behöver skapas i Azure DevOps:

1. **AzureServiceConnection-dev**
   - Type: Azure Resource Manager
   - Subscription: HAZE-01AA-APP1066-Dev-Martechlab
   - Resource Group: rg-hsq-forms-dev

2. **AzureServiceConnection-prod**
   - Type: Azure Resource Manager  
   - Subscription: HAZE-00B9-APP1066-PROD-Martech-SharedServices
   - Resource Group: rg-hsq-forms-prod

### Docker Registry Service Connections
1. **hsqformsdevacr** (DEV ACR)
2. **hsqformsprodacr** (PROD ACR)

### Pipeline Variables
- `DB_ADMIN_PASSWORD` - Secure variable för database password

## 📦 Implementation Steps

### Phase 1: Infrastructure Setup
1. **IT Team skapar ACR registries**:
   - `hsqformsdevacr.azurecr.io` (DEV)
   - `hsqformsprodacr.azurecr.io` (PROD)
   - Aktiverar admin credentials för båda

2. **Service Connections setup**:
   - Skapa Service Connections i Azure DevOps
   - Konfigurera Docker Registry connections

### Phase 2: Infrastructure Deployment
```bash
# Deploy till DEV
az deployment group create \
  --resource-group rg-hsq-forms-dev \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.dev.json

# Deploy till PROD
az deployment group create \
  --resource-group rg-hsq-forms-prod \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.prod.json
```

### Phase 3: Pipeline Configuration
1. Importera `azure-pipelines.yml` till Azure DevOps
2. Konfigurera pipeline variables
3. Skapa environments: `dev` och `prod`
4. Testa deployment genom push till `develop` branch

## 🔒 Security Considerations

### Managed Identity
- Varje Container App får sin egen Managed Identity
- Automatisk access till Storage Account
- Ingen hårdkodade credentials

### Network Security
- Storage Account: Privat access (no public blob access)
- PostgreSQL: Firewall tillåter endast Azure services
- Container Apps: HTTPS only

### Secrets Management
- Database passwords via Azure DevOps Secure Variables
- ACR credentials via Service Connections
- Applikations-secrets via Container App environment variables

## 🎛️ Environment Configuration

### Database Settings
- **DEV**: Standard_B1ms (Burstable tier)
- **PROD**: Standard_B1ms (kan uppgraderas)
- **Backup**: 7 days retention
- **Version**: PostgreSQL 15

### Scaling Configuration
- **DEV**: 1-3 replicas
- **PROD**: 2-10 replicas

### Storage Configuration
- **Type**: Standard_LRS (Locally Redundant)
- **Encryption**: Enabled
- **CORS**: Konfigurerad för form uploads
- **Retention**: 7 days för deleted blobs

## 📈 Monitoring & Logging

### Log Analytics
- Centralized logging för alla Container Apps
- 30 days retention
- Automatic container logs collection

### Application Insights
- Performance monitoring
- Error tracking
- Custom metrics för form submissions

## 🔄 Deployment Process

### Automatisk Deployment
1. **Push till develop** → DEV deployment
2. **Push/PR till main** → PROD deployment
3. **Infrastructure changes** → Automatic Bicep deployment
4. **Application changes** → Container rebuild + deployment

### Manual Deployment
```bash
# Manual infrastructure deployment
az deployment group create \
  --resource-group <resource-group> \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.<env>.json

# Manual container deployment  
az containerapp update \
  --name <container-app-name> \
  --resource-group <resource-group> \
  --image <acr-name>.azurecr.io/hsq-forms-api:latest
```

## 📋 Next Actions

### Immediate (IT Team)
1. ✅ Create ACR registries med admin credentials
2. ✅ Provide PROD subscription details
3. ✅ Setup initial resource groups

### After Infrastructure (DevOps Team)
1. Configure Service Connections
2. Setup pipeline variables
3. Test DEV deployment
4. Validate PROD deployment
5. Setup monitoring alerts

### Post-Deployment
1. Configure custom domains (om needed)
2. Setup backup strategies
3. Performance tuning
4. Security reviews

---

**Status**: Ready för infrastructure setup  
**Next Step**: IT Team infrastructure creation
