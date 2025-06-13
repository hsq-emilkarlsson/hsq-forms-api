# HSQ Forms B2B Returns - Container Development Guide

## 🚀 Snabbstart

### Första gången
```bash
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api/forms/hsq-forms-container-b2b-returns

# Bygg och starta container
docker-compose up --build
```

**Din app körs nu på:** http://localhost:3002

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
docker-compose exec hsq-returns-form sh
```

---

## 📁 Filstruktur för Development

```
hsq-forms-container-b2b-returns/
├── src/                     # Din React kod
│   ├── components/          # Form komponenter
│   │   ├── B2BReturnsForm.tsx
│   │   └── LanguageSelector.tsx
│   ├── App.tsx             # Huvudapp med routing
│   ├── main.tsx            # React entry point
│   ├── index.css           # Tailwind CSS styles
│   └── i18n.js             # Språkhantering
├── public/                  # Statiska filer
├── dist/                    # Byggda filer (genereras automatiskt)
├── package.json             # Dependencies och scripts
├── Dockerfile               # Container-konfiguration
├── docker-compose.yml       # Standard container setup
├── docker-compose.dev.yml   # Development setup
├── dev-helper.sh           # Dina utvecklingskommandon
├── vite.config.ts          # Vite build konfiguration
├── tsconfig.json           # TypeScript konfiguration
└── tailwind.config.js      # Tailwind CSS konfiguration
```

---

## 🔧 Olika Development Modes

### Production Mode (Standard)
- **Port:** 3002
- **Använder:** `serve` för statiska filer
- **Bäst för:** Final testing innan deployment

```bash
docker-compose up --build
```

### Development Mode
- **Port:** 3002 (från docker-compose.dev.yml)
- **Använder:** Live reload med volumes
- **Bäst för:** Aktiv utveckling

```bash
docker-compose -f docker-compose.dev.yml up --build
```

---

## 📝 Typical Development Session

### 1. Starta din dag
```bash
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api/forms/hsq-forms-container-b2b-returns

# Kontrollera status
./dev-helper.sh status

# Starta development mode
./dev-helper.sh dev
```

### 2. Gör ändringar
- Ändra formulärfält i `src/components/B2BReturnsForm.tsx`
- Uppdatera språkversioner i `src/i18n.js`
- Anpassa styling i `src/index.css` eller Tailwind klasser
- Lägg till nya komponenter

### 3. Testa ändringar
- **Development mode:** Ändringar syns automatiskt (tack vare volumes)
- **Production mode:** Kör `./dev-helper.sh quick` för att rebuilda
- Testa språkväxling (English/Swedish/German)
- Verifiera formulärvalidering

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

### Port-konflikter (3002 används redan)
```bash
# Kontrollera vad som använder port 3002
lsof -i :3002

# Ändra port i docker-compose.yml om nödvändigt
ports:
  - "3003:3000"  # Ändra från 3002 till 3003
```

### Cache-problem
```bash
# Rensa Docker cache
docker system prune -f

# Rensa Node modules (i container)
docker-compose exec hsq-returns-form rm -rf node_modules
docker-compose exec hsq-returns-form npm install
```

### TypeScript/Vite fel
```bash
# Kontrollera TypeScript konfiguration
docker-compose exec hsq-returns-form npx tsc --noEmit

# Rebuilda med clean cache
./dev-helper.sh clean
```

---

## 🌐 Testing & URLs

### Lokala URLs
- **Development:** http://localhost:3002
- **API Backend:** http://localhost:8000 (om du kör main API)

### Testa olika scenarios
```bash
# Test i olika browsers
open -a "Google Chrome" http://localhost:3002
open -a "Safari" http://localhost:3002

# Test med olika skärmstorlekar (Chrome DevTools)
# Cmd+Shift+M för responsive mode
```

### Testa Returns-specifika funktioner
- Formulärvalidering (obligatoriska fält)
- Språkväxling (EN/SE/DE)
- Produktspecifika fält (modell, serienummer)
- Returnorsaker och prioritetsnivåer
- API-integration för formskickning

---

## 🚀 Deployment Process

### 1. Lokal test
```bash
# Säkerställ att allt fungerar lokalt
./dev-helper.sh quick
# Testa på http://localhost:3002
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
echo "dist" >> .dockerignore
```

### Optimera container storlek
- Använd multi-stage builds (redan konfigurerat i Dockerfile)
- Undvik onödiga dependencies i package.json
- Vite builds är redan optimerade för production

### Snabbare development
- Använd development mode för live reload
- Använd `--build` bara när du ändrat dependencies eller Dockerfile
- TypeScript type-checking är snabbare än full rebuild

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
docker-compose exec hsq-returns-form sh  # Gå in i container
docker system df                         # Visa Docker disk usage
docker system prune                      # Rensa oanvänd data

# React/Vite specific
npm run dev              # Development server (i container)
npm run build           # Production build (i container)
npm run preview         # Preview production build (i container)
```

---

## 🎯 B2B Returns Specifics

### Formulärstruktur
```typescript
// Huvudfält i B2BReturnsForm.tsx
interface ReturnFormData {
  companyName: string;
  contactPerson: string;
  email: string;
  phone: string;
  orderNumber: string;
  productModel: string;
  serialNumber: string;
  purchaseDate: string;
  returnReason: string;
  condition: string;
  refundMethod: string;
  urgencyLevel: string;
  additionalInfo: string;
}
```

### Språkstöd
- **Engelska (EN):** Standardspråk
- **Svenska (SE):** Komplett översättning
- **Tyska (DE):** Komplett översättning

### Validering
- Zod schema för type-safe validering
- React Hook Form för formulärhantering
- Real-time validation feedback

---

## 💡 Best Practices

### ✅ Gör detta
- Använd `./dev-helper.sh quick` för dagliga ändringar
- Testa alla språkversioner innan deployment
- Validera formulärfält och API-integration
- Använd TypeScript för type safety
- Testa på olika skärmstorlekar

### ❌ Undvik detta
- Skapa nya containers manuellt i Docker Desktop
- Glöm att stoppa containers när du inte använder dem
- Editera filer direkt i container (de försvinner vid rebuild)
- Skippa TypeScript type-checking
- Ignorera språkversioner

---

**🎯 Nu har du allt du behöver för smidig utveckling av B2B Returns formuläret!**
