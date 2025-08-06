# HSQ Forms API - Azure Deployment Plan

## Overview
This document outlines the comprehensive deployment strategy for the HSQ Forms API to Azure using Azure DevOps with proper environment separation and enterprise-grade security practices.

## Architecture Overview

### Environment Strategy
- **Development**: HAZE-01AA-APP1066-Dev-Martechlab
- **Production**: HAZE-00B9-APP1066-PROD-Martech-SharedServices

### Naming Conventions
- Resource Groups: `rg-hsq-forms-{env}-{region}`
- Container Registry: `hsqforms{env}acr`
- Container Apps: `hsq-forms-api-{env}`
- App Service Plans: `asp-hsq-forms-{env}-{region}`

## Infrastructure Components

### Azure Container Registry (ACR)
- **Development**: hsqformsdevacr (West Europe)
- **Production**: hsqformsprodacr (West Europe)
- Authentication: Admin credentials (enterprise-friendly)
- Features: Image scanning, vulnerability assessment

### Azure Container Apps
- **Development**:
  - Min replicas: 1, Max replicas: 3
  - CPU: 0.25 cores, Memory: 0.5Gi
  - Environment: Development settings
- **Production**:
  - Min replicas: 2, Max replicas: 10
  - CPU: 0.5 cores, Memory: 1.0Gi
  - Environment: Production settings

### Azure PostgreSQL
- **Development**: Flexible Server, B1ms SKU
- **Production**: Flexible Server, GP_Standard_D2s_v3 SKU
- Features: Backup retention, high availability (prod only)

## Deployment Process

### Phase 1: Infrastructure Setup
1. **Azure DevOps Setup**
   - Create service connections for both subscriptions
   - Configure variable groups for environment-specific settings
   - Set up ACR admin credentials as secure variables

2. **Azure Resources**
   - Deploy infrastructure using Bicep templates
   - Configure networking and security settings
   - Set up monitoring and logging

### Phase 2: Application Deployment
1. **Container Build & Push**
   - Multi-stage Docker build for optimization
   - Security scanning and vulnerability assessment
   - Push to environment-specific ACR

2. **Container App Deployment**
   - Deploy to development environment first
   - Run automated tests and validation
   - Deploy to production with approval gates

### Phase 3: Validation & Monitoring
1. **Health Checks**
   - Application health endpoints
   - Database connectivity validation
   - Integration tests

2. **Monitoring Setup**
   - Application Insights integration
   - Log Analytics workspace
   - Alerting rules and notifications

## Azure DevOps Configuration

### Required Service Connections
- Azure Resource Manager connection for dev subscription
- Azure Resource Manager connection for prod subscription
- Docker Registry connection for each ACR

### Variable Groups
**HSQ-Forms-Dev-Variables**
```
ACR_LOGIN_SERVER: hsqformsdevacr.azurecr.io
ACR_USERNAME: hsqformsdevacr
ACR_PASSWORD: [Secure variable from ACR admin credentials]
AZURE_SUBSCRIPTION_ID: HAZE-01AA-APP1066-Dev-Martechlab
RESOURCE_GROUP: rg-hsq-forms-dev-westeu
CONTAINER_APP_NAME: hsq-forms-api-dev
```

**HSQ-Forms-Prod-Variables**
```
ACR_LOGIN_SERVER: hsqformsprodacr.azurecr.io
ACR_USERNAME: hsqformsprodacr
ACR_PASSWORD: [Secure variable from ACR admin credentials]
AZURE_SUBSCRIPTION_ID: [Production subscription ID]
RESOURCE_GROUP: rg-hsq-forms-prod-westeu
CONTAINER_APP_NAME: hsq-forms-api-prod
```

### Pipeline Structure
1. **Build Stage**: Docker image build and push to ACR
2. **Deploy Dev Stage**: Automated deployment to development
3. **Test Stage**: Automated testing in development
4. **Deploy Prod Stage**: Manual approval + production deployment

## Security Considerations

### Container Security
- Non-root user execution
- Minimal base image (python:3.11-slim)
- Multi-stage builds to reduce attack surface
- Regular dependency updates

### Network Security
- Private endpoints for database connections
- Network security groups with minimal required access
- HTTPS/TLS encryption for all communications

### Access Control
- Azure RBAC for resource access
- Managed identities where possible
- Secure variable storage in Azure DevOps

## Monitoring & Observability

### Application Monitoring
- Health check endpoints: `/health`, `/ready`
- Application Insights for performance monitoring
- Structured logging with correlation IDs

### Infrastructure Monitoring
- Azure Monitor for resource metrics
- Log Analytics for centralized logging
- Custom dashboards for operational visibility

### Alerting
- Application performance degradation
- High error rates or failures
- Resource utilization thresholds
- Security incidents

## Disaster Recovery

### Backup Strategy
- Database automated backups (35-day retention)
- Container image retention in ACR
- Infrastructure as Code for rapid recovery

### High Availability
- Multi-zone deployment for production
- Auto-scaling based on demand
- Health probes and automatic restart

## Deployment Commands

### Initial Setup
```bash
# Create Azure resources
./deployment/scripts/deploy-azure-resources.sh dev
./deployment/scripts/deploy-azure-resources.sh prod

# Configure Azure DevOps variables
az devops variable-group create --organization https://dev.azure.com/your-org --project HSQ-Forms
```

### Daily Operations
```bash
# Deploy to development
az pipelines run --name "HSQ Forms API - CI/CD" --branch main

# Check deployment status
az containerapp show --name hsq-forms-api-dev --resource-group rg-hsq-forms-dev-westeu
```

## Troubleshooting

### Common Issues
1. **ACR Authentication**: Verify admin credentials are enabled and correct
2. **Container App Startup**: Check health endpoints and logs
3. **Database Connectivity**: Verify connection strings and firewall rules
4. **Pipeline Failures**: Check service connection permissions

### Debug Commands
```bash
# Check container logs
az containerapp logs show --name hsq-forms-api-dev --resource-group rg-hsq-forms-dev-westeu

# Test ACR connectivity
docker login hsqformsdevacr.azurecr.io

# Validate health endpoints
curl https://hsq-forms-api-dev.azurecontainerapps.io/health
```

## Next Steps

1. **Immediate Actions**:
   - Set up Azure DevOps project and service connections
   - Configure variable groups with ACR credentials
   - Run initial infrastructure deployment

2. **Short Term**:
   - Execute first pipeline deployment to development
   - Validate application functionality
   - Set up monitoring and alerting

3. **Long Term**:
   - Implement automated testing suite
   - Add performance monitoring
   - Document operational procedures

## Support Contacts
- Azure Infrastructure: [Your Azure Team]
- Application Development: [Your Dev Team]
- DevOps/CI-CD: [Your DevOps Team]
