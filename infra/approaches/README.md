# Infrastructure Approaches

This directory contains different infrastructure deployment approaches for the HSQ Forms API. Each approach is contained in its own subdirectory, allowing you to easily test and compare different deployment strategies via DevOps pipelines.

## Available Approaches

### 1. Default (01-default)
The standard deployment approach using Container Apps with basic security and networking.

### 2. Minimal (02-minimal)
A streamlined deployment with fewer resources, ideal for development and testing.

### 3. No VNet (03-no-vnet)
A deployment without VNet integration, useful when network permissions are limited.

### 4. Minimal VNet (04-minimal-vnet)
A minimal deployment that includes VNet integration for basic network security.

### 5. Secure (05-secure)
An enhanced security deployment with private endpoints and network isolation.

### 6. AVM (06-avm)
A deployment using Azure Verified Modules for standardized, compliant infrastructure.

### 7. Ready (07-ready)
A production-ready deployment with VNet integration, policy compliance, and optimal security settings.

### 8. App Service (08-appservice)
An alternative deployment using App Service instead of Container Apps.

## Usage

To deploy a specific approach, update your pipeline to reference the desired approach's directory:

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
        --template-file infra/approaches/01-default/main.bicep \
        --parameters @infra/approaches/01-default/main.parameters.$(environment).json \
        --parameters dbAdminPassword="$(DB_ADMIN_PASSWORD)"
```

For more detailed information, refer to the main [README.md](../README.md) in the parent directory.
