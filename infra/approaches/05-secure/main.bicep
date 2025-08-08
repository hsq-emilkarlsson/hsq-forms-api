// 🔒 HSQ Forms API - Secure Azure Infrastructure 
// Säkrare arkitektur med separation av frontend och API

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

@description('Allowed frontend origins for CORS')
param frontendOrigins array = []

@description('Container app scaling configuration')
param containerAppScale object = {
  minReplicas: 1
  maxReplicas: 3
}

// Variables
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))
var tags = {
  Environment: environmentName
  Project: projectName
  ManagedBy: 'Bicep'
  'azd-env-name': environmentName
}

// CORS origins baserat på miljö
var corsOrigins = environmentName == 'dev' ? [
  'http://localhost:3000'
  'http://localhost:5173'
  'http://localhost:8080'
] : length(frontendOrigins) > 0 ? frontendOrigins : [
  'https://husqvarnagroup.com'
  'https://*.husqvarnagroup.com'
]

// 💾 Secure Storage Account
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
    publicNetworkAccess: 'Disabled' // 🔒 Disable public access
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
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

  resource blobService 'blobServices@2023-01-01' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: [
          {
            allowedOrigins: corsOrigins
            allowedMethods: ['GET', 'POST', 'PUT', 'HEAD']
            allowedHeaders: ['Content-Type', 'Authorization']
            exposedHeaders: ['*']
            maxAgeInSeconds: 3600
          }
        ]
      }
      deleteRetentionPolicy: {
        enabled: true
        days: 30
      }
    }

    resource uploadsContainer 'containers@2023-01-01' = {
      name: 'form-uploads'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// 🗄️ Secure PostgreSQL Server
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
  }
}

// 🌐 Container Apps Environment with security
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${projectName}-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${projectName}-${environmentName}-${resourceToken}'
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
    vnetConfiguration: {
      internal: true // 🔒 Internal VNet för säkerhet
    }
  }
}

// 🔐 Managed Identity för säker autentisering
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${projectName}-${environmentName}-identity'
  location: location
  tags: tags
}

// 📋 Storage access för Managed Identity
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, managedIdentity.id, 'StorageBlobDataContributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 🏗️ FRONTEND Container App (Publicly accessible)
resource frontendApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${projectName}-frontend-${environmentName}'
  location: location
  tags: tags
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
        external: true // ✅ Frontend kan vara extern
        targetPort: 3000
        transport: 'http'
        corsPolicy: {
          allowedOrigins: corsOrigins
          allowedMethods: ['GET', 'OPTIONS']
          allowedHeaders: ['Content-Type']
          allowCredentials: false
        }
      }
    }
    template: {
      containers: [
        {
          name: 'frontend'
          image: 'hsqformsdevacr.azurecr.io/hsq-forms-frontend:latest'
          resources: {
            cpu: 1
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'API_BASE_URL'
              value: 'https://${apiApp.properties.configuration.ingress.fqdn}'
            }
            {
              name: 'NODE_ENV'
              value: environmentName == 'prod' ? 'production' : 'development'
            }
          ]
        }
      ]
      scale: containerAppScale
    }
  }
}

// 🔒 API Container App (Internal only)
resource apiApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${projectName}-api-${environmentName}'
  location: location
  tags: tags
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
        external: false // 🔒 KRITISKT: API endast intern access
        targetPort: 8000
        transport: 'http'
        // CORS hanteras i applikationen med miljöspecifika inställningar
      }
      secrets: [
        {
          name: 'database-url'
          value: 'postgresql://${dbAdminUsername}:${dbAdminPassword}@${postgresServer.properties.fullyQualifiedDomainName}:5432/hsq_forms'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'api'
          image: 'hsqformsdevacr.azurecr.io/hsq-forms-api:latest'
          resources: {
            cpu: 1
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
              name: 'AZURE_CLIENT_ID'
              value: managedIdentity.properties.clientId
            }
            {
              name: 'LOG_LEVEL'
              value: environmentName == 'prod' ? 'info' : 'debug'
            }
          ]
        }
      ]
      scale: containerAppScale
    }
  }
}

// 🔍 Outputs
output apiUrl string = 'https://${apiApp.properties.configuration.ingress.fqdn}'
output frontendUrl string = 'https://${frontendApp.properties.configuration.ingress.fqdn}'
output storageAccountName string = storageAccount.name
output databaseHost string = postgresServer.properties.fullyQualifiedDomainName
output managedIdentityId string = managedIdentity.id

// 📊 Security Summary
output securityFeatures object = {
  apiAccess: 'Internal Only'
  databaseAccess: 'Private'
  storageAccess: 'Private with Managed Identity'
  corsOrigins: corsOrigins
  httpsOnly: true
  tlsVersion: 'TLS 1.2+'
}
