// 🏗️ HSQ Forms API - Clean Azure Infrastructure
// Skapar alla nödvändiga Azure-resurser för HSQ Forms API
// Stöder både DEV och PROD miljöer

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

@description('Container app minimum replicas')
param containerAppMinReplicas int = 1

@description('Container app maximum replicas')
param containerAppMaxReplicas int = 3

@description('Enable Virtual Network integration')
param enableVNet bool = true  // Default changed to true to comply with Azure Policy

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
    publicNetworkAccess: 'Disabled'
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

// 🌐 Virtual Network (Conditional - Only if enableVNet=true)
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = if (enableVNet) {
  name: '${projectName}-vnet-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'container-apps-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
    ]
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

// 🏗️ Container Apps Environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${projectName}-env-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  properties: {
    // Always use VNet integration
    vnetConfiguration: enableVNet && vnet != null ? {
      infrastructureSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'container-apps-subnet')
      internal: true  // Internal to comply with security policy
    } : null
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// 🔐 Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${projectName}-identity-${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

// 🚀 Container App
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
        external: false  // Ingen extern åtkomst pga Azure Policy
        targetPort: 8000
        transport: 'tcp'  // Using TCP transport for VNet integration
        allowInsecure: false
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
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          env: [
            {
              name: 'APP_ENVIRONMENT'
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
      scale: {
        minReplicas: containerAppMinReplicas
        maxReplicas: containerAppMaxReplicas
      }
    }
  }
}

// 📤 Outputs
output RESOURCE_GROUP_ID string = resourceGroup().id
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = containerAppsEnvironment.id
output SERVICE_API_IDENTITY_PRINCIPAL_ID string = managedIdentity.properties.principalId
output SERVICE_API_NAME string = containerApp.name
output SERVICE_API_URI string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.name
output AZURE_STORAGE_BLOB_ENDPOINT string = storageAccount.properties.primaryEndpoints.blob

// Backward compatibility
output storageAccountName string = storageAccount.name
output databaseHost string = postgresServer.properties.fullyQualifiedDomainName
output databaseName string = postgresServer::database.name
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
