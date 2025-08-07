# Azure App Service Deployment Guide

Detta dokument beskriver hur man deployar HSQ Forms API till Azure App Service.

## Förutsättningar

- Azure subscription
- Azure DevOps projekt med rätt behörigheter
- Service Connection i Azure DevOps med rätt behörigheter

## Deployment-processen

HSQ Forms API deployas till Azure App Service med hjälp av Azure DevOps Pipeline. Processen består av tre huvudsteg:

1. **Bygga och testa applikationen**
2. **Deploya infrastrukturen med Bicep**
3. **Deploya applikationskoden till App Service**

## Resurser som skapas

- **Resource Group**: Innehåller alla resurser för miljön
- **App Service Plan**: Linux-plan för att köra applikationen
- **App Service**: Web App för att köra FastAPI-applikationen
- **PostgreSQL Flexible Server**: Databas för att lagra formulärdata
- **Storage Account**: För att lagra formulärbilagor
- **Application Insights**: För övervakning och loggning
- **Log Analytics**: För centraliserad logganalys
- **Managed Identity**: För säker åtkomst till Azure-resurser

## Miljöer

HSQ Forms API stödjer två miljöer:

- **Development (dev)**: För testning och utveckling
- **Production (prod)**: För produktionsanvändning

## Deployment-steg

### 1. Skapa infrastrukturen

Infrastrukturen skapas med Bicep-mallen `infra/main-appservice.bicep`. Parametrar konfigureras i `infra/main-appservice.parameters.json`.

```bash
az deployment group create \
  --resource-group <resource-group-name> \
  --template-file infra/main-appservice.bicep \
  --parameters infra/main-appservice.parameters.json \
  --parameters environmentName=<environment> \
  --parameters dbAdminPassword=<secure-password>
```

### 2. Deploya applikationen

Applikationen deployas som en zip-fil till App Service. Zipfilen innehåller:

- main.py
- src/ (applikationskod)
- alembic/ (databasmigrering)
- alembic.ini
- requirements.txt

```bash
# Skapa zip-fil
zip -r app.zip main.py src/ alembic/ alembic.ini requirements.txt

# Deploya till App Service
az webapp deploy \
  --resource-group <resource-group-name> \
  --name <app-service-name> \
  --src-path app.zip \
  --type zip
```

### 3. Kör databasmigrering

Efter deployment behöver databasmigreringen köras:

```bash
# Hämta connection string
CONNECTIONSTRING=$(az webapp config appsettings list \
  --resource-group <resource-group-name> \
  --name <app-service-name> \
  --query "[?name=='SQLALCHEMY_DATABASE_URI'].value" -o tsv)

# Kör migrering
export SQLALCHEMY_DATABASE_URI=$CONNECTIONSTRING
python -m alembic upgrade head
```

## Övervakning

- Application Insights används för att övervaka applikationen
- Log Analytics används för att analysera loggar
- Azure Portal ger en översikt över resursanvändning

## Felsökning

### Problem med deployment

Kontrollera loggar i Azure DevOps Pipeline.

### App Service-problem

1. Kontrollera App Service-loggar i Azure Portal
2. Använd Kudu-konsolen för att inspektera filer och processer

```bash
# Strömma loggar från App Service
az webapp log tail --name <app-service-name> --resource-group <resource-group-name>
```

### Databasfrågor

Kontrollera att databasmigreringen har körts korrekt:

```bash
# Kontrollera status för alembic
export SQLALCHEMY_DATABASE_URI=$CONNECTIONSTRING
python -m alembic current
```
