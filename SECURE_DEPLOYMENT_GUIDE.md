# 🚀 Säker Deployment Guide - HSQ Forms API

## 📋 Översikt

Denna guide beskriver hur du deployer den säkrare arkitekturen för HSQ Forms API med separerade frontend/backend och förbättrad säkerhet.

## 🏗️ Säker Arkitektur

```
Internet
    ↓
🛡️ HTTPS Only
    ↓
┌─────────────────────────────────────────────┐
│ PUBLIC ZONE                                 │
│ ┌─────────────────┐                        │
│ │ Frontend App    │ (External Ingress)     │
│ │ React/Vite      │ Port: 3000             │
│ │ Static Assets   │ CORS: Restricted       │
│ └─────────────────┘                        │
└─────────────────────────────────────────────┘
                    │ Internal Network Only
                    ▼
┌─────────────────────────────────────────────┐
│ PRIVATE ZONE                               │
│ ┌─────────────────┐  ┌─────────────────┐  │
│ │ API Backend     │  │ PostgreSQL DB   │  │
│ │ FastAPI         │  │ Private Access  │  │
│ │ Internal Only   │  │ Port: 5432      │  │
│ │ Port: 8000      │  │                 │  │
│ └─────────────────┘  └─────────────────┘  │
│                                           │
│ ┌─────────────────┐                      │
│ │ Azure Blob      │ Private Access       │
│ │ Storage         │ Managed Identity     │
│ └─────────────────┘                      │
└─────────────────────────────────────────────┘
```

## 🔧 Steg-för-steg Implementation

### 1. Förberedelser

```bash
# Installera säkerhetspaket
pip install slowapi redis
pip install -r requirements.txt
```

### 2. Deploy med Säker Bicep

```bash
# Säkert deployment med ny infrastruktur
az deployment group create \
  --resource-group hsq-forms-rg \
  --template-file infra/main-secure.bicep \
  --parameters \
    environmentName=dev \
    dbAdminUsername=hsqadmin \
    dbAdminPassword="$(az keyvault secret show --vault-name hsq-forms-kv --name db-password --query value -o tsv)" \
    frontendOrigins='["https://husqvarnagroup.com","https://*.husqvarnagroup.com"]'
```

### 3. Uppdatera Environment Variables

```bash
# Sätt APP_ENVIRONMENT för miljöspecifik CORS
az containerapp update \
  --name hsq-forms-api-dev \
  --resource-group hsq-forms-rg \
  --set-env-vars APP_ENVIRONMENT=dev

# Production environment
az containerapp update \
  --name hsq-forms-api-prod \
  --resource-group hsq-forms-rg \
  --set-env-vars \
    APP_ENVIRONMENT=production \
    FRONTEND_URL="https://husqvarnagroup.com,https://forms.husqvarnagroup.com"
```

## 🔒 Säkerhetsvalidering

### Kontrollera CORS-konfiguration

```bash
# Test development CORS
curl -H "Origin: http://localhost:3000" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://hsq-forms-api-dev.azurecontainerapps.io/api/templates

# Test production CORS (ska bara tillåta tillåtna origins)
curl -H "Origin: https://badsite.com" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://hsq-forms-api-prod.azurecontainerapps.io/api/templates
```

### Verifiera Rate Limiting

```bash
# Test rate limiting (ska få 429 Too Many Requests efter 5 requests)
for i in {1..10}; do
  curl -X POST https://hsq-forms-api.azurecontainerapps.io/api/templates \
       -H "Content-Type: application/json" \
       -d '{"name":"test","project_id":"test"}'
  echo "Request $i"
  sleep 1
done
```

### Kontrollera API Docs Access

```bash
# Development - ska fungera
curl https://hsq-forms-api-dev.azurecontainerapps.io/docs

# Production - ska returnera 404
curl https://hsq-forms-api-prod.azurecontainerapps.io/docs
```

## 🛡️ Säkerhetsfeatures Aktiverade

### ✅ CORS Säkring
- **Development**: Endast localhost origins
- **Production**: Endast Husqvarna Group domains
- **Headers**: Begränsade till nödvändiga headers
- **Methods**: Endast GET, POST, OPTIONS

