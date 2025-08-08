# HSQ Forms API - Azure App Service Deployment

Detta projekt innehåller en API för HSQ Forms-systemet med enkel deployment till Azure App Service via Azure DevOps.

> **Status:** Projektet är genomgått och förberett för deployment (2025-08-08)

## 📋 Översikt

HSQ Forms API är en applikation som gör det möjligt att:
- Hantera formulär och formulärmallar
- Hantera inskickade formulär
- Integrera med andra system via webhooks

## 🏗️ Infrastruktur

Infrastrukturen för projektet är redan uppsatt manuellt i Azure. Azure DevOps-pipelinen validerar att resurserna finns men skapar inga nya resurser.

### Befintliga resurser:
- **App Service (hsq-forms-api-dev)** - Kör API:et som en Python-applikation
- **App Service Plan (sq-forms-plan-dev)** - Beräkningsresurser för App Service
- **PostgreSQL Flexible Server (hsq-forms-db-dev)** - Databas
- **Storage Account (hsqformsdev)** - För att lagra filer och formulär
- **Log Analytics Workspace (hsq-forms-logs-dev)** - För loggning
- **Application Insights (sq-forms-insights-dev)** - För övervakning
- **Managed Identity (hsq-forms-identity-dev)** - För säker åtkomst till Azure-resurser
- **VNet (hsq-forms-vnet-dev)** - Virtuellt nätverk för säker kommunikation
- **Private Endpoints** - För säker åtkomst till PostgreSQL och Storage

### Konfigureringsalternativ:
- **environmentName**: `dev`/`prod` - Miljö som påverkar resursnamngivning
- **appServiceSku**: `B1`/`P1V2` - Storleken på App Service Plan

## 📑 Formulär och Web Apps

Projektet innehåller både ett backend-API och formulär som kan distribueras som webbapplikationer:

### API-delen
API-delen är det centrala i projektet och körs på Azure App Service. Detta är det vi distribuerar först för att hantera formulärdata.

### Formulärdelen
Formulären finns i `forms/`-mappen och är organiserade som separata applikationer:

- `hsq-forms-container-b2b-feedback/` - B2B Feedback-formulär
- `hsq-forms-container-b2b-returns/` - B2B Returformulär 
- `hsq-forms-container-b2b-support/` - B2B Support-formulär
- `hsq-forms-container-b2c-returns/` - B2C Returformulär

Dessa formulär kan i framtiden distribueras som separata Static Web Apps eller Web Apps beroende på behov.

### Framtida distributionsplan
- **Steg 1**: Distribuera API:et (aktuellt fokus)
- **Steg 2**: Distribuera formulären som Static Web Apps
- **Steg 3**: Konfigurera CI/CD för automatiska uppdateringar av formulär

## 🧪 Testning av Azure-anslutningar

Projektet innehåller skript för att testa anslutningen till Azure-resurser:

### Testning i Azure DevOps Pipeline

Testningen av Azure-anslutningar är integrerad i deploy-pipelinen och körs automatiskt efter att applikationen har distribuerats. Detta säkerställer att:

1. Anslutningen till Azure Storage fungerar
2. Anslutningen till PostgreSQL-databasen fungerar
3. Managed Identity har rätt behörigheter

### Lokal testning

För att testa Azure-anslutningar lokalt behöver du följande miljövariabler:

```bash
# Azure Storage
export AZURE_STORAGE_ACCOUNT_NAME="hsq-forms-dev-XXXXXXXX"  # Ditt storage-kontonamn
export AZURE_CLIENT_ID="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"  # Client ID för Managed Identity
export AZURE_STORAGE_CONTAINER_NAME="form-uploads"
export AZURE_STORAGE_TEMP_CONTAINER_NAME="temp-uploads"

# PostgreSQL
export SQLALCHEMY_DATABASE_URI="postgresql://hsqadmin:PASSWORD@hsq-forms-dev-XXXXXXXX.postgres.database.azure.com:5432/hsq_forms"
```

Kör sedan testskriptet:

```bash
python scripts/test-azure-connection.py
```

**OBS!** Normalt sett behöver du inte köra dessa tester lokalt, eftersom de körs automatiskt i pipelinen.

## 📋 Testa deployad miljö

När du har skapat infrastrukturen manuellt i Azure Portal eller via Azure DevOps, bör du testa följande för att verifiera att miljön fungerar korrekt:

1. **Anslutning till App Service**:
   - Besök App Service URL: `https://hsq-forms-api-dev.azurewebsites.net/`
   - Du bör se en välkomstsida eller API-dokumentation

2. **Testa API-endpoints**:
   - Test health check: `https://hsq-forms-api-dev.azurewebsites.net/api/health`
   - Testa formulärlistning: `https://hsq-forms-api-dev.azurewebsites.net/api/forms`

3. **Verifiera databas och storage**:
   - Via Azure Portal, kontrollera att PostgreSQL-servern är online
   - Kontrollera att Storage Account har behållarna `form-uploads` och `temp-uploads`

4. **Kontrollera loggning**:
   - Via Azure Portal, gå till Application Insights och kontrollera att data strömmas in

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
```

## 📝 Parametersfil

Parametersfilen (`infra/main.parameters.unified.json`) innehåller alla nödvändiga parametrar för deployment:

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
    "containerAppMinReplicas": {
      "value": 1
    },
    "containerAppMaxReplicas": {
      "value": 3
    },
    "enableVNet": {
      "value": false
    }
  }
}
```

## 🔄 Rekommenderad process

1. **Utveckling**: Använd alltid VNet-integration (`enableVNet=true`) enligt Azure Security Policy
2. **Produktion**: Använd alltid VNet-integration (`enableVNet=true`) för produktionsmiljön

## 🛠️ Felsökning

### Vanliga problem:

1. **Namnkonflikter**: Azure-resursnamn måste vara globalt unika. Bicep-mallen genererar ett unikt suffix för att undvika konflikter.

2. **VNet-behörigheter**: Om du får "AuthorizationFailed" när VNet är aktiverat, kontrollera att serviceprincipal har rätt behörigheter (Network Contributor).

3. **Container App åtkomst**: Container App är konfigurerad som intern (internal) enligt Azure Policy. Använd VNet peering eller private endpoints för att få åtkomst.

### Användbara kommandon:

```bash
# Lista resurser i resursgruppen
az resource list --resource-group rg-hsq-forms-dev --output table

# Validera Bicep-mall
az deployment group validate --resource-group rg-hsq-forms-dev --template-file infra/main.bicep --parameters @infra/main.parameters.unified.json

# Visa loggarna för Container App
az containerapp logs show --resource-group rg-hsq-forms-dev --name hsq-forms-api-dev --follow
```
