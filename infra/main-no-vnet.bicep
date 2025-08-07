// 🧪 HSQ Forms API - NO VNET TEST (Alternative Strategy)
// Test om Azure Policy tillåter Default Network + Internal Ingress

@description('Environment name (dev/prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Project name prefix')
param projectName string = 'hsq-forms'

@description('Database administrator username')
param dbAdminUsername string

@description('Database administrator password')  
@secure()
param dbAdminPassword string

@description('Container app minimum replicas')
param containerAppMinReplicas int = 1

@description('Container app maximum replicas')
param containerAppMaxReplicas int = 3

// Variables
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))
var shortToken = substring(resourceToken, 0, 8)
var tags = {
  Environment: environmentName
  Project: projectName
  ManagedBy: 'Bicep'
  'azd-env-name': environmentName
}

// 💾 Storage Account (Policy Compliant)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'hsq${environmentName}st${shortToken}'
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

  resource blobService 'blobServices@2023-01-01' = {
    name: 'default'
    
    resource formsContainer 'containers@2023-01-01' = {
      name: 'forms'
      properties: {
        publicAccess: 'None'
      }
    }
    
    resource uploadsContainer 'containers@2023-01-01' = {
      name: 'uploads'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// 🗄️ PostgreSQL Database
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: '${projectName}-${environmentName}-${shortToken}'
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
  }
}

// 🔧 Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: 'hsq${environmentName}acr${shortToken}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
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

// 🏗️ Container Apps Environment (DEFAULT NETWORK - NO VNET!)
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${projectName}-env-${environmentName}-${shortToken}'
  location: location
  tags: tags
  properties: {
    // ✅ NO vnetConfiguration - uses Azure's default network
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
  name: '${projectName}-identity-${environmentName}-${shortToken}'
  location: location
  tags: tags
}

// 🚀 Container App (INTERNAL INGRESS - POLICY TEST)
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${projectName}-api-${environmentName}-${shortToken}'
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
        external: false  // ✅ INTERNAL INGRESS - NO PUBLIC ACCESS
        targetPort: 8000
        transport: 'http'
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
        {
          name: 'acr-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'hsq-forms-api'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'  // Placeholder
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
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
              name: 'AZURE_STORAGE_ACCOUNT_KEY'
              secretRef: 'storage-account-key'
            }
            {
              name: 'AZURE_STORAGE_CONTAINER_FORMS'
              value: 'forms'
            }
            {
              name: 'AZURE_STORAGE_CONTAINER_UPLOADS'
              value: 'uploads'
            }
          ]
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
output SERVICE_API_URI string = 'https://${containerApp.properties.configuration.ingress.fqdn}'  // Internal FQDN
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.name
output DATABASE_HOST string = postgresServer.properties.fullyQualifiedDomainName
output STORAGE_ACCOUNT_NAME string = storageAccount.name
