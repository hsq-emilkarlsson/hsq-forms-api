# HSQ Forms API - Azure App Service Deployment

Detta projekt innehåller en API för HSQ Forms-systemet med enkel deployment till Azure App Service via Azure DevOps.

## 📋 Översikt

HSQ Forms API är en applikation som gör det möjligt att:
- Hantera formulär och formulärmallar
- Hantera inskickade formulär
- Integrera med andra system via webhooks

## 🏗️ Infrastruktur

Projektet använder en enda Bicep-mall (`infra/bicep/main.bicep`) med en konfiguration som kan anpassas för olika miljöer (utveckling/produktion) via parametrar.

### Resurser som skapas:
- **App Service** - För att köra API:et som en Python-applikation
- **App Service Plan** - Beräkningsresurser för App Service
- **PostgreSQL Flexible Server** - Databas
- **Storage Account** - För att lagra filer och formulär
- **Log Analytics Workspace** - För loggning
- **Application Insights** - För övervakning
- **Managed Identity** - För säker åtkomst till Azure-resurser

### Konfigureringsalternativ:
- **environmentName**: `dev`/`prod` - Miljö som påverkar resursnamngivning
- **appServiceSku**: `B1`/`P1V2` - Storleken på App Service Plan

## 🚀 Deployment via Azure DevOps Pipeline

1. Använd pipeline-filen `azure-pipelines.yml`
2. Ställ in pipeline-variabler i Azure DevOps
3. Kör pipelinen

```yaml
# Exempel:
- task: AzureResourceManagerTemplateDeployment@3
  displayName: 'Deploy Bicep Template'
  inputs:
    deploymentScope: 'Resource Group'
    azureResourceManagerConnection: 'SCON-HAZE-01AA-APP1066-Dev-Martechlab'
    subscriptionId: '$(subscriptionId)'
    action: 'Create Or Update Resource Group'
    resourceGroupName: '$(resourceGroupName)'
    location: '$(location)'
    templateLocation: 'Linked artifact'
    csmFile: 'infra/bicep/main.bicep'
    csmParametersFile: 'infra/bicep/main.parameters.json'
    overrideParameters: '-environmentName $(environment) -projectName $(projectName) -dbAdminPassword $(dbAdminPassword) -appServiceSku $(appServiceSku)'
    deploymentMode: 'Incremental'
```

## 📝 Parametersfil

Parametersfilen (`infra/bicep/main.parameters.json`) innehåller alla nödvändiga parametrar för deployment:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "dev"
    },
    "projectName": {
      "value": "hsq-forms"
    },
    "dbAdminUsername": {
      "value": "hsqadmin"
    },
    "dbAdminPassword": {
      "value": "REPLACE_WITH_SECURE_PASSWORD_FROM_PIPELINE"
    },
    "appServiceSku": {
      "value": "B1"
    }
  }
}
```

## 🔄 Rekommenderad process

1. **Utveckling**: Använd `B1` SKU för utveckling och test
2. **Produktion**: Använd `P1V2` SKU för produktionsmiljön för bättre prestanda och tillförlitlighet

## 📦 Applikationsdistribution

Applikationskoden deployas som en zip-fil till App Service med följande innehåll:
- main.py
- src/ (applikationskod)
- alembic/ (databasmigrering)
- alembic.ini
- requirements.txt

## 🛠️ Felsökning

### Vanliga problem:

1. **Namnkonflikter**: Azure-resursnamn måste vara globalt unika. Bicep-mallen genererar ett unikt suffix för att undvika konflikter.

2. **App Service-loggning**: Använd Application Insights för detaljerad loggning och övervakning.

3. **Databasmigrering**: Kontrollera att alembic-migreringen har körts korrekt efter deployment.

4. **Python-installation**: App Service använder Python 3.11 runtime. Se till att alla paket är kompatibla.

### Användbara kommandon:

```bash
# Lista resurser i resursgruppen
az resource list --resource-group rg-hsq-forms-dev --output table

# Validera Bicep-mall
az deployment group validate --resource-group rg-hsq-forms-dev --template-file infra/main.bicep --parameters @infra/main.parameters.unified.json

# Visa loggarna för Container App
az containerapp logs show --resource-group rg-hsq-forms-dev --name hsq-forms-api-dev --follow
```