### ✅ Rate Limiting
- **Templates**: 5 requests/minut (admin endpoints)
- **Submissions**: 10 requests/minut (public forms)
- **Validation**: 30 requests/minut (customer validation)
- **Read operations**: 60 requests/minut

### ✅ API Docs Säkring
- **Development**: `/docs` och `/redoc` tillgängliga
- **Production**: API docs inaktiverade
- **OpenAPI schema**: Endast i development

### ✅ Infrastructure Säkring
- **API**: Internal ingress endast
- **Database**: Private access
- **Storage**: Managed Identity authentication
- **HTTPS**: Endast TLS 1.2+

## 🔍 Monitoring & Alerts

### Säkerhetsloggar

```bash
# Visa rate limiting events
az monitor log-analytics query \
  --workspace "hsq-forms-workspace" \
  --analytics-query "
    ContainerAppConsoleLogs_CL
    | where ContainerAppName_s contains 'hsq-forms-api'
    | where Log_s contains 'rate limit'
    | project TimeGenerated, Log_s
    | order by TimeGenerated desc
  "

# Visa CORS violations
az monitor log-analytics query \
  --workspace "hsq-forms-workspace" \
  --analytics-query "
    ContainerAppConsoleLogs_CL
    | where Log_s contains 'CORS'
    | project TimeGenerated, Log_s
  "
```

### Säkerhetsalerts

```bash
# Skapa alert för rate limiting
az monitor metrics alert create \
  --name "HSQ-Forms-Rate-Limit-Alert" \
  --resource-group hsq-forms-rg \
  --description "Alert when rate limiting is triggered frequently" \
  --condition "count 'logs' where source contains 'rate limit'" \
  --window-size 5m \
  --evaluation-frequency 1m
```

## 🚨 Incident Response

### Rate Limiting Attack

```bash
# Identifiera IP-adresser
az monitor log-analytics query \
  --workspace "hsq-forms-workspace" \
  --analytics-query "
    ContainerAppConsoleLogs_CL
    | where Log_s contains 'rate limit exceeded'
    | extend IP = extract('IP: ([0-9.]+)', 1, Log_s)
    | summarize count() by IP
    | order by count_ desc
  "

# Blockera IP på Container App level (temporary)
# Implementera via Azure Front Door eller Application Gateway
```

### CORS Violation

```bash
# Analysera CORS violations
az monitor log-analytics query \
  --workspace "hsq-forms-workspace" \
  --analytics-query "
    ContainerAppConsoleLogs_CL
    | where Log_s contains 'CORS error'
    | extend Origin = extract('Origin: ([^\\s]+)', 1, Log_s)
    | summarize count() by Origin
  "
```

## 📊 Säkerhets-checklist

### Före Production Deploy

- [ ] CORS origins konfigurerade för production
- [ ] API docs inaktiverade i production
- [ ] Rate limiting testat och verifierat
- [ ] Database firewall rules konfigurerade
- [ ] Storage account private access verifierat
- [ ] Managed Identity permissions korrekta
- [ ] Säkerhetsloggar konfigurerade
- [ ] Alerts för säkerhetshändelser aktiverade

### Regelbundna Säkerhetskontroller

- [ ] Granska CORS violations (veckovis)
- [ ] Analysera rate limiting events (dagligen)
- [ ] Kontrollera suspicious IP addresses (dagligen)
- [ ] Verifiera SSL certificate validity (månadsvis)
- [ ] Uppdatera säkerhetspaket (månadsvis)

## 🔄 Rollback Plan

Om säkerhetsproblem upptäcks:

```bash
# 1. Snabb rollback till tidigare version
az containerapp revision copy \
  --name hsq-forms-api-prod \
  --resource-group hsq-forms-rg \
  --from-revision "hsq-forms-api-prod--previous-revision"

# 2. Inaktivera external access tillfälligt
az containerapp ingress disable \
  --name hsq-forms-api-prod \
  --resource-group hsq-forms-rg

# 3. Analysera säkerhetslöggar
# 4. Fixa säkerhetsproblem
# 5. Deploy ny säker version
# 6. Aktivera ingress igen
```

---

**⚠️ VIKTIGT**: Utför alltid säkerhetstester innan production deployment!
