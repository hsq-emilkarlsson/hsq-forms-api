// 🏗️ HSQ Forms API - Azure App Service Infrastructure with VNet Integration
// Skapar alla nödvändiga Azure-resurser för HSQ Forms API med App Service och VNet

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

// 🌐 Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${projectName}-vnet-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'storage-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'db-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
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
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// Storage Private Endpoint
resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${projectName}-storage-pe-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${projectName}-storage-plink-${environmentName}-${resourceToken}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    subnet: {
      id: vnet.properties.subnets[1].id
    }
  }
}

// Create the containers in the storage account
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource formUploadsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'form-uploads'
  properties: {
    publicAccess: 'None'
  }
}

resource tempUploadsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'temp-uploads'
  properties: {
    publicAccess: 'None'
  }
}

// 📊 Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${projectName}-logs-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

// 🤖 Managed Identity for App Service
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${projectName}-identity-${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

// Give Storage Blob Data Contributor role to the managed identity for the storage account
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, managedIdentity.id, 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// 🐘 PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: '${projectName}-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '15'
    administratorLogin: dbAdminUsername
    administratorLoginPassword: dbAdminPassword
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
    createMode: 'Default'
  }

  // Create the database
  resource database 'databases' = {
    name: 'hsq_forms'
  }
}

// PostgreSQL Private Endpoint
resource postgresPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${projectName}-postgres-pe-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${projectName}-postgres-plink-${environmentName}-${resourceToken}'
        properties: {
          privateLinkServiceId: postgresServer.id
          groupIds: [
            'postgresqlServer'
          ]
        }
      }
    ]
    subnet: {
      id: vnet.properties.subnets[2].id
    }
  }
}

// Private DNS Zone for PostgreSQL
resource postgresDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.postgres.database.azure.com'
  location: 'global'
  tags: tags
}

// Link DNS Zone to VNet
resource postgresDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: postgresDnsZone
  name: '${projectName}-postgres-dnslink-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// DNS Zone Group for PostgreSQL
resource postgresDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: postgresPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'postgres-dns-config'
        properties: {
          privateDnsZoneId: postgresDnsZone.id
        }
      }
    ]
  }
}

// Private DNS Zone for Blob Storage
resource storageDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

// Link DNS Zone to VNet
resource storageDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: storageDnsZone
  name: '${projectName}-storage-dnslink-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// DNS Zone Group for Storage
resource storageDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: storagePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'storage-dns-config'
        properties: {
          privateDnsZoneId: storageDnsZone.id
        }
      }
    ]
  }
}

// 🖥️ App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${projectName}-plan-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: appServiceSku
  }
  properties: {
    reserved: true // Required for Linux
  }
}

// 📱 App Service (Web App)
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: '${projectName}-api-${environmentName}-${resourceToken}'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: true
      vnetRouteAllEnabled: true
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
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: 'true'
        }
      ]
    }
    virtualNetworkSubnetId: vnet.properties.subnets[0].id
  }
}

// Set VNet integration for App Service
resource appServiceVNetConfig 'Microsoft.Web/sites/networkConfig@2022-09-01' = {
  parent: appService
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: vnet.properties.subnets[0].id
    swiftSupported: true
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
output VNET_ID string = vnet.id

// Backward compatibility
output storageAccountName string = storageAccount.name
output databaseHost string = postgresServer.properties.fullyQualifiedDomainName
output databaseName string = postgresServer::database.name
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output managedIdentityPrincipalId string = managedIdentity.properties.principalId
output managedIdentityClientId string = managedIdentity.properties.clientId
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
