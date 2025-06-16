# 🚀 HSQ Forms - Lokal Utveckling med Full Container Architecture

## 🎯 Översikt

Detta setup matchar exakt produktionsarkitekturen där varje formulär körs som en egen container. Samma Docker images används både lokalt och i produktion.

## 🏗️ Arkitektur

```
Lokal Utveckling (docker-compose)           Produktion (Azure Container Apps)
┌─────────────────────────────────┐        ┌─────────────────────────────────┐
│                                 │        │                                 │
│ localhost:3001 → B2B Feedback   │   ≡    │ Container App: b2b-feedback     │
│ localhost:3002 → B2B Returns    │   ≡    │ Container App: b2b-returns      │
│ localhost:3003 → B2B Support    │   ≡    │ Container App: b2b-support      │
│ localhost:3004 → B2C Returns    │   ≡    │ Container App: b2c-returns      │
│                                 │        │                                 │
│ localhost:8000 → API            │   ≡    │ Container App: api (internal)   │
│ localhost:5432 → PostgreSQL     │   ≡    │ Azure PostgreSQL               │
│                                 │        │                                 │
└─────────────────────────────────┘        └─────────────────────────────────┘
```

## 🚀 Kom igång

### 1. Förutsättningar
```bash
# Kontrollera att Docker Desktop körs
docker --version
docker-compose --version
```

### 2. Skapa nätverk (första gången)
```bash
docker network create hsq-forms-network
```

### 3. Starta alla services
```bash
# Starta allt (första gången eller vid ändringar)
docker-compose -f docker-compose.full.yml up --build

# Starta i bakgrunden
docker-compose -f docker-compose.full.yml up -d

# Endast API och databas (för API-utveckling)
docker-compose -f docker-compose.yml up
```

### 4. Stoppa services
```bash
# Stoppa alla containers
docker-compose -f docker-compose.full.yml down

# Stoppa och ta bort volumes (full reset)
docker-compose -f docker-compose.full.yml down -v
```

## 🌐 Åtkomst-URLs

### Formulär (Frontend)
- **B2B Feedback**: http://localhost:3001
- **B2B Returns**: http://localhost:3002  
- **B2B Support**: http://localhost:3003
- **B2C Returns**: http://localhost:3004

### Backend Services
- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **PostgreSQL**: localhost:5432 (postgres/local_dev_password_123)

## 🔧 Utvecklingsflöde

### Scenario 1: Utveckla API:t
```bash
# Starta endast API och databas
docker-compose up

# API startar med --reload för hot reloading
# Ändringar i src/ triggar automatisk restart
```

### Scenario 2: Utveckla ett specifikt formulär
```bash
# Starta alla services
docker-compose -f docker-compose.full.yml up -d

# Stoppa bara det formulär du vill utveckla
docker-compose -f docker-compose.full.yml stop b2b-feedback

# Utveckla lokalt i forms/hsq-forms-container-b2b-feedback/
cd forms/hsq-forms-container-b2b-feedback
npm run dev  # Kör på port 5173 istället

# Uppdatera VITE_API_BASE_URL till http://localhost:8000
```

### Scenario 3: Utveckla allt
```bash
# Starta alla containers
docker-compose -f docker-compose.full.yml up

# Alla formulär bygger om automatiskt vid ändringar
# API restartar automatiskt vid ändringar
```

## 🐛 Debug och Logs

### Se logs för alla services
```bash
docker-compose -f docker-compose.full.yml logs -f
```

### Se logs för specifik service
```bash
docker-compose -f docker-compose.full.yml logs -f api
docker-compose -f docker-compose.full.yml logs -f b2b-feedback
```

### Koppla till container
```bash
# API container
docker-compose -f docker-compose.full.yml exec api bash

# Formulär container
docker-compose -f docker-compose.full.yml exec b2b-feedback sh
```

### Kontrollera container status
```bash
docker-compose -f docker-compose.full.yml ps
```

## 🔄 Uppdatera efter ändringar

### Efter Python-ändringar (API)
```bash
# API container har --reload aktiverat, inget behövs
# Eller starta om manuellt:
docker-compose -f docker-compose.full.yml restart api
```

### Efter React-ändringar (Formulär)
```bash
# Vite har hot reloading, men vid package.json ändringar:
docker-compose -f docker-compose.full.yml build b2b-feedback
docker-compose -f docker-compose.full.yml up -d b2b-feedback
```

### Efter Dockerfile-ändringar
```bash
# Bygg om specifik service
docker-compose -f docker-compose.full.yml build b2b-feedback

# Eller bygg om allt
docker-compose -f docker-compose.full.yml build
```

## 🧪 Testa hela flödet

### 1. Starta alla services
```bash
docker-compose -f docker-compose.full.yml up -d
```

### 2. Kontrollera att allt fungerar
```bash
# API hälsokontroll
curl http://localhost:8000/health

# Formulär
open http://localhost:3001  # B2B Feedback
open http://localhost:3002  # B2B Returns
open http://localhost:3003  # B2B Support
open http://localhost:3004  # B2C Returns
```

### 3. Testa formulärinlämning
1. Gå till http://localhost:3001
2. Fyll i formuläret
3. Kontrollera att data sparas i API:t
4. Verifiera i databas om behövs

## 🚧 Troubleshooting

### Port redan används
```bash
# Hitta vad som använder porten
lsof -i :3001

# Stoppa alla containers
docker-compose -f docker-compose.full.yml down
```

### Container startar inte
```bash
# Kontrollera logs
docker-compose -f docker-compose.full.yml logs b2b-feedback

# Bygg om från scratch
docker-compose -f docker-compose.full.yml build --no-cache b2b-feedback
```

### Databasproblem
```bash
# Återställ databas
docker-compose -f docker-compose.full.yml down -v
docker-compose -f docker-compose.full.yml up -d postgres

# Vänta på att databasen startar
docker-compose -f docker-compose.full.yml logs postgres
```

### Nätverksproblem
```bash
# Återskapa nätverk
docker network rm hsq-forms-network
docker network create hsq-forms-network
```

## 🎯 Produktionslikhet

Detta setup ger:
- ✅ Samma container images som i produktion
- ✅ Samma nätverksarkitektur (containers kommunicerar via nätverk)
- ✅ Samma miljövariabler-mönster
- ✅ Samma port-konfiguration
- ✅ Samma dependency-hantering

Enda skillnaden:
- Lokal: PostgreSQL i container + localhost URLs
- Prod: Azure PostgreSQL + internal Azure URLs

## 🚀 Deploy till produktion

När du är nöjd med lokal utveckling:

1. **Push ändringar**:
   ```bash
   git add .
   git commit -m "Update forms"
   git push
   ```

2. **Bygg nya images**:
   ```bash
   # Automatisk build via CI/CD
   # Eller manuellt:
   docker build -t hsqformsprodacr.azurecr.io/hsq-forms-api:latest .
   docker push hsqformsprodacr.azurecr.io/hsq-forms-api:latest
   ```

3. **Uppdatera Container Apps**:
   ```bash
   # Automatisk deploy via azd/bicep
   # Eller manuellt:
   az containerapp update --name hsq-forms-api-v2 --image hsqformsprodacr.azurecr.io/hsq-forms-api:latest
   ```

Perfekt utvecklingsmiljö för container-baserad arkitektur! 🎉
