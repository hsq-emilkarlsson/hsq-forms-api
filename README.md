# 🚀 HSQ Forms Platform

> **Multi-frontend form system med centraliserad API backend**  
> Byggd med React, FastAPI och deployed på Azure Container Apps

![Deployment Status](https://img.shields.io/badge/Deployment-✅%20Live-success?style=for-the-badge)
![Azure](https://img.shields.io/badge/Azure-Container%20Apps-0078d4?style=for-the-badge&logo=microsoft-azure)
![React](https://img.shields.io/badge/React-18-61dafb?style=for-the-badge&logo=react)
![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi)

## 🌐 Live Production URLs

| Component | URL | Status |
|-----------|-----|--------|
| **🔗 API Backend** | [hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io](https://hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io) | ✅ Running |
| **📝 Contact Form** | [ca-hsq-contact-form.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io](https://ca-hsq-contact-form.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io) | ✅ Running |
| **🎫 Support Form** | [hsq-forms-support.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io](https://hsq-forms-support.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io) | ✅ Running |

## 🏗️ Arkitektur

```
HSQ Forms Platform
├── 🔗 API Backend (FastAPI)
│   ├── Centraliserad formulärhantering
│   ├── Database med Alembic migrations
│   └── RESTful API endpoints
├── 📝 Contact Form (React + Vite)
│   ├── Kontaktformulär för allmänna förfrågningar
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

# Contact Form
cd apps/form-contact
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
# apps/form-contact/.env
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
│   ├── form-contact/       # Kontaktformulär (React)
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
