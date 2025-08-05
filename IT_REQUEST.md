# 📧 IT REQUEST - H**DEV Environment**
- *# DEV ACR
az acr create \
  --name hsqformsdevacr \
  --resource-group rg-hsq-forms-dev \
  --sku Basic \
  --admin-enabled true \
  --location "West Europe": `hsqformsdevacr`
- **Subscription**: HAZE-01AA-APP1066-Dev-Martechlab (`c0b03b12-570f-4442-b337-c9175ad4037f`)
- **Resource Group**: `rg-hsq-forms-dev` (create if not exists)orms API Azure Setup

**Subject:** Azure Infrastructure & DevOps Setup för HSQ Forms API  
**Requester:** Emil Karlsson (Emil.Karlsson@husqvarnagroup.com)  
**Priority:** Medium  
**Date:** 2025-01-04

## 🎯 Project Overview

**Project:** HSQ Forms API  
**Purpose:** Customer support forms backend with React frontends  
**Architecture:** FastAPI + PostgreSQL + Azure Blob Storage  
**Deployment:** Azure Container Apps via Azure DevOps Pipelines

## 🏗️ Infrastructure Requirements

### Container Registries
Behöver Azure Container Registries för båda miljöer:

**DEV Environment**
- **Name**: `hsqformsdevek2025`
- **Subscription**: HAZE-01AA-APP1066-Dev-Martechlab (`c0b03b12-570f-4442-b337-c9175ad4037f`)
- **Resource Group**: `rg-hsq-forms-dev-westeu` (create if not exists)
- **SKU**: Basic
- **Admin Credentials**: Enabled
- **Location**: West Europe

**PROD Environment**
- **Name**: `hsqformsprodacr`
- **Subscription**: HAZE-00B9-APP1066-PROD-Martech-SharedServices
- **Resource Group**: `rg-hsq-forms-prod-westeu` (create if not exists)
- **SKU**: Standard
- **Admin Credentials**: Enabled
- **Location**: West Europe

### Required Actions

#### 1. Create ACR Registries
```bash
# DEV ACR
az acr create 
  --name hsqformsdevek2025 
  --resource-group rg-hsq-forms-dev-westeu 
  --sku Basic 
  --admin-enabled true 
  --location "West Europe"

# PROD ACR
az acr create 
  --name hsqformsprodacr 
  --resource-group rg-hsq-forms-prod-westeu 
  --sku Standard 
  --admin-enabled true 
  --location "West Europe"
```

#### 2. Extract Admin Credentials
Efter ACR creation, extract admin credentials:

```bash
# DEV credentials
az acr credential show --name hsqformsdevacr

# PROD credentials  
az acr credential show --name hsqformsprodacr
```

#### 3. Provide Infrastructure Details
- Complete infrastructure kommer att deployas automatiskt via Bicep templates
- Endast ACR credentials behöver konfigureras manuellt
- Resterande resources (Container Apps, Database, Storage) skapas via pipeline

## 🔧 Integration med Azure DevOps

### Service Connections (DevOps Team)
Efter infrastructure setup kommer DevOps team att skapa:

1. **Azure Resource Manager Connections**:
   - DEV: Connection till HAZE-01AA-APP1066-Dev-Martechlab
   - PROD: Connection till HAZE-00B9-APP1066-PROD-Martech-SharedServices

2. **Docker Registry Connections**:
   - DEV: `hsqformsdevacr.azurecr.io`
   - PROD: `hsqformsprodacr.azurecr.io`

### Pipeline Variables Needed
Efter ACR setup, provide följande för pipeline configuration:

**DEV ACR Variables**:
- `ACR_USERNAME_DEV`: Admin username från DEV ACR
- `ACR_PASSWORD_DEV`: Admin password från DEV ACR

**PROD ACR Variables**:
- `ACR_USERNAME_PROD`: Admin username från PROD ACR
- `ACR_PASSWORD_PROD`: Admin password från PROD ACR

## 🔒 Security Considerations

### Network Security
- ACR registries med private endpoint capability
- Admin credentials används endast för initial CI/CD setup
- Managed Identity används för runtime access

### Access Control
- Resource-level RBAC konfiguration
- Least privilege access principles
- Service Connection isolation per environment

## 📁 Additional Infrastructure

### Automated via Bicep
Följande kommer att deployas automatiskt via Azure DevOps pipeline:

- **Container Apps Environment** med Log Analytics
- **PostgreSQL Flexible Server** med firewall rules
- **Storage Account** med blob containers och CORS
- **Managed Identity** för secure resource access
- **Log Analytics Workspace** för monitoring

### Resource Naming Convention
- Pattern: `{project}-{resource}-{environment}-{uniqueToken}`
- Examples:
  - `hsq-forms-api-dev-abc123` (Container App)
  - `hsq-forms-db-dev-abc123` (PostgreSQL)
  - `hsqformsdevstg123` (Storage Account)

