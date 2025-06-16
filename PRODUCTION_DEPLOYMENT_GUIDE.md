# 🚀 HSQ Forms API - Production Deployment Guide

**Date:** June 15, 2025  
**Environment:** Azure Cloud Platform  
**Deployment Type:** Container Apps + PostgreSQL + Blob Storage

## 📋 Deployment Overview

### 🏗️ Infrastructure Architecture

HSQ Forms API deployar till Azure med följande arkitektur:

```
┌─────────────────────────────────────────────────────────────┐
│                    AZURE RESOURCE GROUP                     │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  │  CONTAINER APPS │  │   POSTGRESQL    │  │ BLOB STORAGE    │
│  │   ENVIRONMENT   │  │ FLEXIBLE SERVER │  │    ACCOUNT      │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘
│           │                      │                      │      │
│           │                      │                      │      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  │   API SERVICE   │  │ hsq_forms DB    │  │ form-uploads    │
│  │ (FastAPI/Python)│  │ (UTF8/Postgres)│  │ temp-uploads    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘
│           │                      │                      │      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  │ FORM CONTAINERS │  │   MONITORING    │  │ MANAGED IDENTITY│
│  │ B2B/B2C Forms  │  │ Log Analytics   │  │   (Security)    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘
└─────────────────────────────────────────────────────────────┘
```

## 🌐 Deployment Locations & URLs

### Production Environment
- **Primary Region**: West Europe (westeurope)
- **Resource Group**: `hsq-forms-prod-rg`
- **Environment**: `prod`

### Deployed Services & URLs

| Service | Type | Production URL | Purpose |
|---------|------|----------------|---------|
| **Main API** | Container App | `https://hsq-forms-api-prod-{token}.westeurope.azurecontainerapps.io` | Backend API services |
| **B2B Support Form** | Container App | `https://hsq-forms-b2b-support-prod-{token}.westeurope.azurecontainerapps.io` | Technical support requests |
| **B2B Returns Form** | Container App | `https://hsq-forms-b2b-returns-prod-{token}.westeurope.azurecontainerapps.io` | Product returns |
| **B2C Returns Form** | Container App | `https://hsq-forms-b2c-returns-prod-{token}.westeurope.azurecontainerapps.io` | Consumer returns |
| **B2B Feedback Form** | Container App | `https://hsq-forms-b2b-feedback-prod-{token}.westeurope.azurecontainerapps.io` | Customer feedback |

*Note: `{token}` är en unik identifierare som genereras av Azure*

## 💾 Storage & Data Management

### 📊 Database (PostgreSQL Flexible Server)

**Configuration:**
- **Server**: `hsq-forms-prod-{token}.postgres.database.azure.com`
- **Database**: `hsq_forms`
- **Version**: PostgreSQL 15
- **Tier**: Standard_B1ms (Burstable, upgradeable to General Purpose för production)
- **Storage**: 32GB (auto-grow enabled)
- **Backup**: 7 dagar retention
- **SSL**: Enforced (TLS 1.2)

**Tables & Data:**
```sql
-- Huvudtabeller för formulärdata
- form_templates       (Formulärmallar)
- flexible_form_submissions (Inlämnade formulär)
- flexible_form_attachments (Filuppladdningar)
- form_submissions     (Grundläggande submissions)
- file_attachments     (Filmetadata)

-- Alembic migrations (Databasversioner)
- alembic_version      (Schema versioning)
```

### 🗂️ File Storage (Azure Blob Storage)

**Storage Account**: `hsqformsprod{token}`

**Containers:**
1. **`form-uploads`** (Permanent storage)
   - Uploaded files från formulär
   - Retention: Permanent (eller enligt data retention policy)
   - Access: Private (endast via Managed Identity)

2. **`temp-uploads`** (Temporary storage)
   - Temporära filer under uppladdning
   - Retention: 7 dagar (automatic cleanup)
   - Access: Private

**File Organization:**
```
form-uploads/
├── submissions/
│   └── {submission_id}/
│       ├── document1.pdf
│       ├── image1.jpg
│       └── attachment.xlsx
└── templates/
    └── {template_id}/
        └── default_files/

temp-uploads/
└── {session_id}/
    ├── pending_file1.pdf
    └── pending_file2.jpg
```

