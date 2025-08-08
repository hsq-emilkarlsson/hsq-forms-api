// 🚀 HSQ Forms API - Azure App Service Alternative
// Enkel Web App deployment utan VNet permissions

targetScope = 'resourceGroup'

// 📋 PARAMETERS
@description('Environment name (dev, test, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Project name used in resource naming')
param projectName string = 'hsq-forms'

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

@description('Database administrator username')
@secure()
param dbAdminUsername string

@description('Database administrator password')
@secure()
param dbAdminPassword string

// 🏷️ RESOURCE NAMING
var shortToken = take(uniqueString(resourceGroup().id, deployment().name), 8)
var tags = {
  Environment: environmentName
  Project: projectName
  ManagedBy: 'Bicep'
}

// 📊 Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${projectName}-logs-${environmentName}-${shortToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// 🗄️ PostgreSQL Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: '${projectName}-db-${environmentName}-${shortToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: dbAdminUsername
    administratorLoginPassword: dbAdminPassword
    version: '15'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

// 📁 Storage Account (PRIVATE ACCESS)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${projectName}st${environmentName}${shortToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'  // 🔒 POLICY COMPLIANT
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// 📦 App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${projectName}-plan-${environmentName}-${shortToken}'
  location: location
  tags: tags
  sku: {
    name: appServicePlanSku
  }
  kind: 'linux'
  properties: {
    reserved: true  // Linux App Service Plan
  }
}

// 🎭 Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${projectName}-identity-${environmentName}-${shortToken}'
  location: location
  tags: tags
}

// 🌐 App Service (Web App)
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: '${projectName}-api-${environmentName}-${shortToken}'
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    publicNetworkAccess: 'Disabled'  // 🔒 POLICY COMPLIANT
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: true
      ftpsState: 'Disabled'
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
      appSettings: [
        {
          name: 'DATABASE_URL'
          value: 'postgresql://${dbAdminUsername}:${dbAdminPassword}@${postgresServer.properties.fullyQualifiedDomainName}:5432/postgres'
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT_NAME'
          value: storageAccount.name
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'ENVIRONMENT'
          value: environmentName
        }
        {
          name: 'PORT'
          value: '8000'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
      ]
    }
  }
}

// 🔒 RBAC - Storage Blob Data Contributor
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, managedIdentity.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 📤 OUTPUTS
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output storageAccountName string = storageAccount.name
output databaseHost string = postgresServer.properties.fullyQualifiedDomainName
output managedIdentityClientId string = managedIdentity.properties.clientId
