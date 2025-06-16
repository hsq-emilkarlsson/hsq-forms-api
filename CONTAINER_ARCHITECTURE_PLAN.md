# 🏗️ HSQ Forms - Container Architecture Plan

## 🎯 Vision: Full Container Architecture

Du har helt rätt! Varje formulär ska köras som egen container för att säkerställa identisk miljö mellan lokal utveckling och produktion.

## 📦 Container Architecture Overview

### Main API Container
```
hsq-forms-api-v2
├── Image: hsqformsprodacr.azurecr.io/hsq-forms-api:v1.0.0
├── Port: 8000
├── Type: Internal API
└── Environment Variables:
    ├── DATABASE_URL=postgresql://hsq_admin:***@hsq-forms-prod-db.postgres.database.azure.com:5432/hsq_forms_db
    ├── AZURE_STORAGE_ACCOUNT_NAME=hsqformsprodsa
    ├── AZURE_STORAGE_CONTAINER_NAME=forms
    └── CORS_ORIGINS=https://forms.hazesoft.se,https://support.hazesoft.se,https://returns.hazesoft.se
```

### Form Container Apps
```
hsq-forms-b2b-feedback
├── Image: hsqformsprodacr.azurecr.io/hsq-forms-b2b-feedback:latest
├── Port: 3000
├── Type: Frontend (React/Vite)
└── Environment Variables:
    └── VITE_API_BASE_URL=https://hsq-forms-api-v2.internal.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io

hsq-forms-b2b-returns
├── Image: hsqformsprodacr.azurecr.io/hsq-forms-b2b-returns:latest
├── Port: 3000
├── Type: Frontend (React/Vite)
└── Environment Variables:
    └── VITE_API_BASE_URL=https://hsq-forms-api-v2.internal.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io

hsq-forms-b2b-support
├── Image: hsqformsprodacr.azurecr.io/hsq-forms-b2b-support:latest
├── Port: 3000
├── Type: Frontend (React/Vite)
└── Environment Variables:
    └── VITE_API_BASE_URL=https://hsq-forms-api-v2.internal.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io

hsq-forms-b2c-returns
├── Image: hsqformsprodacr.azurecr.io/hsq-forms-b2c-returns:latest
├── Port: 3000
├── Type: Frontend (React/Vite)
└── Environment Variables:
    └── VITE_API_BASE_URL=https://hsq-forms-api-v2.internal.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io
```

## 🌐 Network Architecture

```
Internet
    ↓
Azure Front Door / Application Gateway (future)
    ↓
┌─────────────────────────────────────────────────────────────┐
│ Container Apps Environment: hsq-forms-prod-env             │
│                                                             │
│ ┌─────────────────┐  ┌─────────────────┐                   │
│ │ Form Containers │  │   Main API      │                   │
│ │ (External)      │  │ (Internal)      │                   │
│ │                 │  │                 │                   │
│ │ Port: 3000      │──┤ Port: 8000      │                   │
│ │ React/Vite      │  │ FastAPI/Python  │                   │
│ └─────────────────┘  └─────────────────┘                   │
│                              │                             │
└──────────────────────────────┼─────────────────────────────┘
                               │
                    ┌─────────────────┐
                    │ PostgreSQL DB   │
                    │ Azure Storage   │
                    └─────────────────┘
```

## 🚀 Deployment Commands (När ACR Auth är löst)

### 1. B2B Feedback Form
```bash
az containerapp create \
  --name hsq-forms-b2b-feedback \
  --resource-group rg-hsq-forms-prod-westeu \
  --environment hsq-forms-prod-env \
  --image hsqformsprodacr.azurecr.io/hsq-forms-b2b-feedback:latest \
  --target-port 3000 \
  --ingress external \
  --system-assigned \
  --env-vars "VITE_API_BASE_URL=https://hsq-forms-api-v2.internal.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io"
```

### 2. B2B Returns Form
```bash
az containerapp create \
  --name hsq-forms-b2b-returns \
  --resource-group rg-hsq-forms-prod-westeu \
  --environment hsq-forms-prod-env \
  --image hsqformsprodacr.azurecr.io/hsq-forms-b2b-returns:latest \
  --target-port 3000 \
  --ingress external \
  --system-assigned \
  --env-vars "VITE_API_BASE_URL=https://hsq-forms-api-v2.internal.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io"
```

