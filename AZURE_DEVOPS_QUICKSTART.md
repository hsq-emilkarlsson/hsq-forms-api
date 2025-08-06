# 🚀 Azure DevOps Quickstart - HSQ Forms API

## 🎯 Mål: Få igång allt via Azure DevOps steg för steg

### 📋 **STATUS: Projektet är DEPLOYMENT-KLART! ✅**

**✅ FÄRDIGT:**
- Service Connection skapad av IT-organisation
- Bicep templates för infrastruktur (API, DB, Storage, Container Apps)
- Azure Pipeline konfiguration
- Container images för API + alla formulär
- Database migrations och schemas
- File upload-hantering med Azure Storage

**⚠️ ÅTERSTÅR:**
- Köra första pipeline-deploys för att skapa infrastruktur
- Konfigurera ACR credentials för container push
- Testa deployment och validera funktionalitet

---

### 📋 **STEG 1: Azure DevOps Setup**

#### 1.1 ✅ Projekt finns redan!
```
✅ DevOps Projekt: Customforms
✅ URL: https://dev.azure.com/HQV-DBP/Customforms
✅ GitHub repo kopplat
```

#### 1.2 ✅ Pipeline konfiguration klar
```
✅ azure-pipelines.yml finns och är konfigurerad
✅ Bicep templates redo för infrastruktur
✅ Multi-stage pipeline: Test → Infrastructure → Deploy
```

### 📋 **STEG 2: Service Connection (✅ KLART!)**

#### 2.1 ✅ Service Connection Skapad av IT
```
✅ REDAN KLART! IT-organisationen har skapat service connectionen:

Service Connection: SCON-HAZE-01AA-APP1066-Dev-Martechlab
- Typ: Azure Resource Manager
- Autentisering: Workload Identity Federation via OpenID Connect
- Service Connection ID: 07517baa-1095-43de-ad5c-63dbfbc22f56
- Subscription: HAZE-01AA-APP1066-Dev-Martechlab
- Skapad av: Grzegorz Jońca (grzegorz.jonca@husqvarnagroup.com)

🔗 OIDC Issuer: https://login.microsoftonline.com/2a1c169e-715a-412b-b526-05da3f8412fa/v2.0
🎯 Subject Identifier: /eid1/c/pub/t/hNyCkpxKOG1JgXaP4QS-g/a/IrSbSSETt0KqFYZ8ppdXmA/sc/64ad3665-c01b-443a-a696-99b1d21a0145/07517baa-1095-43de-ad5c-63dbfbc22f56
```

#### 2.2 Azure DevOps Project Information
```
DevOps Projekt: Customforms
URL: https://dev.azure.com/HQV-DBP/Customforms
Subscription: HAZE-01AA-APP1066-Dev-Martechlab
IT-ärende: REQ0964349
```

**✅ Detta är nu klart! Service connectionen är skapad och kan användas för deployment.**

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