## 🔐 Security & Access Control

### 🛡️ Managed Identity
- **Type**: User-assigned Managed Identity
- **Purpose**: Säker åtkomst mellan services utan lösenord
- **Permissions**:
  - Storage Blob Data Contributor (för filhantering)
  - Database access via Azure AD (om konfigurerat)

### 🔒 Network Security
- **API Endpoint**: HTTPS only (TLS 1.2+)
- **Database**: SSL enforced, firewall-protected
- **Storage**: HTTPS only, private containers
- **CORS**: Konfigurerat för specifika domäner

### 🔑 Secrets Management
```yaml
# Secrets stored in Azure Container Apps
DATABASE_URL: "postgresql://username:password@server:5432/hsq_forms"
AZURE_STORAGE_ACCOUNT_KEY: "{storage_key}"
AZURE_CLIENT_ID: "{managed_identity_client_id}"
```

## 🚀 Deployment Process

### Prerequisites
```bash
# Install Azure Developer CLI
brew install azure/azd/azd

# Install Azure CLI
brew install azure-cli

# Login to Azure
az login
azd auth login
```

### 1. Initial Infrastructure Deployment

```bash
# Navigate to project
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api

# Initialize AZD (first time only)
azd init

# Set environment variables
azd env set AZURE_LOCATION westeurope
azd env set AZURE_SUBSCRIPTION_ID {your_subscription_id}

# Deploy infrastructure and application
azd up
```

**Vad händer under `azd up`:**
1. **Infrastructure Provisioning** (via Bicep)
   - Resource Group skapas
   - PostgreSQL server och databas
   - Storage Account med containers
   - Container Apps Environment
   - Managed Identity och permissions
   - Log Analytics för monitoring

2. **Application Deployment**
   - API container byggs och deployas
   - Database migrations körs automatiskt
   - Environment variables konfigureras
   - Health checks aktiveras

### 2. Form Containers Deployment

```bash
# Deploy B2B Support Form
cd forms/hsq-forms-container-b2b-support
azd deploy --service b2b-support

# Deploy B2B Returns Form  
cd ../hsq-forms-container-b2b-returns
azd deploy --service b2b-returns

# Deploy B2C Returns Form
cd ../hsq-forms-container-b2c-returns  
azd deploy --service b2c-returns

# Deploy B2B Feedback Form
cd ../hsq-forms-container-b2b-feedback
azd deploy --service b2b-feedback
```

### 3. Environment Configuration

```bash
# Set production environment variables
azd env set ENVIRONMENT prod
azd env set DEBUG false
azd env set LOG_LEVEL INFO

# Configure CORS for production domains
azd env set ALLOWED_ORIGINS "https://husqvarna.com,https://gardena.com"

# Set file upload limits
azd env set MAX_FILE_SIZE_MB 10
azd env set MAX_FILES_PER_SUBMISSION 5
```

## 📊 Monitoring & Logging

### 📈 Azure Monitor Integration

**Log Analytics Workspace:**
- **Name**: `hsq-forms-logs-prod-{token}`
- **Retention**: 30 dagar
- **Queries**: KQL (Kusto Query Language)

**Key Metrics:**
```kql
// Application requests
ContainerAppConsoleLogs_CL
| where ContainerName_s == "hsq-forms-api"
| project TimeGenerated, Log_s
| order by TimeGenerated desc

// Database connections
// Monitor PostgreSQL metrics via Azure Monitor

// File upload operations  
// Track blob storage operations via Storage Analytics
```

### 🚨 Alerting

**Recommended Alerts:**
1. **API Response Time** > 5 seconds
2. **Database CPU** > 80%
3. **Storage capacity** > 80%
4. **Failed form submissions** > 5% 
5. **Container restart** events

## 🔄 Backup & Disaster Recovery

### 💾 Database Backup
- **Automatic backups**: 7 dagar retention
- **Geo-redundant**: Disabled (kan aktiveras för production)
- **Point-in-time restore**: Tillgänglig

