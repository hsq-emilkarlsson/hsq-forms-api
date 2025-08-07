// 🚀 HSQ Forms API - Policy-Compliant Infrastructure med Azure's officiella moduler
// Följer IT:s rekommendation: https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/app/container-app#example-4-vnet-integrated-container-app-deployment

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
var tags = {
  Environment: environmentName
  Project: projectName
  ManagedBy: 'Bicep'
  'azd-env-name': environmentName
}

// 🌐 Virtual Network med Azure's officiella modul
module vnet 'br/public:avm/res/network/virtual-network:0.7.0' = {
  name: '${uniqueString(deployment().name, location)}-vnet'
  params: {
    name: '${projectName}-vnet-${environmentName}-${resourceToken}'
    location: location
    tags: tags
    addressPrefixes: ['10.0.0.0/16']
    subnets: [
      {
        name: 'container-apps-subnet'
        addressPrefix: '10.0.1.0/23'  // Container Apps kräver minst /23
        delegations: [
          {
            name: 'Microsoft.App.environments'
            properties: {
              serviceName: 'Microsoft.App/environments'
            }
          }
        ]
      }
    ]
  }
}

// 💾 Storage Account (Policy Compliant)
module storageAccount 'br/public:avm/res/storage/storage-account:0.15.0' = {
  name: '${uniqueString(deployment().name, location)}-storage'
  params: {
    name: '${projectName}${environmentName}${resourceToken}'
    location: location
    tags: tags
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'  // Policy compliant
    blobServices: {
      containers: [
        {
          name: 'forms'
          publicAccess: 'None'
        }
        {
          name: 'uploads'
          publicAccess: 'None'
        }
      ]
    }
  }
}

// 🗄️ PostgreSQL Database med Azure's officiella modul
module postgresServer 'br/public:avm/res/db-for-postgre-sql/flexible-server:0.6.0' = {
  name: '${uniqueString(deployment().name, location)}-postgres'
  params: {
    name: '${projectName}-${environmentName}-${resourceToken}'
    location: location
    tags: tags
    skuName: 'Standard_B1ms'
    tier: 'Burstable'
    administratorLogin: dbAdminUsername
    administratorLoginPassword: dbAdminPassword
    version: '15'
    storageSizeGB: 32
    databases: [
      {
        name: 'hsq_forms'
        charset: 'UTF8'
        collation: 'en_US.UTF8'
      }
    ]
  }
}

// 🔧 Container Registry med Azure's officiella modul
module containerRegistry 'br/public:avm/res/container-registry/registry:0.6.0' = {
  name: '${uniqueString(deployment().name, location)}-acr'
  params: {
    name: '${projectName}${environmentName}acr${resourceToken}'
    location: location
    tags: tags
    skuName: 'Basic'
    adminUserEnabled: true
  }
}

// 📊 Log Analytics Workspace
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.0' = {
  name: '${uniqueString(deployment().name, location)}-logs'
  params: {
    name: '${projectName}-logs-${environmentName}-${resourceToken}'
    location: location
    tags: tags
    skuName: 'PerGB2018'
    dataRetention: 30
  }
}

// 🏗️ Container Apps Environment med Azure's officiella modul
module containerAppsEnvironment 'br/public:avm/res/app/managed-environment:0.11.0' = {
  name: '${uniqueString(deployment().name, location)}-env'
  params: {
    name: '${projectName}-env-${environmentName}-${resourceToken}'
    location: location
    tags: tags
    internal: true  // ✅ Private environment som IT krävde
    infrastructureSubnetResourceId: vnet.outputs.subnetResourceIds[0]
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
  }
}

// 🔐 Managed Identity med Azure's officiella modul  
module managedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: '${uniqueString(deployment().name, location)}-identity'
  params: {
    name: '${projectName}-identity-${environmentName}-${resourceToken}'
    location: location
    tags: tags
  }
}

// 🚀 Container App med Azure's officiella modul enligt IT:s rekommendation
module containerApp 'br/public:avm/res/app/container-app:0.17.0' = {
  name: '${uniqueString(deployment().name, location)}-app'
  params: {
    name: '${projectName}-api-${environmentName}-${resourceToken}'
    location: location
    tags: union(tags, {
      'azd-service-name': 'api'
    })
    environmentResourceId: containerAppsEnvironment.outputs.resourceId
    
    // ✅ Exakt konfiguration som IT-exemplet visar för privat endpoint
    ingressExternal: false    // ✅ Precis som IT:s exempel - INGEN publik åtkomst
    ingressTargetPort: 8000
    ingressTransport: 'http'
    ingressAllowInsecure: false
    
    // Additional port mappings enligt IT:s exempel
    additionalPortMappings: [
      {
        exposedPort: 8000
        external: false  // ✅ Även extra portar är privata
        targetPort: 8000
      }
    ]
    
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
            value: storageAccount.outputs.name
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
    
    scaleSettings: {
      minReplicas: containerAppMinReplicas
      maxReplicas: containerAppMaxReplicas
    }
    
    secrets: [
      {
        name: 'database-url'
        value: 'postgresql://${dbAdminUsername}:${dbAdminPassword}@${postgresServer.outputs.fqdn}:5432/hsq_forms'
      }
      {
        name: 'storage-account-key'
        value: storageAccount.outputs.primaryKey
      }
      {
        name: 'acr-password'
        value: containerRegistry.outputs.adminCredentials.passwords[0].value
      }
    ]
    
    managedIdentities: {
      userAssignedResourceIds: [managedIdentity.outputs.resourceId]
    }
  }
}

// 📤 Outputs
output RESOURCE_GROUP_ID string = resourceGroup().id
output AZURE_CONTAINER_APPS_ENVIRONMENT_ID string = containerAppsEnvironment.outputs.resourceId
output SERVICE_API_IDENTITY_PRINCIPAL_ID string = managedIdentity.outputs.principalId
output SERVICE_API_NAME string = containerApp.outputs.name
output SERVICE_API_URI string = 'https://${containerApp.outputs.fqdn}'  // Privat FQDN endast
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output DATABASE_HOST string = postgresServer.outputs.fqdn
output STORAGE_ACCOUNT_NAME string = storageAccount.outputs.name
output VNET_ID string = vnet.outputs.resourceId
