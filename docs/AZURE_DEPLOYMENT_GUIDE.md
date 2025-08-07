# 🚀 HSQ Forms API – Azure Deployment Guide

Senast uppdaterad: 2025-08-07

## 📋 Översikt

Denna guide visar hur du deployar HSQ Forms API till Azure med en VNet-integrerad approach:

- **Azure Container Apps** - för API hosting med autoscaling och VNet-integration
- **Azure Database for PostgreSQL Flexible Server** - för databas
- **Azure Blob Storage** - för filuppladdningar
- **Azure Container Registry** - för Docker images
- **Azure Log Analytics** - för monitorering och logging
- **Azure Virtual Network** - för nätverkssäkerhet (obligatoriskt enligt policy)

## 🏗️ Arkitektur

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────────┐ │
│  │   Container     │  │   PostgreSQL     │  │   Storage       │ │
│  │     Apps        │  │   Flexible       │  │   Account       │ │
│  │   Environment   │  │     Server       │  │                 │ │
│  │                 │  │                  │  │  ┌───────────┐  │ │
│  │  ┌───────────┐  │  │  Database:       │  │  │ Blob      │  │ │
│  │  │ HSQ Forms │◄─┼──┼─► hsq_forms     │  │  │ Container │  │ │
│  │  │    API    │  │  │                  │  │  │ uploads   │  │ │
│  │  └─────┬─────┘  │  │                  │  │  └───────────┘  │ │
│  │        │        │  │                  │  │                 │ │
│  │  ┌─────▼─────┐  │  │                  │  │                 │ │
│  │  │ Managed   │  │  │                  │  │                 │ │
│  │  │ Identity  │──┼──┼──────────────────┼──┼─► Authentication│ │
│  │  └───────────┘  │  │                  │  │                 │ │
│  └─────────────────┘  └──────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 🛠️ Förutsättningar

Innan du börjar, se till att du har:

1. **Azure DevOps** konfigurerat med ditt projekt
2. **Service Connection** till Azure i Azure DevOps
3. **Git Repository** för projektet

## 🚀 Deployment med Azure DevOps

### Steg 1: Konfigurera Azure DevOps Pipeline

1. Öppna ditt projekt i Azure DevOps
2. Gå till Pipelines > Pipelines
3. Skapa en ny pipeline eller redigera en befintlig
4. Använd YAML-filen `azure-pipelines.yml` från ditt repository

### Steg 2: Konfigurera pipeline-variabler

Ställ in följande variabler i Azure DevOps:

- `subscriptionId`: Azure-prenumerationens ID
- `resourceGroupName`: Resursgruppens namn (t.ex. "rg-hsq-forms-dev")
- `environment`: Miljönamn ("dev" eller "prod")
- `projectName`: Projektets namn (t.ex. "hsq-forms")
- `dbAdminPassword`: Lösenord för databasadministratör (som Secret)
- `enableVNet`: Alltid "true" för att aktivera VNet-integration enligt Azure Policy

### Steg 3: Säkerställ rätt behörigheter

För att kunna deploya med VNet-integration krävs att Azure DevOps serviceprincipal har följande behörigheter:

1. `Network Contributor` på resursgruppen
2. `Microsoft.Network/virtualNetworks/*`
3. `Microsoft.Network/virtualNetworks/subnets/*`

Detta kan behöva konfigureras av en Azure-administratör genom att tilldela rätt roller till serviceprincipal.

### Steg 4: Verifiera deployment

När pipelinen är klar, kontrollera:

1. Alla resurser har skapats i Azure Portal
2. Container App är igång och fungerar
3. API-endpoints är tillgängliga

## 📊 Monitorering och logs

### Azure Container Apps logs

```bash
# Visa live logs för API
az containerapp logs show \
  --resource-group rg-hsq-forms-dev \
  --name hsq-forms-api-dev \
  --follow
```

## 🛡️ Säkerhetskonfiguration

### VNet-integration

För ökad säkerhet, använd VNet-integration i produktionsmiljön:

1. Ställ in `enableVNet=true` i pipeline-variablerna
2. Se till att du har behörighet som Network Contributor

## 🔄 Rekommenderad process

1. **Utveckling**: Använd alltid VNet-integration enligt Azure Security Policy
2. **Produktion**: Använd alltid VNet-integration för produktionsmiljön

## 📝 Felsökning

### Vanliga problem:

1. **Namnkonflikter**: Azure-resursnamn måste vara globalt unika. Bicep-mallen genererar ett unikt suffix för att undvika konflikter.

2. **VNet-behörigheter**: Om du får "AuthorizationFailed" för VNet-relaterade operationer, följ dessa steg:
   - Kontrollera att serviceprincipal har rätt behörigheter (Network Contributor)
   - Be Azure-administratör lägga till behörigheter för Microsoft.Network/virtualNetworks/* och Microsoft.Network/virtualNetworks/subnets/*
   - Se till att serviceprincipal har dessa behörigheter på resursgruppsnivå

3. **Container App åtkomst**: Container App är konfigurerad som intern (internal) enligt Azure Policy. För att komma åt API:et behöver du:
   - Konfigurera VNet peering till ditt utvecklarnätverk
   - Använda Azure Application Gateway eller Private Link
   - Sätta upp en bastion-host inom samma VNet

### Användbara kommandon:

```bash
# Lista resurser i resursgruppen
az resource list --resource-group rg-hsq-forms-dev --output table

# Validera Bicep-mall
az deployment group validate --resource-group rg-hsq-forms-dev --template-file infra/main.bicep --parameters @infra/main.parameters.unified.json

# Visa loggarna för Container App
az containerapp logs show --resource-group rg-hsq-forms-dev --name hsq-forms-api-dev --follow
```

---

## 📚 Ytterligare resurser

- [Azure Container Apps dokumentation](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Bicep dokumentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure DevOps Pipelines](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
- [Azure PostgreSQL Flexible Server](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/)

**Senast uppdaterad:** 2025-08-07  **Nästa review:** 2026-08-07
