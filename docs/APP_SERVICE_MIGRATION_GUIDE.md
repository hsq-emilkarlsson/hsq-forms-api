# Azure App Service Migration Guide

## Översikt

Detta dokument beskriver migreringen från Azure Container Apps till Azure App Service för HSQ Forms API.

## Varför migrera till App Service?

- **Enkelhet**: App Service ger en mer hanterbar miljö för Python-applikationer utan containerkomplexitet
- **Kostnad**: App Service erbjuder bra pris/prestanda för denna typ av applikation
- **Integration**: Enklare integration med Azure-tjänster utan behov av VNet-konfiguration
- **Skalbarhet**: Automatisk skalning finns tillgänglig vid behov
- **Säkerhet**: App Service ger bra säkerhetsfunktioner utan VNet-komplexitet
- **CI/CD**: Stöder direkt deployment från Azure DevOps pipeline

## Migreringssteg

1. **Infrastruktur**: Ny Bicep-mall `infra/main-appservice.bicep` har skapats
2. **Pipeline**: Azure Pipeline har uppdaterats för App Service-deployment
3. **Parametrar**: Nya parameterfiler `infra/main-appservice.parameters.json`
4. **Konfiguration**: App-inställningar har anpassats för App Service Python-runtime

## Resursjämförelse

| Container Apps | App Service |
|---------------|-------------|
| Container Registry | Inte nödvändig |
| Container App Environment | App Service Plan |
| Container App | Web App |
| VNet integration | Valfri |
| Managed Identity | Managed Identity |
| PostgreSQL Flexible Server | PostgreSQL Flexible Server |
| Storage Account | Storage Account |

## Deployment Process

1. Skapa infrastruktur via Bicep-mall
2. Zippa och ladda upp applikationskod
3. Konfigurera app-inställningar
4. Kör databasmigrering
5. Verifiera deployment

## Konfiguration

App Service konfigureras för att köra Python 3.11 med följande inställningar:

```
SQLALCHEMY_DATABASE_URI=postgresql://<username>:<password>@<server>.postgres.database.azure.com:5432/hsq_forms
ENVIRONMENT=dev/prod
AZURE_STORAGE_ACCOUNT_NAME=<storage-account-name>
AZURE_STORAGE_CONTAINER_NAME=form-uploads
AZURE_STORAGE_TEMP_CONTAINER_NAME=temp-uploads
AZURE_CLIENT_ID=<managed-identity-client-id>
STARTUP_COMMAND=gunicorn main:app --workers 2 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

## Rollback-plan

Om problem uppstår med App Service kan vi återgå till Container Apps genom att:

1. Återställa tidigare pipeline
2. Köra Container Apps-deployment igen
3. Uppdatera DNS-pekare till Container App
