# 🚀 HSQ Forms Platform - Backend API

> **Centralized FastAPI backend for HSQ form applications**  
> Deployed on Azure Container Apps with Cosmos DB

![Deployment Status](https://img.shields.io/badge/Deployment-✅%20Live-success?style=for-the-badge)
![Azure](https://img.shields.io/badge/Azure-Container%20Apps-0078d4?style=for-the-badge&logo=microsoft-azure)
![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi)
![Python](https://img.shields.io/badge/Python-3.11+-3776ab?style=for-the-badge&logo=python)

## 🌐 Production API

| Component | URL | Status |
|-----------|-----|--------|
| **🔗 API Backend** | [hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io](https://hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io) | ✅ Running |
| **📚 API Documentation** | [/docs](https://hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io/docs) | ✅ Available |

## 🏗️ New Architecture (Frontend Separated)

**This repository now contains ONLY the backend API.**  
Frontend applications are in separate repositories for better isolation and deployment.

```
hsq-form-platform/              # 👈 This repo (Backend)
├── apps/app/                   # FastAPI application
├── infra/                      # Azure Bicep infrastructure
└── docker/                    # Docker configurations

# Separate repositories (to be created):
hsq-feedback-form/              # React feedback form
hsq-support-form/               # React support form  
hsq-contact-form/               # React contact form
```
HSQ Forms Platform
├── 🔗 API Backend (FastAPI)
│   ├── Centraliserad formulärhantering
│   ├── Database med Alembic migrations
│   └── RESTful API endpoints
├── 📝 Feedback Form (React + Vite)
│   ├── Feedbackformulär för användarrespons
│   └── Responsiv design med modern UI
├── 🎫 Support Form (React + Vite)
│   ├── Supportärenden och tekniska frågor
│   └── Strukturerad ärendehantering
└── 📦 Shared Packages
    ├── UI-komponenter
    └── Gemensamma scheman
```

## 🚀 Funktioner

- ✅ **Centraliserad API** - En backend för alla formulär
- ✅ **Multi-frontend** - Separata appar för olika formulärtyper
- ✅ **Container-baserad** - Docker för enkel deployment
- ✅ **Azure-native** - Container Apps för skalning
- ✅ **TypeScript** - Type-safety i hela stacken
- ✅ **Modern UI** - React 18 med Vite
- ✅ **Database** - PostgreSQL med migrations
- ✅ **Production-ready** - CI/CD pipeline och monitoring

## 🛠️ Tech Stack

### Backend
- **FastAPI** - Modern Python web framework
- **SQLAlchemy** - ORM för databashantering
- **Alembic** - Database migrations
- **PostgreSQL** - Production database
- **Pydantic** - Data validation

### Frontend
- **React 18** - UI library
- **TypeScript** - Type safety
- **Vite** - Build tool och dev server
- **Modern CSS** - Responsiv design

### Infrastructure
- **Azure Container Apps** - Hosting platform
- **Azure Container Registry** - Image storage
- **Docker** - Containerization
- **GitHub Actions** - CI/CD pipeline

## 🏃‍♂️ Kom igång

### Lokal utveckling

```bash
# Klona projektet
git clone https://github.com/hsq-emilkarlsson/hsq-form-platform.git
cd hsq-form-platform

# Starta alla services med Docker Compose
docker-compose -f docker/docker-compose.yml up

# Eller kör individuellt:

# API Backend
cd apps/app
pip install -r requirements.txt
uvicorn app.main:app --reload

# Feedback Form
cd apps/form-feedback
npm install
npm run dev

# Support Form
cd apps/form-support
npm install
npm run dev
```

### Environment Variables

Skapa `.env` filer i respektive app-mapp:

```bash
# apps/form-feedback/.env
VITE_API_URL=http://localhost:3001

# apps/form-support/.env  
VITE_API_URL=http://localhost:3001

# apps/app/.env
DATABASE_URL=postgresql://user:pass@localhost/hsq_forms
```

## 📁 Projektstruktur

```
hsq-form-platform/
├── apps/                    # Applikationer
│   ├── app/                # API Backend (FastAPI)
│   ├── form-feedback/       # Feedbackformulär (React)
│   └── form-support/       # Supportformulär (React)
├── packages/               # Delade paket
│   ├── schemas/           # Gemensamma datascheman
│   └── shared-ui/         # UI-komponenter
├── docker/                # Docker konfiguration
├── docs/                  # Dokumentation
├── deploy-azure.sh        # Azure deployment script
└── DEPLOYMENT_STATUS.md   # Deployment status
```

## 🔄 API Endpoints

### Formulär
- `POST /submit` - Skicka in formulärdata
- `GET /submissions` - Hämta tidigare inlämningar
- `GET /submission/{id}` - Hämta specifik inlämning
- `PUT /submission/{id}/status` - Uppdatera status

### Metadata
- `GET /` - API information och dokumentation
- `GET /docs` - Interactive API documentation
- `GET /health` - Health check endpoint

## 🚢 Deployment

Projektet är automatiskt deployt till Azure Container Apps med:

```bash
# Bygg och pusha images
./deploy-azure.sh

# Eller manuellt:
docker build -t hsqformsprodacr1748847162.azurecr.io/hsq-forms-api:latest apps/app/
docker push hsqformsprodacr1748847162.azurecr.io/hsq-forms-api:latest

az containerapp update --name hsq-forms-api \
  --resource-group rg-hsq-forms-prod-westeu \
  --image hsqformsprodacr1748847162.azurecr.io/hsq-forms-api:latest
```

## 🚀 Azure Deployment (Production)

Se även: `docs/AZURE_DEPLOYMENT_GUIDE.md` för detaljerad steg-för-steg-guide.

### Sammanfattning av produktionsflöde

1. **Bygg och pusha Docker-images**
   - Använd Container Registry: `hsqformsprodacr1748847162.azurecr.io`
   - Bygg och pusha images för backend och frontend enligt guiden.

2. **Uppdatera Container Apps**
   - Gå till Azure Portal → resursgrupp `rg-hsq-forms-prod-westeu`.
   - Uppdatera image-taggar för:
     - `hsq-forms-api`
     - `ca-hsq-feedback-form`
     - `hsq-forms-support`

3. **Miljövariabler och secrets**
   - Hantera känsliga värden via Azure Portal → "Secrets" för respektive app.
   - Kontrollera att Storage Account (`hsqformsstorage`) används för filuppladdningar.

4. **Verifiera deployment**
   - Kontrollera att apparna startar korrekt och har status "Running".
   - Testa API och frontend i produktion.
   - Kontrollera loggar i Log Analytics Workspace (`hsq-forms-logs-workspace`).

5. **Rensning och underhåll**
   - Ta bort gamla images och överflödiga resurser vid behov.
   - Rensa gamla revisioner av Container Apps.

6. **Felsökning**
   - Se `docs/AZURE_DEPLOYMENT_GUIDE.md` för felsökningstips och logghantering.

---

**Tips:**
- Använd alltid rätt Container Registry och resursgrupp.
- Uppdatera denna README och deployment-guiden vid förändringar i flödet.

## 📊 Monitoring

- **Azure Application Insights** - Performance monitoring
- **Container logs** - Real-time logging
- **Health checks** - Endpoint monitoring
- **Resource metrics** - CPU, Memory, Request metrics

## 🤝 Bidra

1. Fork projektet
2. Skapa en feature branch (`git checkout -b feature/amazing-feature`)
3. Commit dina ändringar (`git commit -m 'Add amazing feature'`)
4. Push till branchen (`git push origin feature/amazing-feature`)
5. Öppna en Pull Request

## 📝 Licens

Detta projekt är licensierat under MIT License - se [LICENSE](LICENSE) filen för detaljer.

## 👥 Team

- **Emil Karlsson** - [@hsq-emilkarlsson](https://github.com/hsq-emilkarlsson)

---

**🏢 Husqvarna Group**  
*Modern formulärhantering för framtidens digitala upplevelser*
