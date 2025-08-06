// 🚀 HSQ Forms API - Minimal Test Infrastructure
// Test Azure Policy compliance utan VNet permissions

@description('Environment name (dev/prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Project name prefix')
param projectName string = 'hsq-forms'

// Variables
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))
var tags = {
  Environment: environmentName
  Project: projectName
  ManagedBy: 'Bicep'
  'azd-env-name': environmentName
}

// 💾 Storage Account for file uploads (policy compliant)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${projectName}${environmentName}${resourceToken}'
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'  // Policy compliant
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// 📊 Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${projectName}-logs-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// 🏗️ Container Apps Environment (minimal test)
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${projectName}-env-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// 📤 Outputs
output RESOURCE_GROUP_ID string = resourceGroup().id
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = containerAppsEnvironment.id
output STORAGE_ACCOUNT_NAME string = storageAccount.name
