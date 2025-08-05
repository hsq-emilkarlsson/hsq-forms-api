# 🚀 Azure DevOps Quickstart - HSQ Forms API

## 🎯 Mål: Få igång allt via Azure DevOps steg för steg

### 📋 **STEG 1: Azure DevOps Setup**

#### 1.1 Skapa Project (Om inte redan gjort)
```
1. Gå till: https://dev.azure.com/
2. Klicka "New project"
3. Name: hsq-forms-api
4. Visibility: Private
5. Klicka "Create"
```

#### 1.2 Koppla GitHub Repository
```
1. Gå till: Pipelines → Pipelines
2. Klicka "Create Pipeline"
3. Välj "GitHub"
4. Välj repository: hsq-emilkarlsson/hsq-forms-api
5. Välj "Existing Azure Pipelines YAML file"
6. Branch: develop
7. Path: /azure-pipelines.yml
8. Klicka "Continue"
```

### 📋 **STEG 2: Service Connection (Viktigast!)**

#### 2.1 Skapa Azure Service Connection
```
1. Gå till: Project Settings → Service connections
2. Klicka "New service connection"
3. Välj "Azure Resource Manager"
4. Authentication method: Service principal (automatic)
5. Scope level: Subscription
6. Subscription: c0b03b12-570f-4442-b337-c9175ad4037f
7. Service connection name: Azure subscription 1
8. Grant access permission to all pipelines: ✓
9. Klicka "Save"
```

**OBS:** Detta är den viktigaste delen! Utan denna kommer pipeline inte kunna skapa Azure resources.

### 📋 **STEG 3: Pipeline Variables**

#### 3.1 Lägg till Secrets
```
1. Gå till: Pipelines → {din pipeline}
2. Klicka "Edit"
3. Klicka "Variables"
4. Lägg till:
   - Name: DB_ADMIN_PASSWORD
   - Value: [Generera säkert lösenord]
   - Keep this value secret: ✓
```

**Generera säkert lösenord:**
```bash
# Kör detta i terminal för säkert lösenord
openssl rand -base64 32
```

### 📋 **STEG 4: Testa Pipeline**

#### 4.1 Första körningen
```
1. Gå till pipeline
2. Klicka "Run pipeline"
3. Branch: develop
4. Klicka "Run"
```

#### 4.2 Förväntat resultat
```
✅ Test Stage (1-2 min) - Kör Python tests
🔄 Infrastructure Stage (3-5 min) - Skapar Azure resources:
   - Resource Group: rg-hsq-forms-dev
   - Container Registry: hsqformsdevacr.azurecr.io
   - PostgreSQL Database
   - Storage Account
   - Container Apps Environment
✅ Deploy Stage - Visar nästa steg
```

### 📋 **STEG 5: Verifiera Deployment**

#### 5.1 Kolla Azure Portal
```
1. Gå till: https://portal.azure.com
2. Sök efter: rg-hsq-forms-dev
3. Kontrollera att följande resources finns:
   ✓ hsqformsdevacr (Container Registry)
   ✓ hsq-forms-dev-db (PostgreSQL)
   ✓ hsqformsdev... (Storage Account)
   ✓ hsq-forms-dev-env (Container Apps Environment)
```

#### 5.2 Nästa steg efter infrastruktur
```
När infrastrukturen är skapad:
1. ACR service connection
2. Docker build/push
3. Container deployment
4. API testing
```

## 🔧 **Troubleshooting**

### Problem 1: Service Connection Fails
```
Symptom: "The subscription could not be found"
Lösning: 
1. Kontrollera subscription ID
2. Se till att du har rätt permissions
3. Försök med "Service principal (manual)" om automatisk misslyckas
```

### Problem 2: Infrastructure Stage Fails
```
Symptom: "Deployment failed"
Lösning:
1. Kolla pipeline logs för specifikt fel
2. Kontrollera att service connection fungerar
3. Verifiera att subscription har rätt permissions
```

### Problem 3: Resource Group Already Exists
```
Symptom: "Resource group already exists"
Lösning: Detta är OK - pipeline hoppar över skapandet
```

## 🎯 **Vad händer sen?**

### Automatisk Workflow
```
1. Push till develop → DEV deployment
2. Push till main → PROD deployment
3. Löpande utveckling via feature branches
```

### Manuella steg som behövs en gång
```
✓ Azure DevOps project setup
✓ Service connections
✓ Pipeline variables
✓ Första infrastruktur deployment
⏳ ACR connections (efter infrastruktur)
⏳ Container deployment configuration
```

## 🚀 **Starta här:**

**🎯 Nästa action:** Gå till Azure DevOps och följ STEG 1-3 ovan. Sedan kan vi köra pipeline och skapa all infrastruktur automatiskt!

```
Direct link: https://dev.azure.com/
```
