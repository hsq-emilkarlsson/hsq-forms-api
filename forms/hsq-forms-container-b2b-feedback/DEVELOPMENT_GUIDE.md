# HSQ Forms B2B Feedback - Container Development Guide

## 🚀 Snabbstart

### Första gången
```bash
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api/forms/hsq-forms-container-b2b-feedback

# Bygg och starta container
docker-compose up --build
```

**Din app körs nu på:** http://localhost:3001

---

## 🔄 Daily Development Workflow

### 1. **Snabba Ändringar (Rekommenderat för de flesta fall)**
```bash
# När du gör ändringar i kod (färger, fält, etc.)
./dev-helper.sh quick

# Eller manuellt:
docker-compose down
docker-compose up --build -d
```

### 2. **Aktiv Utveckling (För större ändringar)**
```bash
# Startar development mode med live reload
./dev-helper.sh dev

# Eller manuellt:
docker-compose -f docker-compose.dev.yml up --build
```

### 3. **Kontrollera Status**
```bash
# Se vad som körs
./dev-helper.sh status

# Eller manuellt:
docker-compose ps
```

---

## 🛠️ Utvecklings-kommandon

### Tillgängliga Helper-kommandon
```bash
./dev-helper.sh status   # Visa container status
./dev-helper.sh quick    # Snabb rebuild (samma container-namn)
./dev-helper.sh dev      # Development mode med live reload
./dev-helper.sh clean    # Clean rebuild (tar bort cache)
./dev-helper.sh stop     # Stoppa alla containers
```

### Manuella Docker-kommandon
```bash
# Stoppa container (behåller imagen)
docker-compose stop

# Stoppa och ta bort container
docker-compose down

# Bygg om imagen
docker-compose build --no-cache

# Starta i bakgrunden
docker-compose up -d

# Visa loggar
docker-compose logs -f

# Gå in i container (för debugging)
docker-compose exec hsq-feedback-form sh
```

---

## 📁 Filstruktur för Development

```
hsq-forms-container-b2b-feedback/
├── src/                     # Din React/Vue/JS kod
├── public/                  # Statiska filer
├── dist/                    # Byggda filer (genereras automatiskt)
├── package.json             # Dependencies och scripts
├── Dockerfile               # Container-konfiguration
├── docker-compose.yml       # Standard container setup
├── docker-compose.dev.yml   # Development setup
└── dev-helper.sh           # Dina utvecklingskommandon
```

---

## 🔧 Olika Development Modes

### Production Mode (Standard)
- **Port:** 3001
- **Använder:** `serve` för statiska filer
- **Bäst för:** Final testing innan deployment

```bash
docker-compose up --build
```

### Development Mode
- **Port:** 3001 (från docker-compose.dev.yml)
- **Använder:** Live reload med volumes
- **Bäst för:** Aktiv utveckling

```bash
docker-compose -f docker-compose.dev.yml up --build
```

---

## 📝 Typical Development Session

### 1. Starta din dag
```bash
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api/forms/hsq-forms-container-b2b-feedback

# Kontrollera status
./dev-helper.sh status

# Starta development mode
./dev-helper.sh dev
```

### 2. Gör ändringar
- Ändra färger i CSS/SCSS filer
- Lägg till nya fält i formulär
- Uppdatera komponenter

### 3. Testa ändringar
- **Development mode:** Ändringar syns automatiskt (tack vare volumes)
- **Production mode:** Kör `./dev-helper.sh quick` för att rebuilda

### 4. När du är klar
```bash
# Stoppa containers
./dev-helper.sh stop

# Eller låt dem köra i bakgrunden
docker-compose up -d
```

---

## 🚨 Troubleshooting

### Container startar inte
```bash
# Clean rebuild
./dev-helper.sh clean

# Kontrollera loggar
docker-compose logs
```

### Ändringar syns inte
```bash
# Force rebuild
docker-compose build --no-cache
docker-compose up --force-recreate
```

### Port-konflikter
```bash
# Kontrollera vad som använder port 3001
lsof -i :3001

# Ändra port i docker-compose.yml om nödvändigt
ports:
  - "3002:3000"  # Ändra från 3001 till 3002
```

### Cache-problem
```bash
# Rensa Docker cache
docker system prune -f

# Rensa Node modules (i container)
docker-compose exec hsq-feedback-form rm -rf node_modules
docker-compose exec hsq-feedback-form npm install
```

---

## 🌐 Testing & URLs

### Lokala URLs
- **Development:** http://localhost:3001
- **API Backend:** http://localhost:8000 (om du kör main API)

### Testa olika scenarios
```bash
# Test i olika browsers
open -a "Google Chrome" http://localhost:3001
open -a "Safari" http://localhost:3001

# Test med olika skärmstorlekar (Chrome DevTools)
# Cmd+Shift+M för responsive mode
```

---

## 🚀 Deployment Process

### 1. Lokal test
```bash
# Säkerställ att allt fungerar lokalt
./dev-helper.sh quick
# Testa på http://localhost:3001
```

### 2. Production build test
```bash
# Testa production build lokalt
docker-compose -f docker-compose.yml up --build
```

### 3. Deploy till Azure
```bash
# Gå till root-projektet
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api

# Azure deployment
azd up

# Eller använd deployment scripts
./scripts/deploy-production.sh
```

---

## 📊 Performance Tips

### Optimera Docker builds
```bash
# Använd .dockerignore för att exkludera onödiga filer
echo "node_modules" >> .dockerignore
echo "*.log" >> .dockerignore
echo ".git" >> .dockerignore
```

### Optimera container storlek
- Använd multi-stage builds (redan konfigurerat i Dockerfile)
- Undvik onödiga dependencies i package.json

### Snabbare development
- Använd development mode för live reload
- Använd `--build` bara när du ändrat dependencies

---

## 🔗 Viktiga Kommandon - Cheat Sheet

```bash
# Snabbkommandon
./dev-helper.sh quick    # Vanligaste - snabb rebuild
./dev-helper.sh dev      # Development med live reload
./dev-helper.sh stop     # Stoppa allt
./dev-helper.sh status   # Kontrollera vad som körs

# Docker-kommandon
docker-compose up --build       # Bygg och starta
docker-compose down            # Stoppa och ta bort
docker-compose logs -f         # Visa loggar live
docker-compose ps              # Lista containers

# Debugging
docker-compose exec hsq-feedback-form sh  # Gå in i container
docker system df                          # Visa Docker disk usage
docker system prune                       # Rensa oanvänd data
```

---

## 💡 Best Practices

### ✅ Gör detta
- Använd `./dev-helper.sh quick` för dagliga ändringar
- Testa alltid lokalt innan deployment
- Använd development mode för större utvecklingsarbete
- Committa kod regelbundet

### ❌ Undvik detta
- Skapa nya containers manuellt i Docker Desktop
- Glöm att stoppa containers när du inte använder dem
- Editera filer direkt i container (de försvinner vid rebuild)
- Skippa testing innan deployment

---

**🎯 Nu har du allt du behöver för en smidig development-workflow!**