## 🚀 Deployment Architecture

### Pipeline Flow
1. **Infrastructure Stage**: Deploy Bicep template
2. **Build Stage**: Build container image
3. **Deploy Stage**: Push till ACR + Update Container App

### Environment Strategy
- **develop** branch → Automatic DEV deployment
- **main** branch → Automatic PROD deployment
- Manual approvals för PROD environment

## 📊 Monitoring Setup

### Included in Bicep Deployment
- Log Analytics Workspace för centralized logging
- Container Apps insights och metrics
- Storage Account monitoring
- Database performance insights

### Custom Monitoring
- Application performance monitoring via Application Insights
- Custom alerts för business metrics
- Health checks och availability monitoring

## 📋 Deliverables from IT Team

### Required Outputs
1. **ACR Registry URLs**:
   - DEV: `hsqformsdevacr.azurecr.io`
   - PROD: `hsqformsprodacr.azurecr.io`

2. **Admin Credentials** (secure delivery):
   - DEV ACR: username/password
   - PROD ACR: username/password

3. **Resource Group Confirmation**:
   - `rg-hsq-forms-dev-westeu` (DEV)
   - `rg-hsq-forms-prod-westeu` (PROD)

4. **PROD Subscription Details**:
   - Subscription ID för HAZE-00B9-APP1066-PROD-Martech-SharedServices
   - Confirmation of access rights

### Validation Steps
Efter setup, please confirm:
- [ ] ACR registries created och accessible
- [ ] Admin credentials enabled och functional
- [ ] Resource groups created
- [ ] PROD subscription accessible
- [ ] Credentials securely shared med DevOps team

## 🎯 Success Criteria

### Phase 1 Complete
- ✅ DEV ACR registry operational
- ✅ PROD ACR registry operational  
- ✅ Admin credentials provided
- ✅ Resource groups established

### Ready for DevOps Handover
- ✅ All infrastructure prerequisites met
- ✅ Credentials securely transferred
- ✅ Documentation updated med actual resource names
- ✅ Permissions verified för Service Connection creation

## 📞 Contact Information

**Development Team Contact**: [Team Lead]  
**Azure DevOps Project**: HSQ Forms API  
**Repository**: hsq-forms-api  

**Questions**: Please reach out för any clarifications eller additional requirements.

---

**Status**: Awaiting IT Team action  
**Estimated Timeline**: 1-2 weeks från approval  
**Next Step**: IT Team infrastructure creation + credential provisioning

## 🔧 Azure DevOps Configuration

### Service Connections Required
**None** - Using ACR admin credentials approach to avoid permission issues

### Pipeline Variables Needed
```
DEV Environment:
- ACR_USERNAME_DEV (secure)
- ACR_PASSWORD_DEV (secure)

PROD Environment:
- ACR_USERNAME_PROD (secure)  
- ACR_PASSWORD_PROD (secure)
```

## 📋 Specific Requests

### 1. Create Azure Infrastructure
- [ ] Create DEV resources in Dev-Martechlab subscription
- [ ] Create PROD resources in PROD-Martech-SharedServices subscription
- [ ] Enable ACR admin credentials for both registries
- [ ] Configure Container Apps for auto-deployment from ACR

### 2. Provide ACR Credentials
- [ ] Extract admin username/password for DEV ACR
- [ ] Extract admin username/password for PROD ACR
- [ ] Add credentials as secure variables in Azure DevOps pipeline

### 3. Configure Permissions
- [ ] Ensure Emil.Karlsson@husqvarnagroup.com has Contributor access on both resource groups
- [ ] Configure Container Apps to pull from respective ACRs
- [ ] Set up managed identity for Azure services access

### 4. Database Setup
- [ ] Create PostgreSQL databases: `hsq_forms`
- [ ] Configure firewall rules for Azure services
- [ ] Provide connection strings for applications

## 🎯 Expected Outcome

After completion:
- ✅ Working CI/CD pipeline from Azure DevOps
- ✅ Automatic deployments from `develop` → DEV and `main` → PROD
- ✅ Container Apps auto-update when new images are pushed
- ✅ Database connectivity configured
- ✅ File storage ready for form attachments

## 📞 Contact Information

**Primary Contact:** Emil Karlsson  
**Email:** Emil.Karlsson@husqvarnagroup.com  
**Azure DevOps Project:** Customforms  
**Repository:** hsq-forms-api

## 🔄 Implementation Approach

**Phase 1:** Infrastructure Creation (both environments)  
**Phase 2:** ACR Configuration & Credentials  
**Phase 3:** Pipeline Testing & Validation  
**Phase 4:** Production Deployment  

**Estimated Timeline:** 1-2 weeks

---

**Note:** This approach uses ACR admin credentials instead of Service Connections to avoid the permission issues we encountered previously. This is a simpler, more reliable deployment method for our use case.