### 📁 File Backup
- **LRS Storage**: Local redundant storage
- **Soft delete**: 7 dagar för containers
- **Versioning**: Kan aktiveras för kritiska filer

### 🆘 Disaster Recovery Plan
1. **RTO (Recovery Time Objective)**: 4 timmar
2. **RPO (Recovery Point Objective)**: 1 timme
3. **Backup strategy**: Daily automated backups
4. **Testing**: Monthly DR tests

## 💰 Cost Estimation (Monthly)

### Production Environment

| Service | Tier | Estimated Cost |
|---------|------|----------------|
| **Container Apps** | 4 apps, 0.5 vCPU each | ~€60 |
| **PostgreSQL** | Standard_B1ms | ~€25 |
| **Storage Account** | Standard_LRS, 100GB | ~€5 |
| **Log Analytics** | 1GB/day ingestion | ~€15 |
| **Network** | Egress traffic | ~€10 |
| **Total** | | **~€115/month** |

*Priser är uppskattningar baserat på West Europe region*

### Cost Optimization
- Använd **Burstable tiers** för utveckling
- **Auto-scaling** för Container Apps
- **Lifecycle policies** för storage cleanup
- **Reserved instances** för förutsägbara workloads

## 🔧 Maintenance & Updates

### Regular Tasks

**Daily:**
- Monitor dashboard för health checks
- Review error logs i Log Analytics

**Weekly:**
- Database performance review
- Storage usage analysis
- Security updates check

**Monthly:**
- Backup verification
- Cost analysis
- Performance optimization review
- Security vulnerability scan

### Update Process

```bash
# Deploy API updates
azd deploy --service api

# Deploy form updates
azd deploy --service b2b-support
azd deploy --service b2b-returns
azd deploy --service b2c-returns
azd deploy --service b2b-feedback

# Run database migrations (if needed)
azd exec --service api -- python -m alembic upgrade head
```

## 🌍 Multi-Language Support

### Språkstöd
- **English (EN)**: Default language
- **Swedish (SV)**: Complete translation
- **German (DE)**: Complete translation

### URL Structure
```
https://hsq-forms-api-prod.azurecontainerapps.io/
├── en/forms/      (English forms)
├── sv/forms/      (Swedish forms)  
├── de/forms/      (German forms)
└── api/           (Language-agnostic API)
```

## 🔗 Integration Points

### Sitecore CMS Integration

```html
<!-- Production iframe integration -->
<iframe 
  src="https://hsq-forms-b2b-support-prod-{token}.westeurope.azurecontainerapps.io?lang=sv&embed=true"
  width="100%" 
  height="800px"
  frameborder="0">
</iframe>
```

### API Integration

```javascript
// Production API base URL
const API_BASE_URL = 'https://hsq-forms-api-prod-{token}.westeurope.azurecontainerapps.io';

// Submit form data
const response = await fetch(`${API_BASE_URL}/api/templates/{template_id}/submit`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify(formData)
});
```

## 🎯 Next Steps

### Immediate (Post-Deployment)
1. **DNS Configuration**: Setup custom domains
2. **SSL Certificates**: Configure custom certificates
3. **Monitoring Setup**: Configure alerts and dashboards
4. **Load Testing**: Verify performance under load

### Short-term (1-2 weeks)
1. **CI/CD Pipeline**: Setup GitHub Actions for automated deployment
2. **Environment Promotion**: Dev → Staging → Production pipeline
3. **Security Review**: Penetration testing and vulnerability assessment
4. **Performance Optimization**: Fine-tune resource allocation

### Long-term (1-3 months)
1. **Scaling Strategy**: Auto-scaling configuration
2. **Multi-region**: Consider secondary region deployment
3. **Advanced Monitoring**: Custom metrics and business intelligence
4. **Compliance**: Data retention and GDPR compliance review

---

**Deployment Status**: 🚀 **Ready for Production**  
**Infrastructure**: ✅ Azure Container Apps + PostgreSQL + Blob Storage  
**Security**: ✅ Managed Identity + HTTPS + Private Storage  
**Monitoring**: ✅ Log Analytics + Health Checks + Alerts  
**Backup**: ✅ Automated daily backups + 7-day retention
