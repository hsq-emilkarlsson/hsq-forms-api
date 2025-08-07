// 🏗️ HSQ Forms API - Azure App Service Infrastructure
// Skapar alla nödvändiga Azure-resurser för HSQ Forms API med App Service

@description('Environment name (dev/prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Project name prefix')
param projectName string = 'hsq-forms'

@description('Database administrator username')
@secure()
param dbAdminUsername string

@description('Database administrator password')  
@secure()
param dbAdminPassword string

@description('App Service Plan SKU')
param appServiceSku string = 'B1'

// Variables
var resourceToken = take(toLower(uniqueString(subscription().id, resourceGroup().id, environmentName)), 8)
var tags = {
  Environment: environmentName
  Project: projectName
  ManagedBy: 'Bicep'
  'azd-env-name': environmentName
}

// 💾 Storage Account for file uploads
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
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  resource blobService 'blobServices@2023-01-01' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: [
          {
            allowedOrigins: ['*']
            allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS']
            allowedHeaders: ['*']
            exposedHeaders: ['*']
            maxAgeInSeconds: 86400
          }
        ]
      }
      deleteRetentionPolicy: {
        enabled: true
        days: 7
      }
    }

    resource uploadsContainer 'containers@2023-01-01' = {
      name: 'form-uploads'
      properties: {
        publicAccess: 'None'
      }
    }

    resource tempContainer 'containers@2023-01-01' = {
      name: 'temp-uploads'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// 🗄️ PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: '${projectName}-${environmentName}-${resourceToken}'
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
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }

  resource database 'databases@2023-03-01-preview' = {
    name: 'hsq_forms'
    properties: {
      charset: 'UTF8'
      collation: 'en_US.utf8'
    }
  }

  resource firewallRuleAzure 'firewallRules@2023-03-01-preview' = {
    name: 'AllowAllAzureServices'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
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
    features: {
      legacy: 0
      searchVersion: 1
    }
  }
}

// 🔐 Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${projectName}-identity-${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

// 🏗️ App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${projectName}-plan-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: appServiceSku
  }
  kind: 'linux'
  properties: {
    reserved: true  // Required for Linux
    zoneRedundant: environmentName == 'prod' ? true : false
  }
}

// 🚀 App Service (Web App)
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: '${projectName}-api-${environmentName}-${resourceToken}'
  location: location
  tags: union(tags, {
    'azd-service-name': 'api'
  })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'  // FastAPI Python Runtime
      alwaysOn: true
      ftpsState: 'Disabled'
      http20Enabled: true
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: ['*']
      }
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'true'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'SQLALCHEMY_DATABASE_URI'
          value: 'postgresql://${dbAdminUsername}:${dbAdminPassword}@${postgresServer.properties.fullyQualifiedDomainName}:5432/hsq_forms'
        }
        {
          name: 'ENVIRONMENT'
          value: environmentName
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT_NAME'
          value: storageAccount.name
        }
        {
          name: 'AZURE_STORAGE_CONTAINER_NAME'
          value: 'form-uploads'
        }
        {
          name: 'AZURE_STORAGE_TEMP_CONTAINER_NAME'
          value: 'temp-uploads'
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'PYTHON_ENABLE_GUNICORN_MULTIWORKERS'
          value: 'true'
        }
        {
          name: 'STARTUP_COMMAND'
          value: 'gunicorn main:app --workers 2 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000'
        }
      ]
    }
  }
}

// 📈 Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${projectName}-insights-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Add Application Insights to Web App
resource appServiceAppInsightsConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: appService
  name: 'appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
  }
}

// 📤 Outputs
output RESOURCE_GROUP_ID string = resourceGroup().id
output SERVICE_API_IDENTITY_PRINCIPAL_ID string = managedIdentity.properties.principalId
output SERVICE_API_NAME string = appService.name
output SERVICE_API_URI string = 'https://${appService.properties.defaultHostName}'
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.name
output AZURE_STORAGE_BLOB_ENDPOINT string = storageAccount.properties.primaryEndpoints.blob

// Backward compatibility
output storageAccountName string = storageAccount.name
output databaseHost string = postgresServer.properties.fullyQualifiedDomainName
output databaseName string = postgresServer::database.name
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
