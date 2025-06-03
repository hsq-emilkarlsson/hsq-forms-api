# 🚀 HSQ Forms API

> **FastAPI backend för HSQ formulärplattform**  
> Deployed på Azure Container Apps med PostgreSQL databas

## 🏗️ Arkitektur

- **Backend**: FastAPI med PostgreSQL
- **Storage**: Lokal fillagring för utveckling, Azure Blob för produktion
- **Deployment**: Azure Container Apps
- **Frontend**: Separata repositories med Azure Static Web Apps

## 🛠️ Lokal utveckling

### Med Docker Compose (Rekommenderat)
```bash
docker-compose -f docker/docker-compose.yml up
```

### Utan Docker
```bash
cd apps/app
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

API:et är tillgängligt på `http://localhost:8000`  
Swagger dokumentation: `http://localhost:8000/docs`

## 🗄️ Databas

### Lokalt (PostgreSQL via Docker)
```bash
# Kör migreringar
cd apps/app
alembic upgrade head
```

### Produktion (Azure PostgreSQL)
Databas-credentials hanteras via environment variables i Azure Container Apps.

## 📁 Projektstruktur

```
hsq-forms-api/
├── apps/app/               # FastAPI backend
│   ├── app/               # Applikationskod
│   │   ├── main.py        # FastAPI app
│   │   ├── models.py      # SQLAlchemy modeller
│   │   ├── schemas.py     # Pydantic scheman
│   │   ├── crud.py        # Database operations
│   │   └── routers/       # API routes
│   ├── alembic/           # Database migrations
│   ├── Dockerfile         # Container definition
│   └── requirements.txt   # Python dependencies
├── docker/                # Docker Compose för lokal utveckling
├── infra/                 # Azure Bicep infrastructure
├── docs/                  # Dokumentation
├── deploy-simple.sh       # Enkel deployment
└── deploy-backend-update.sh # Backend uppdatering
```

## 🚀 Deployment

### Snabb backend-uppdatering
```bash
./deploy-simple.sh
```

### Första deployment (Infrastructure)
```bash
./deploy-backend-update.sh
```

## 🔧 API Endpoints

- `POST /api/forms/submit` - Skicka formulärinlämning
- `POST /api/files/upload` - Ladda upp filer
- `GET /api/files/{file_id}` - Hämta uppladdad fil
- `GET /docs` - Swagger dokumentation
- `GET /health` - Hälsokontroll

## 🌍 Environment Variables

```bash
# apps/app/.env
DATABASE_URL=postgresql://user:pass@localhost/hsq_forms
ALLOWED_ORIGINS=http://localhost:3000,https://yourfrontend.com
AZURE_STORAGE_CONNECTION_STRING=...  # För produktion
```

## 📋 Vanliga kommandon

```bash
# Skapa ny Alembic migration
cd apps/app && alembic revision --autogenerate -m "Description"

# Kör migreringar
cd apps/app && alembic upgrade head

# Testa API lokalt
curl -X POST http://localhost:8000/api/forms/submit \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","message":"Hello"}'
```

## 🔗 Relaterade Repositories

- **Frontend Forms**: Separata repos för varje formulär
- **Infrastructure**: Bicep templates i `/infra/`

## 📄 Licens

MIT License - se LICENSE fil för detaljer.