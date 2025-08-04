# Azure OIDC Federated Credentials Setup Guide

## Problem
Du har problem med GitHub Actions deployment till ACR eftersom federated credentials har fel konfiguration. Det nuvarande matchningsuttrycket `repo:hsq-emilkarlsson/hsq-emilkarlsson-hsq-forms` matchar inte det faktiska repository-namnet `hsq-forms-api`.

## Lösning: Konfigurera OIDC Federated Credentials

### Steg 1: Uppdatera Federated Credentials i Azure

1. **Gå till Azure Portal** och navigera till din App Registration
2. **Gå till "Certificates & secrets"** > **"Federated credentials"**
3. **Redigera eller skapa nya federated credentials** med följande konfiguration:

#### För Develop Branch (Dev Environment)
- **Namn**: `github-actions-develop`
- **Beskrivning**: `Federated credential for GitHub Actions deploy from develop branch to dev environment`
- **Issuer**: `https://token.actions.githubusercontent.com`
- **Subject identifier**: `repo:hsq-emilkarlsson/hsq-forms-api:ref:refs/heads/develop`
- **Audience**: `api://AzureADTokenExchange`

#### För Main Branch (Production Environment)
- **Namn**: `github-actions-main`
- **Beskrivning**: `Federated credential for GitHub Actions deploy from main branch to production environment`
- **Issuer**: `https://token.actions.githubusercontent.com`
- **Subject identifier**: `repo:hsq-emilkarlsson/hsq-forms-api:ref:refs/heads/main`
- **Audience**: `api://AzureADTokenExchange`

#### För Tags (Production Releases)
- **Namn**: `github-actions-tags`
- **Beskrivning**: `Federated credential for GitHub Actions deploy from tags to production environment`
- **Issuer**: `https://token.actions.githubusercontent.com`
- **Subject identifier**: `repo:hsq-emilkarlsson/hsq-forms-api:ref:refs/tags/*`
- **Audience**: `api://AzureADTokenExchange`

#### För Pull Requests
- **Namn**: `github-actions-pr`
- **Beskrivning**: `Federated credential for GitHub Actions on pull requests`
- **Issuer**: `https://token.actions.githubusercontent.com`
- **Subject identifier**: `repo:hsq-emilkarlsson/hsq-forms-api:pull_request`
- **Audience**: `api://AzureADTokenExchange`

### Steg 2: Uppdatera GitHub Secrets

Se till att följande secrets är konfigurerade i ditt GitHub repository:

1. **Gå till GitHub repository** → **Settings** → **Secrets and variables** → **Actions**
2. **Lägg till eller uppdatera följande secrets**:

```
AZURE_CLIENT_ID: [Din App Registration Client ID]
AZURE_TENANT_ID: [Din Azure Tenant ID]
```

**VIKTIGT**: Ta bort `AZURE_CLIENT_SECRET` och `AZURE_CREDENTIALS` secrets om de finns, eftersom OIDC inte använder hemligheter.

### Steg 3: Verifiera App Registration Permissions

Se till att din App Registration har följande permissions:

#### API Permissions
- **Azure Container Registry**: `pull`, `push`
- **Azure Resource Manager**: `Contributor` eller `Reader` + specifika roller för Container Apps

#### Azure RBAC Roles (på subscription/resource group level)
- **AcrPush** - för att pusha till ACR
- **Contributor** - för att uppdatera Container Apps
- **Reader** - för att läsa resurser

### Steg 4: Testa Deployment

1. **Commit och push** ändringarna till `develop` branch
2. **Kontrollera GitHub Actions** logs för att se om OIDC authentication fungerar
3. **Kolla Azure Portal** för att verifiera att images pushas till ACR

## Felsökning

### Om du fortfarande får fel:

1. **Kontrollera Subject Identifier**: Se till att det exakt matchar `repo:hsq-emilkarlsson/hsq-forms-api:ref:refs/heads/develop`
2. **Kontrollera Audience**: Måste vara `api://AzureADTokenExchange`
3. **Kontrollera Permissions**: Se till att App Registration har rätt roller
4. **Kontrollera Client ID**: Se till att `AZURE_CLIENT_ID` secret matchar din App Registration

### Vanliga fel och lösningar:

- **"AADSTS70021: No matching federated identity record found"** → Kontrollera subject identifier
- **"The request signature is invalid"** → Kontrollera audience värdet
- **"Access denied"** → Kontrollera RBAC permissions

## Fördelar med OIDC

- ✅ Ingen hemligheter som kan läcka
- ✅ Automatisk token rotation
- ✅ Mer säker än service principal secrets
- ✅ Granulär kontroll per branch/tag/PR
- ✅ Rekommenderas av Microsoft

## Kommandoexempel för att skapa Federated Credentials via CLI

```bash
# För develop branch
az ad app federated-credential create \
  --id <APP_REGISTRATION_ID> \
  --parameters '{
    "name": "github-actions-develop",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:hsq-emilkarlsson/hsq-forms-api:ref:refs/heads/develop",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# För main branch
az ad app federated-credential create \
  --id <APP_REGISTRATION_ID> \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:hsq-emilkarlsson/hsq-forms-api:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# För tags
az ad app federated-credential create \
  --id <APP_REGISTRATION_ID> \
  --parameters '{
    "name": "github-actions-tags",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:hsq-emilkarlsson/hsq-forms-api:ref:refs/tags/*",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

Ersätt `<APP_REGISTRATION_ID>` med din faktiska App Registration Object ID.
