# 🚀 HSQ Forms API - Deployment Checklist

## 🎯 Mål: Första deployment + Löpande releases

Den här guiden täcker allt som behövs för att få igång första deployment och sedan kunna släppa nya versioner löpande.

## ⚠️ Status: Pipeline Failed - ACR Login Problem

**Problem**: Pipeline failar på "Login to Azure Container Registry"
**Orsak**: Service connections behöver konfigureras för nya ACR-namn

## 📋 Deployment Checklist

### 🔧 **STEG 1: Azure DevOps Konfiguration** (Krävs först)

#### 1.1 Service Connections
Du behöver skapa/uppdatera service connections i Azure DevOps:

```bash
# I Azure DevOps project settings > Service connections
1. Skapa/uppdatera: "AzureServiceConnection-dev"
   - Subscription: c0b03b12-570f-4442-b337-c9175ad4037f
   - Resource Group: rg-hsq-forms-dev
   
2. Skapa/uppdatera: "AzureServiceConnection-prod"  
   - Subscription: HAZE-00B9-APP1066-PROD-Martech-SharedServices
   - Resource Group: rg-hsq-forms-prod
```

#### 1.2 Container Registry Service Connections
```bash
# Nya ACR service connections
1. "hsqformsdevacr"
   - Registry: hsqformsdevacr.azurecr.io
   - Service Principal authentication
   
2. "hsqformsprodacr" 
   - Registry: hsqformsprodacr.azurecr.io
   - Service Principal authentication
```

#### 1.3 Pipeline Variables (Secrets)
```bash
# I Azure DevOps pipeline > Variables
1. DB_ADMIN_PASSWORD (secret) - PostgreSQL admin password
2. FRONTEND_URL (optional) - Specific frontend URLs for CORS
```

### 🏗️ **STEG 2: Azure Resources** (Automatiskt via pipeline)

#### 2.1 Resource Groups
```bash
# Skapas automatiskt av pipeline
- rg-hsq-forms-dev (West Europe)
- rg-hsq-forms-prod (West Europe)
```

#### 2.2 Infrastructure Components
Bicep template deployar automatiskt:
- ✅ PostgreSQL Flexible Server (privat networking)
- ✅ Azure Container Registry (hsqformsdevacr/hsqformsprodacr)
- ✅ Container Apps Environment
- ✅ Storage Account (privata containers)
- ✅ Log Analytics Workspace
- ✅ Application Insights

### 🐳 **STEG 3: Container App Configuration**

#### 3.1 Environment Variables (Automatic via Bicep)
```bash
# Sätts automatiskt av infrastructure deployment
DATABASE_URL=postgresql://...
AZURE_STORAGE_CONNECTION_STRING=...
APP_ENVIRONMENT=dev/prod
```

#### 3.2 Säkerhetsinställningar (Implementerat)
```bash
✅ CORS: Miljöspecifika domäner
✅ Rate Limiting: Implementerat på alla endpoints
✅ API Docs: Endast i development
✅ Internal Ingress: API endast intern access
```

## 🚀 **DEPLOYMENT WORKFLOW**

### Första Deployment (DEV)
```bash
1. Konfigurera service connections (se STEG 1)
2. Push till develop branch
3. Pipeline kör automatiskt:
   ✅ Test → Infrastructure → Build → Deploy
```

### Löpande Releases

#### Development (develop branch)
```bash
# Automatisk deployment vid varje push till develop
git checkout develop
git add .
git commit -m "feat: ny funktionalitet"
git push origin develop

# Pipeline kör automatiskt: Test → Build → Deploy to DEV
```

#### Production (main branch)
```bash
# Deployment via merge till main
git checkout main
git merge develop
git push origin main

# Pipeline kör automatiskt: Test → Build → Deploy to PROD
```

## 🔍 **NUVARANDE PIPELINE STATUS**

### ✅ Fungerande Steg
- Test stage: ✅ PASS (55s)
- Infrastructure stage: Väntar på service connections

### ❌ Misslyckande Steg  
- Build & Deploy: ❌ FAIL (ACR login)

**Nästa Action**: Konfigurera service connections

## 📝 **Service Connection Setup Guide**

### I Azure DevOps Portal:

1. **Gå till Project Settings**
   ```
   https://dev.azure.com/{organization}/{project}/_settings/adminservices
   ```

2. **Create Service Connection**
   ```bash
   Type: Azure Resource Manager
   Authentication: Service Principal (automatic)
   Scope: Subscription
   ```

3. **Konfigurera för DEV:**
   ```yaml
   Connection name: AzureServiceConnection-dev
   Subscription: c0b03b12-570f-4442-b337-c9175ad4037f
   Resource Group: rg-hsq-forms-dev
   ```

4. **Konfigurera för PROD:**
   ```yaml
   Connection name: AzureServiceConnection-prod  
   Subscription: HAZE-00B9-APP1066-PROD-Martech-SharedServices
   Resource Group: rg-hsq-forms-prod
   ```

5. **Container Registry Connections:**
   ```yaml
   # DEV ACR
   Type: Docker Registry
   Registry: hsqformsdevacr.azurecr.io
   Name: hsqformsdevacr
   
   # PROD ACR  
   Type: Docker Registry
   Registry: hsqformsprodacr.azurecr.io
   Name: hsqformsprodacr
   ```

## 🎯 **Efter Första Deployment**

### Verifiera API
```bash
# DEV
curl https://{container-app-url}/health
curl https://{container-app-url}/api/templates

# Kontrollera säkerhet
curl https://{container-app-url}/docs  # Ska fungera i DEV
```

### Monitorering
```bash
# I Azure Portal
1. Container Apps → hsq-forms-api-dev
2. Application Insights → Request telemetry
3. Log Analytics → Container logs
```

## 🔄 **Continuous Deployment Workflow**

### Daglig Development Cycle
```bash
1. Gör ändringar lokalt
2. Testa lokalt: python3 test_security_config.py
3. Commit & push till develop
4. Pipeline deployar automatiskt till DEV
5. Testa i DEV environment
6. Merge till main för PROD deployment
```

### Feature Branches (Rekommenderat)
```bash
# Skapa feature branch
git checkout -b feature/new-form-template
git push origin feature/new-form-template

# PR → develop → automatisk DEV deployment
# PR → main → automatisk PROD deployment
```

## ⚡ **IMMEDIATE NEXT STEPS**

### Idag (För första deployment):
1. **Konfigurera service connections** (15-30 min)
2. **Sätt pipeline variables** (5 min)
3. **Trigger pipeline igen** (git push)
4. **Verifiera deployment** (15 min)

### Denna vecka:
1. **Testa API endpoints** i DEV
2. **Konfigurera frontend forms** integration
3. **Production deployment** (merge till main)

---

**🎉 RESULTAT**: Efter dessa steg har du en fungerande CI/CD pipeline för löpande deployments!
