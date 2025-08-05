# 🔒 HSQ Forms API - Säkerhetsanalys & Arkitekturrekommendationer

## 📋 Executive Summary

Projektets nuvarande arkitektur innehåller flera säkerhetsrisker som behöver adresseras innan production deployment. Detta dokument ger rekommendationer för en säkrare arkitektur.

## 🚨 Identifierade Säkerhetsrisker

### 1. **CORS Konfiguration - KRITISK**
```python
# NUVARANDE: /src/forms_api/app.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ❌ SÄKERHETSRISK: Tillåter alla domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**Risk**: 
- Öppnar för Cross-Site Request Forgery (CSRF) attacker
- Möjliggör datareading från skadliga webbsidor
- Bryter mot säkerhetsprinciper för production

### 2. **API Exponering - KRITISK**
```bicep
# NUVARANDE: /infra/main.bicep
ingress: {
  external: true  # ❌ API exponerat direkt till internet
  targetPort: 8000
  corsPolicy: {
    allowedOrigins: ['*']  # ❌ Alla origins tillåtna
  }
}
```

**Risk**:
- API är direkt tillgängligt från internet
- Inga rate limiting eller authentisering
- Känsliga endpoints som `/docs` exponerade i production

### 3. **Autentisering & Auktorisering - HÅRD**
```python
# NUVARANDE: Ingen enforced autentisering
# Endpints som /api/templates är öppna för alla
```

**Risk**:
- Obehöriga kan skapa/modifiera formulär templates
- Ingen kontroll över vem som kan submita forms
- API keys är optional

### 4. **Secrets Management - MEDEL**
```python
# NUVARANDE: Hard-coded fallbacks
husqvarna_api_key = os.getenv(
    'HUSQVARNA_API_KEY', 
    '3d9c4d8a3c5c47f1a2a0ec096496a786'  # ❌ Hard-coded API key
)
```

## 🏗️ Rekommenderad Arkitektur

### Arkitektur - Separation av Concerns

```
Internet
    ↓
🛡️ Azure Front Door + WAF
    ↓
┌─────────────────────────────────────────────────────────┐
│ PUBLIC ZONE (External Ingress)                         │
│                                                         │
│ ┌─────────────────┐  ┌─────────────────┐              │
│ │ Form Frontend   │  │ Static Assets   │              │
│ │ (React/Vite)    │  │ (CSS/JS/Images) │              │
│ │ Port: 443       │  │ CDN Cached      │              │
│ └─────────────────┘  └─────────────────┘              │
└─────────────────────────────────────────────────────────┘
                               │ HTTPS Only
                               ▼
┌─────────────────────────────────────────────────────────┐
│ PRIVATE ZONE (Internal Ingress Only)                   │
│                                                         │
│ ┌─────────────────┐  ┌─────────────────┐              │
│ │ Forms API       │  │ Admin API       │              │
│ │ (FastAPI)       │  │ (Internal Only) │              │
│ │ Port: 8000      │  │ Port: 8001      │              │
│ └─────────────────┘  └─────────────────┘              │
│                              │                         │
└──────────────────────────────┼─────────────────────────┘
                               │
                    ┌─────────────────┐
                    │ PostgreSQL      │
                    │ (Private)       │
                    └─────────────────┘
```

### Säkerhetsförbättringar

#### 1. **CORS Säkring**
```python
# REKOMMENDERAT: Miljöspecifik CORS
def get_cors_origins(environment: str) -> List[str]:
    if environment == "development":
        return [
            "http://localhost:3000",
            "http://localhost:5173",
            "http://localhost:8080"
        ]
    elif environment == "production":
        return [
            "https://husqvarnagroup.com",
            "https://*.husqvarnagroup.com",
            "https://your-forms-domain.com"
        ]
    return []

app.add_middleware(
    CORSMiddleware,
    allow_origins=get_cors_origins(settings.environment),
    allow_credentials=False,  # Säkrare utan credentials
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)
```

#### 2. **API Säkring & Rate Limiting**
```python
from fastapi import Depends, HTTPException
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/templates")
@limiter.limit("5/minute")  # Max 5 requests per minut
async def create_template(
    request: Request,
    template_data: FormTemplateCreate,
    api_key: str = Depends(validate_api_key),  # Kräv API key
    db: Session = Depends(get_db)
):
    """Create template - Requires authentication"""
    pass

@router.post("/submit")
@limiter.limit("10/minute")  # Form submission rate limit
async def submit_form(
    request: Request,
    form_data: FormSubmissionCreate,
    db: Session = Depends(get_db)
):
    """Submit form - Public endpoint med rate limiting"""
    pass