### 3. B2B Support Form
```bash
az containerapp create \
  --name hsq-forms-b2b-support \
  --resource-group rg-hsq-forms-prod-westeu \
  --environment hsq-forms-prod-env \
  --image hsqformsprodacr.azurecr.io/hsq-forms-b2b-support:latest \
  --target-port 3000 \
  --ingress external \
  --system-assigned \
  --env-vars "VITE_API_BASE_URL=https://hsq-forms-api-v2.internal.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io"
```

### 4. B2C Returns Form
```bash
az containerapp create \
  --name hsq-forms-b2c-returns \
  --resource-group rg-hsq-forms-prod-westeu \
  --environment hsq-forms-prod-env \
  --image hsqformsprodacr.azurecr.io/hsq-forms-b2c-returns:latest \
  --target-port 3000 \
  --ingress external \
  --system-assigned \
  --env-vars "VITE_API_BASE_URL=https://hsq-forms-api-v2.internal.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io"
```

## 🔄 Lokal Utveckling vs Produktion

### Lokal Utveckling (docker-compose)
```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/hsq_forms
  
  b2b-feedback:
    build: ./forms/hsq-forms-container-b2b-feedback
    ports:
      - "3001:3000"
    environment:
      - VITE_API_BASE_URL=http://localhost:8000
  
  b2b-returns:
    build: ./forms/hsq-forms-container-b2b-returns
    ports:
      - "3002:3000"
    environment:
      - VITE_API_BASE_URL=http://localhost:8000
  
  b2b-support:
    build: ./forms/hsq-forms-container-b2b-support
    ports:
      - "3003:3000"
    environment:
      - VITE_API_BASE_URL=http://localhost:8000
  
  b2c-returns:
    build: ./forms/hsq-forms-container-b2c-returns
    ports:
      - "3004:3000"
    environment:
      - VITE_API_BASE_URL=http://localhost:8000
  
  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=hsq_forms
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
```

### Produktion (Azure Container Apps)
```bash
# Exakt samma containers, bara olika environment variables:
# - Produktions-databas istället för lokal postgres
# - Internal URLs för API-kommunikation
# - Azure Storage istället för lokal fillagring
```

## 🎯 Fördelar med Container Architecture

### 1. Utvecklingsparitet
- ✅ Identisk miljö mellan dev och prod
- ✅ Samma Docker images körs överallt
- ✅ Inga "works on my machine" problem

### 2. Skalbarhet
- ✅ Varje formulär kan skalas individuellt
- ✅ API:t kan skalas separat från frontend
- ✅ Zero-downtime deployments

### 3. Isolering
- ✅ Formulär påverkar inte varandra
- ✅ Fel i ett formulär kraschar inte hela systemet
- ✅ Oberoende deployment av olika formulär

### 4. Säkerhet
- ✅ API:t är internal-only
- ✅ Formulär kommunicerar via definierade API:er
- ✅ Nätverksisolering mellan services

### 5. Underhåll
- ✅ Enkelt att uppdatera enskilda formulär
- ✅ Rollback av specifika components
- ✅ A/B testing av olika versioner

## 🔧 DNS och Routing (Framtida)

### Produktions-URLs
```
https://forms.hazesoft.se/b2b-feedback    → hsq-forms-b2b-feedback.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io
https://forms.hazesoft.se/b2b-returns     → hsq-forms-b2b-returns.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io
https://support.hazesoft.se               → hsq-forms-b2b-support.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io
https://returns.hazesoft.se               → hsq-forms-b2c-returns.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io
```

## 🚧 Nuvarande Status

### ✅ Klart
- Alla container images byggda och pushade till ACR
- Container Apps Environment redo
- Main API Container App skapad (väntar på auth)

### 🔄 Väntar på ACR Authentication
- Role assignment för managed identity
- Eller admin user enablement
- Sedan kan alla containers deploylas på 10 minuter

### 📋 Nästa Steg (efter auth)
1. Uppdatera main API container med rätt image
2. Skapa alla form Container Apps
3. Konfigurera environment variables
4. Testa hela flödet
5. Konfigurera custom domains (om behövs)

## 💡 Varför Container Architecture är Smart

1. **DevOps Best Practice**: Infrastructure as Code med identiska environments
2. **Microservices**: Varje formulär är en egen service
3. **Cloud Native**: Designat för Azure Container Apps
4. **Modern**: React frontends + FastAPI backend
5. **Skalbart**: Kan hantera tusentals användare
6. **Säkert**: Network isolation och managed identities

Detta är definitivt rätt väg framåt! 🚀
