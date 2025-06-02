// main.bicep - HSQ Forms Platform core infrastructure
// This Bicep file provisions the core Azure resources for the platform
// - Resource Group, Container Registry, PostgreSQL, Log Analytics, Container Apps (API, Feedback, Support)
// - Uses managed identity and secure best practices

param location string = 'westeurope'
param environment string = 'production'
param projectName string = 'hsq-forms-platform'
param acrName string = 'hsqformsacr${uniqueString(resourceGroup().id)}'
param dbName string = 'formdb'
param dbUser string = 'formuser'
param dbPassword string
param feedbackAppName string = 'hsq-feedback-form'
param supportAppName string = 'hsq-forms-support'
param apiAppName string = 'hsq-forms-api'

// Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  adminUserEnabled: false
  tags: {
    project: projectName
    environment: environment
  }
}

// PostgreSQL Flexible Server
resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: '${projectName}-db'
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: dbUser
    administratorLoginPassword: dbPassword
    version: '15'
    storage: {
      storageSizeGB: 32
    }
    highAvailability: {
      mode: 'Disabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    createMode: 'Default'
  }
  tags: {
    project: projectName
    environment: environment
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${projectName}-logs-workspace'
  location: location
  sku: {
    name: 'PerGB2018'
  }
  retentionInDays: 30
  tags: {
    project: projectName
    environment: environment
  }
}

// Container Apps Environment
resource containerEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${projectName}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
  tags: {
    project: projectName
    environment: environment
  }
}

// Feedback Form Container App
resource feedbackApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: feedbackAppName
  location: location
  properties: {
    managedEnvironmentId: containerEnv.id
    configuration: {
      registries: [
        {
          server: acr.properties.loginServer
        }
      ]
      secrets: []
      ingress: {
        external: true
        targetPort: 3001
      }
    }
    template: {
      containers: [
        {
          name: feedbackAppName
          image: '${acr.properties.loginServer}/${feedbackAppName}:latest'
          resources: {
            cpu: 0.25
            memory: '0.5Gi'
          }
        }
      ]
    }
  }
  tags: {
    project: projectName
    environment: environment
  }
}

// Support Form Container App
resource supportApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: supportAppName
  location: location
  properties: {
    managedEnvironmentId: containerEnv.id
    configuration: {
      registries: [
        {
          server: acr.properties.loginServer
        }
      ]
      secrets: []
      ingress: {
        external: true
        targetPort: 3002
      }
    }
    template: {
      containers: [
        {
          name: supportAppName
          image: '${acr.properties.loginServer}/${supportAppName}:latest'
          resources: {
            cpu: 0.25
            memory: '0.5Gi'
          }
        }
      ]
    }
  }
  tags: {
    project: projectName
    environment: environment
  }
}

// API Backend Container App
resource apiApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: apiAppName
  location: location
  properties: {
    managedEnvironmentId: containerEnv.id
    configuration: {
      registries: [
        {
          server: acr.properties.loginServer
        }
      ]
      secrets: []
      ingress: {
        external: true
        targetPort: 8000
      }
    }
    template: {
      containers: [
        {
          name: apiAppName
          image: '${acr.properties.loginServer}/${apiAppName}:latest'
          resources: {
            cpu: 0.5
            memory: '1Gi'
          }
        }
      ]
    }
  }
  tags: {
    project: projectName
    environment: environment
  }
}