```

#### 3. **Infrastruktur Säkring**
```bicep
// REKOMMENDERAT: Bicep template uppdateringar
resource frontendApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${projectName}-frontend-${environment}'
  properties: {
    configuration: {
      ingress: {
        external: true  // Frontend kan vara extern
        targetPort: 3000
        corsPolicy: {
          allowedOrigins: [
            'https://husqvarnagroup.com'
            'https://*.husqvarnagroup.com'
          ]
        }
      }
    }
  }
}

resource apiApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${projectName}-api-${environment}'
  properties: {
    configuration: {
      ingress: {
        external: false  // ❗ API endast intern access
        targetPort: 8000
      }
    }
  }
}
```

#### 4. **Environment-based API Docs**
```python
# Säkra API dokumentation
def create_app() -> FastAPI:
    docs_url = "/docs" if settings.environment == "development" else None
    redoc_url = "/redoc" if settings.environment == "development" else None
    
    app = FastAPI(
        title="HSQ Forms API",
        docs_url=docs_url,  # Ingen docs i production
        redoc_url=redoc_url,
        openapi_url="/openapi.json" if settings.environment != "production" else None
    )
```

## 🔧 Implementation Plan

### Phase 1: Akut Säkering (1-2 dagar)

1. **CORS Fixning**
   ```bash
   # Uppdatera CORS i app.py
   # Sätt miljöspecifika origins
   ```

2. **API Docs Stängning**
   ```bash
   # Inaktivera /docs och /redoc i production
   ```

3. **Rate Limiting**
   ```bash
   pip install slowapi
   # Implementera basic rate limiting
   ```

### Phase 2: Arkitektur Separation (1 vecka)

1. **Frontend Separation**
   ```bash
   # Flytta forms/ till egen Container App
   # Konfigurera som static hosting
   ```

2. **API Internal Access**
   ```bash
   # Uppdatera Bicep: external: false för API
   # Frontend kommunicerar via internal ingress
   ```

3. **Authentication Layer**
   ```bash
   # Implementera API key requirement för admin endpoints
   # Public endpoints behåller rate limiting
   ```

### Phase 3: Advanced Security (2 veckor)

1. **WAF Implementation**
   ```bash
   # Azure Front Door + WAF
   # DDoS protection
   # Geo-blocking om applicable
   ```

2. **Audit Logging**
   ```bash
   # Log alla API calls
   # Security event monitoring
   # Alert på suspicious activity
   ```

## 📊 Säkerhetsmatris

| Område | Nuvarande Risk | Efter Phase 1 | Efter Phase 2 | Efter Phase 3 |
|--------|----------------|---------------|---------------|---------------|
| CORS | 🔴 Kritisk | 🟡 Medel | 🟢 Låg | 🟢 Låg |
| API Exponering | 🔴 Kritisk | 🔴 Kritisk | 🟢 Låg | 🟢 Låg |
| Rate Limiting | 🔴 Kritisk | 🟡 Medel | 🟢 Låg | 🟢 Låg |
| Authentication | 🟡 Medel | 🟡 Medel | 🟢 Låg | 🟢 Låg |
| Audit Logging | 🔴 Kritisk | 🔴 Kritisk | 🟡 Medel | 🟢 Låg |

## 🎯 Rekommendationer

### Kritiska åtgärder (Innan Production):

1. **STOPP** - Deploy inte med nuvarande CORS konfiguration
2. **FIXA** - Sätt specifika CORS origins innan production
3. **STÄNG** - API docs endpoints i production
4. **IMPLEMENTERA** - Rate limiting på alla endpoints

### Arkitektur rekommendationer:

1. **SEPARERA** - Frontend och API i olika Container Apps
2. **PRIVATA** - API endast internal ingress
3. **WAF** - Använd Azure Front Door för public access
4. **AUDITNG** - Logga alla säkerhetshändelser

### Driftsäkerhet:

1. **MONITORING** - Real-time säkerhetsövervakning
2. **ALERTING** - Automatiska alerts för anomalier  
3. **BACKUP** - Regular backup av känslig data
4. **UPDATE** - Regular security updates

## 📞 Next Steps

**Omedelbart (idag):**
1. Implementera CORS fixing enligt rekommendation
2. Stäng API docs i production environment
3. Lägg till basic rate limiting

**Denna vecka:**
1. Implementera frontend/API separation
2. Konfigurera internal ingress för API
3. Säkerhetstesta den nya arkitekturen

**Kommande veckor:**
1. WAF implementation
2. Comprehensive security testing
3. Audit logging system

---

**⚠️ VARNING**: Nuvarande konfiguration är INTE production-ready ur säkerhetssynpunkt. Implementera åtminstone Phase 1 innan deployment.
