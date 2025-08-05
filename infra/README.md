# 🏗️ Infrastructure Guide - HSQ Forms API

## 📋 Overview
This directory contains Infrastructure as Code (IaC) templates for deploying HSQ Forms API to Azure using Bicep templates.

## 🎯 Architecture

### Resources Deployed
- **Container Apps Environment** - Hosting platform
- **Container App** - Application runtime
- **PostgreSQL Flexible Server** - Database
- **Storage Account** - File uploads and temporary storage
- **Log Analytics Workspace** - Monitoring and logging
- **Managed Identity** - Secure resource access

### Environment Strategy
- **DEV**: Development environment for testing
- **PROD**: Production environment for live workloads

## 📁 File Structure

```
infra/
├── main.bicep                    # Main infrastructure template
├── main.parameters.dev.json     # DEV environment parameters
├── main.parameters.prod.json    # PROD environment parameters
└── README.md                     # This file
```

## 🔧 Template Parameters

### Required Parameters
- `environmentName`: Environment identifier (dev/prod)
- `dbAdminUsername`: Database administrator username
- `dbAdminPassword`: Database administrator password (secure)

### Optional Parameters
- `location`: Azure region (defaults to resource group location)
- `projectName`: Project name prefix (defaults to 'hsq-forms')
- `containerAppScale`: Scaling configuration object

## 🚀 Deployment Methods

### 1. Azure DevOps Pipeline (Recommended)
Infrastructure is automatically deployed via the pipeline in `azure-pipelines.yml`:

```yaml
- task: AzureCLI@2
  displayName: 'Deploy Bicep Template'
  inputs:
    azureSubscription: 'AzureServiceConnection-$(environment)'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az deployment group create \
        --resource-group $(resourceGroupName) \
        --template-file infra/main.bicep \
        --parameters @infra/main.parameters.$(environment).json \
        --parameters dbAdminPassword="$(DB_ADMIN_PASSWORD)"
```

### 2. Manual Deployment via Azure CLI

#### DEV Environment
```bash
# Create resource group
az group create --name rg-hsq-forms-dev --location "West Europe"

# Deploy infrastructure
az deployment group create \
  --resource-group rg-hsq-forms-dev \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.dev.json \
  --parameters dbAdminPassword="YourSecurePassword123!"
```

#### PROD Environment
```bash
# Create resource group  
az group create --name rg-hsq-forms-prod --location "West Europe"

# Deploy infrastructure
az deployment group create \
  --resource-group rg-hsq-forms-prod \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.prod.json \
  --parameters dbAdminPassword="YourSecurePassword123!"
```

### 3. Azure Portal Deployment
1. Open Azure Portal
2. Go to "Deploy a custom template"
3. Upload `main.bicep` file
4. Fill in parameters
5. Deploy to target resource group

## 🔒 Security Configuration

### Managed Identity
Each Container App gets a User-Assigned Managed Identity for secure access to:
- Storage Account (automatic role assignment via Bicep)
- Database (connection string via environment variables)
- Other Azure resources (as needed)

### Network Security
- **Storage Account**: Private access, no public blob access
- **Database**: Firewall rules allowing only Azure services
- **Container Apps**: HTTPS-only communication
- **CORS**: Configured for form uploads

### Secrets Management
- Database passwords: Stored as Container App secrets
- Storage keys: Accessed via Managed Identity
- Application secrets: Environment variables

## 📊 Monitoring & Logging

### Log Analytics Workspace
- Centralized logging for all Container Apps
- 30-day retention period
- Automatic log collection from containers

### Available Metrics
- Container resource usage (CPU, Memory)
- HTTP request metrics
- Database connection metrics
- Storage access patterns

## 🎛️ Environment Configuration

### DEV Environment
```json
{
  "environmentName": "dev",
  "containerAppScale": {
    "minReplicas": 1,
    "maxReplicas": 3
  }
}
```

### PROD Environment
```json
{
  "environmentName": "prod", 
  "containerAppScale": {
    "minReplicas": 2,
    "maxReplicas": 10
  }
}
```

## 📤 Template Outputs

The Bicep template provides these outputs for use by other systems:

```bicep
# Application Endpoints
output SERVICE_API_URI string          # Container App public URL
output SERVICE_API_NAME string         # Container App name

# Database Information  
output databaseHost string             # PostgreSQL server FQDN
output databaseName string             # Database name

# Storage Information
output AZURE_STORAGE_ACCOUNT_NAME string     # Storage account name  
output AZURE_STORAGE_BLOB_ENDPOINT string    # Blob endpoint URL

# Security
output SERVICE_API_IDENTITY_PRINCIPAL_ID string  # Managed Identity principal ID
```

## 🔄 Update Strategy

### Infrastructure Updates
1. Modify Bicep template or parameters
2. Commit changes to repository
3. Pipeline automatically deploys updates
4. Zero-downtime for most changes

### Database Schema Updates
```bash
# Run Alembic migrations after infrastructure deployment
alembic upgrade head
```

### Container App Updates
```bash
# Update container image
az containerapp update \
  --name <container-app-name> \
  --resource-group <resource-group> \
  --image <acr-name>.azurecr.io/hsq-forms-api:latest
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Resource Name Conflicts
```bash
# Check existing resources
az resource list --resource-group <resource-group> --output table
```

#### 2. Parameter Validation Errors
- Verify parameter file syntax
- Check required vs optional parameters
- Validate data types (string, int, object)

#### 3. Permission Issues
```bash
# Check current user permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

#### 4. Template Validation
```bash
# Validate template before deployment
az deployment group validate \
  --resource-group <resource-group> \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.dev.json
```

## 📋 Pre-deployment Checklist

### Prerequisites
- [ ] Azure subscription access
- [ ] Resource group created
- [ ] Contributor permissions on resource group
- [ ] Database admin password defined
- [ ] ACR registry available (for container deployment)

### Validation Steps
- [ ] Template syntax validation
- [ ] Parameter file validation  
- [ ] Resource naming conventions
- [ ] Security configuration review
- [ ] Cost estimation review

## 🚀 Post-deployment Steps

### Immediate Tasks
1. **Verify deployment**: Check all resources created successfully
2. **Test connectivity**: Validate database and storage access
3. **Update DNS**: Configure custom domains if needed
4. **Setup monitoring**: Configure alerts and dashboards

### Container App Configuration
```bash
# Get Container App details
az containerapp show --name <app-name> --resource-group <resource-group>

# View logs
az containerapp logs show --name <app-name> --resource-group <resource-group>
```

### Database Setup
```bash
# Connect to database
psql "host=<db-host> port=5432 dbname=hsq_forms user=<username>"

# Run initial migrations
alembic upgrade head
```

## 📞 Support

### Common Commands

```bash
# List all resources in resource group
az resource list --resource-group <rg-name> --output table

# Get Container App logs
az containerapp logs show --name <app-name> --resource-group <rg-name> --follow

# Check database connectivity
az postgres flexible-server connect --name <server-name> --admin-user <username>

# Monitor deployments
az deployment group list --resource-group <rg-name> --output table
```

### Documentation Links
- [Azure Container Apps Documentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [PostgreSQL Flexible Server](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/)
- [Bicep Template Reference](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

---

**Status**: Ready for deployment  
**Version**: 1.0  
**Last Updated**: 2025
