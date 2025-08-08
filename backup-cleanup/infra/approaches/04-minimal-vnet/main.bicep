// 🚀 HSQ Forms API - MINIMAL VNet Strategy for Policy Compliance
// ============================================================================
// Strategy: Create MINIMAL VNet just for policy compliance
// Uses small address space and simple configuration

targetScope = 'resourceGroup'

// 📋 PARAMETERS
@description('Environment name (dev, test, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Project name used in resource naming')
param projectName string = 'hsq-forms'

@description('Database administrator username')
@secure()
param dbAdminUsername string

@description('Database administrator password')
@secure()
param dbAdminPassword string

@description('Storage account type')
param storageAccountType string = 'Standard_LRS'

// 🏷️ RESOURCE NAMING
var shortToken = take(uniqueString(resourceGroup().id, deployment().name), 8)
var tags = {
  Environment: environmentName
  Project: projectName
  ManagedBy: 'Bicep'
}

// 🌐 MINIMAL VNET FOR POLICY COMPLIANCE
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: '${projectName}-vnet-${environmentName}-${shortToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'  // Simple /16 network
      ]
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

// 🎯 Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${projectName}-insights-${environmentName}-${shortToken}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
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
      publicNetworkAccess: 'Enabled'  // Required for Container Apps access
    }
  }
}

// 📁 Storage Account (PRIVATE ACCESS)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${projectName}st${environmentName}${shortToken}'
  location: location
  tags: tags
  sku: {
    name: storageAccountType
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

// 📦 Container Registry (PRIVATE ACCESS)
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: '${projectName}cr${environmentName}${shortToken}'
  location: location
  tags: tags
  sku: {
    name: 'Premium'  // Required for private access
  }
  properties: {
    publicNetworkAccess: 'Disabled'  // 🔒 POLICY COMPLIANT
    adminUserEnabled: true
    networkRuleSet: {
      defaultAction: 'Deny'
    }
  }
}

// 🎭 Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${projectName}-identity-${environmentName}-${shortToken}'
  location: location
  tags: tags
}

// 🏗️ Container Apps Environment (WITH MINIMAL VNET)
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${projectName}-env-${environmentName}-${shortToken}'
  location: location
  tags: tags
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: virtualNetwork.properties.subnets[0].id
      internal: true  // 🔒 INTERNAL ACCESS ONLY - POLICY COMPLIANT
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// 🐳 Container App (PRIVATE INGRESS)
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
        external: false  // 🔒 INTERNAL INGRESS - POLICY COMPLIANT
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
      ]
      registries: [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          name: 'hsq-forms-api'
          env: [
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
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
            {
              name: 'ENVIRONMENT'
              value: environmentName
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
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

// 🔒 RBAC - AcrPull
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, managedIdentity.id, '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 📤 OUTPUTS
output containerAppEndpoint string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
output storageAccountName string = storageAccount.name
output databaseHost string = postgresServer.properties.fullyQualifiedDomainName
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
output managedIdentityClientId string = managedIdentity.properties.clientId
output virtualNetworkId string = virtualNetwork.id
output containerAppsEnvironmentId string = containerAppsEnvironment.id
