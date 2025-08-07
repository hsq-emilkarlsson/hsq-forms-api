# 🏗️ Infrastructure - HSQ Forms API

## 📋 Översikt
Denna katalog innehåller en Bicep-mall för att deploya HSQ Forms API till Azure.

## 🎯 Arkitektur

### Resurser som skapas
- **Container Apps Environment** - Hosting-plattform
- **Container App** - Applikationskörning
- **PostgreSQL Flexible Server** - Databas
- **Storage Account** - Filuppladdningar och temporär lagring
- **Log Analytics Workspace** - Övervakning och loggning
- **Container Registry** - Docker image-lagring
- **Virtual Network** - Nätverkssäkerhet (obligatoriskt enligt Azure Policy)

## 📁 Filstruktur

- `main.bicep` - Huvudmall för deployment
- `main.parameters.unified.json` - Parameterfil för alla miljöer

## 🚀 Användning

Mallen används via Azure DevOps pipeline (`azure-pipelines.yml`) med parametrar som styr deployment:

```yaml
- task: AzureResourceManagerTemplateDeployment@3
  displayName: 'Deploy Bicep Template'
  inputs:
    deploymentScope: 'Resource Group'
    azureResourceManagerConnection: '$(azureServiceConnection)'
    subscriptionId: '$(subscriptionId)'
    action: 'Create Or Update Resource Group'
    resourceGroupName: '$(resourceGroupName)'
    location: 'West Europe'
    templateLocation: 'Linked artifact'
    csmFile: 'infra/main.bicep'
    csmParametersFile: 'infra/main.parameters.unified.json'
    overrideParameters: '-environmentName $(environment) -projectName $(projectName) -dbAdminPassword $(dbAdminPassword) -enableVNet $(enableVNet)'
```

## ⚙️ Konfiguration

Följande parametrar kan konfigureras:

| Parameter | Beskrivning | Standardvärde |
|-----------|-------------|---------------|
| `environmentName` | Miljönamn (dev/prod) | dev |
| `projectName` | Projektnamn för resurser | hsq-forms |
| `enableVNet` | Aktivera VNet-integration | true |

## 🔒 VNet-Integration (viktigt!)

### Azure Policy krav
Enligt Azure Policy "deny-paas-public-dev" måste Container Apps använda VNet-integration och inte exponeras publikt. Vår mall är konfigurerad för att:

1. Skapa ett VNet med en dedikerad subnet för Container Apps
2. Konfigurera Container Apps Environment som `internal: true` för att följa policyn
3. Konfigurera Container App med `external: false` och `transport: 'tcp'` för säker åtkomst

### Behörigheter som krävs
För att kunna deploya med VNet-integration krävs att Azure DevOps serviceprincipal har:

- `Network Contributor` på resursgruppen
- Behörighet för `Microsoft.Network/virtualNetworks/*`
- Behörighet för `Microsoft.Network/virtualNetworks/subnets/*`

### Att tänka på vid deployment
- Serviceprincipal behöver ha dessa behörigheter innan deployment
- Efter deployment behöver du konfigurera nätverksåtkomst via VNet peering eller Private Link
| `dbAdminUsername` | Databasadministratörsnamn | hsqadmin |
| `dbAdminPassword` | Databasadministratörslösenord | - |
| `containerAppMinReplicas` | Minimalt antal repliker | 1 |
| `containerAppMaxReplicas` | Maximalt antal repliker | 3 |

Se `main.parameters.unified.json` för alla tillgängliga parametrar.
