// HSQ Forms API - Azure Infrastructure
// Denna Bicep-template skapar nödvändig Azure-infrastruktur för HSQ Forms API
// Följer Azure best practices för säkerhet, skalbarhet och kostnadsoptimering

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Project name prefix for resource naming')
param projectName string = 'hsq-forms'

@description('Database administrator username')
@secure()
param dbAdminUsername string

@description('Database administrator password')
@secure()
param dbAdminPassword string

@description('Container app scaling configuration')
param containerAppScale object = {
  minReplicas: 1
  maxReplicas: 3
}

// Variables för resursnamn med miljöspecifik namngivning
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))
var tags = {
  Environment: environmentName
  Project: projectName
  ManagedBy: 'Bicep'
  'azd-env-name': environmentName
}

// Storage Account för filhantering
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${projectName}${environmentName}${resourceToken}'
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS' // Lokalt redundant storage för kostnadseffektivitet
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false // Säkerhet: ingen public access
    networkAcls: {
      defaultAction: 'Allow' // Kan ändras till 'Deny' för production med VNet
    }
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  // Blob service konfiguration
  resource blobService 'blobServices@2023-01-01' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: [
          {
            allowedOrigins: ['*'] // Konfigurera specifika origins för production
            allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS']
            allowedHeaders: ['*']
            exposedHeaders: ['*']
            maxAgeInSeconds: 86400
          }
        ]
      }
      deleteRetentionPolicy: {
        enabled: true
        days: 7 // Behåll borttagna filer i 7 dagar
      }
    }

    // Container för permanenta uploads
    resource uploadsContainer 'containers@2023-01-01' = {
      name: 'form-uploads'
      properties: {
        publicAccess: 'None' // Privat åtkomst
      }
    }

    // Container för temporära uploads
    resource tempContainer 'containers@2023-01-01' = {
      name: 'temp-uploads'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// PostgreSQL Flexible Server för databas
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: '${projectName}-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_B1ms' // Burstable tier för utveckling/staging
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: dbAdminUsername
    administratorLoginPassword: dbAdminPassword
    version: '15' // PostgreSQL 15
    storage: {
      storageSizeGB: 32
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled' // Aktivera för production
    }
  }

  // Databas för applikationen
  resource database 'databases@2023-03-01-preview' = {
    name: 'hsq_forms'
    properties: {
      charset: 'UTF8'
      collation: 'en_US.utf8'
    }
  }

  // Firewall regel för Azure services
  resource firewallRuleAzure 'firewallRules@2023-03-01-preview' = {
    name: 'AllowAllAzureServices'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

// Log Analytics Workspace för monitorering
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

// Container Apps Environment
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

// User-assigned Managed Identity för säker åtkomst
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${projectName}-identity-${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

// Note: Storage role assignment removed due to permission constraints
// This will need to be configured manually in Azure Portal or by admin

// Container App för API
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
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
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8000
        transport: 'http'
        corsPolicy: {
          allowedOrigins: ['*'] // Konfigurera för specifika domains i production
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          allowCredentials: false
        }
      }
      secrets: [
        {
          name: 'database-url'
          value: 'postgresql://${dbAdminUsername}:${dbAdminPassword}@${postgresServer.properties.fullyQualifiedDomainName}:5432/hsq_forms'
        }
        {
          name: 'storage-account-key'
          value: storageAccount.listKeys().keys[0].value
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'hsq-forms-api'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest' // Base image för första deployment
          env: [
            {
              name: 'ENVIRONMENT'
              value: environmentName
            }
            {
              name: 'DATABASE_URL'
              secretRef: 'database-url'
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
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: containerAppScale
    }
  }
}

// Outputs för azd och andra services
output RESOURCE_GROUP_ID string = resourceGroup().id
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = containerAppsEnvironment.id
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = 'https://index.docker.io/v1/' // Docker Hub som default
output AZURE_CONTAINER_REGISTRY_NAME string = 'dockerhub' // Default registry
output SERVICE_API_IDENTITY_PRINCIPAL_ID string = managedIdentity.properties.principalId
output SERVICE_API_NAME string = containerApp.name
output SERVICE_API_URI string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.name
output AZURE_STORAGE_BLOB_ENDPOINT string = storageAccount.properties.primaryEndpoints.blob

// Backward compatibility outputs
output storageAccountName string = storageAccount.name
output databaseHost string = postgresServer.properties.fullyQualifiedDomainName
output databaseName string = postgresServer::database.name
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
