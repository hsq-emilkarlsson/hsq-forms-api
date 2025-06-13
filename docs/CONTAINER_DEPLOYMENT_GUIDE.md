# Container Deployment Guide

Detta dokument beskriver hur du deployar HSQ Forms API som containers och uppdaterar med nya images.

## Översikt

Projektet stöder flera deployment strategier:
- **Lokal utveckling**: Docker Compose för utveckling
- **Production deployment**: Blue-green deployment med rollback
- **Container registry**: Push/pull från externa registries
- **CI/CD**: Automatiserad deployment via GitHub Actions

## Filer för Container Deployment

```
docker-compose.yml          # Utvecklings-setup
docker-compose.prod.yml     # Production-setup
Dockerfile                  # Grundläggande image
Dockerfile.prod            # Optimerad production image
.env.production.template   # Environment template
scripts/
├── deploy-production.sh   # Production deployment script
├── registry-deploy.sh     # Container registry deployment
└── deploy-container.sh    # Lokal deployment (befintlig)
.github/workflows/
└── deploy.yml            # CI/CD pipeline
```

## Snabbstart - Production Deployment

### 1. Förbered miljön

```bash
# Kopiera environment template
cp .env.production.template .env.production

# Redigera med dina produktionsvärden
nano .env.production
```

### 2. Deploy till produktion

```bash
# Enkel deployment med senaste version
./scripts/deploy-production.sh deploy

# Deploy med specifik version
./scripts/deploy-production.sh deploy v1.2.3

# Visa deployment status
./scripts/deploy-production.sh status
```

## Detaljerade Deployment Strategier

### Lokal Utveckling

```bash
# Starta utvecklingsmiljö
docker-compose up -d

# Bygg och starta med nya ändringar
./scripts/deploy-container.sh local

# Stoppa utvecklingsmiljö
docker-compose down
```

### Production Deployment

Production deployment använder blue-green strategi för zero-downtime updates:

```bash
# Full production deployment
./scripts/deploy-production.sh deploy v1.2.3
```

Detta gör:
1. ✅ Bygger ny production image
2. 🔄 Skapar backup av nuvarande deployment
3. 🛑 Stoppar gamla containers gracefully
4. 🚀 Startar nya containers
5. 🏥 Väntar på health checks
6. 🧹 Städar upp gamla images

### Container Registry Deployment

För externa registries (Azure Container Registry, Docker Hub, etc.):

```bash
# Bygg och pusha till registry
./scripts/registry-deploy.sh push v1.2.3

# Deploy från registry
./scripts/registry-deploy.sh deploy v1.2.3

# Full pipeline (build + push + deploy)
./scripts/registry-deploy.sh full-deploy v1.2.3

# Lista tillgängliga images
./scripts/registry-deploy.sh list
```

## Environment Konfiguration

### Production Environment (.env.production)

```bash
# Applikationsinställningar
API_PORT=8000
ENVIRONMENT=production
LOG_LEVEL=INFO
SECRET_KEY=your-super-secret-key
VERSION=v1.2.3

# Databas
DB_NAME=hsqforms
DB_USER=hsqforms
DB_PASSWORD=secure-password
DB_PORT=5432

# CORS (kommaseparerade URLer)
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Container Registry
REGISTRY_URL=your-registry.azurecr.io
REGISTRY_USERNAME=your-username
REGISTRY_PASSWORD=your-password

# Deployment inställningar
DEPLOY_TIMEOUT=300
HEALTH_CHECK_TIMEOUT=60
BACKUP_BEFORE_DEPLOY=true
```

## Uppdatera med Nya Images

### Manuell Uppdatering

```bash
# 1. Bygg ny image med version
./scripts/deploy-production.sh build v1.3.0

# 2. Deploy den nya versionen
./scripts/deploy-production.sh deploy v1.3.0
```

### Automatisk CI/CD Uppdatering

GitHub Actions workflow körs automatiskt vid:
- **Push till `main`**: Deploy till production (om taggad)
- **Push till `develop`**: Deploy till staging
- **Pull requests**: Kör tester och säkerhetsscanning

```bash
# Tagga ny version för production release
git tag v1.3.0
git push origin v1.3.0

# Detta triggar automatisk production deployment
```

## Rollback

### Snabb Rollback

```bash
# Lista tillgängliga backups
ls -la backups/

# Rollback till specifik backup
./scripts/deploy-production.sh rollback backups/deployment-20240608-143022
```

### Registry Rollback

```bash
# Deploy tidigare version från registry
./scripts/registry-deploy.sh deploy v1.2.2
```

## Monitoring och Debugging

### Health Checks

Applikationen har inbyggda health checks:

```bash
# Kontrollera applikationshälsa
curl http://localhost:8000/health

# Detaljerad status
./scripts/deploy-production.sh status
```

### Container Logs

```bash
# Visa senaste logs
docker-compose -f docker-compose.prod.yml logs --tail=50 api

# Följ logs i realtid
docker-compose -f docker-compose.prod.yml logs -f api

# Visa alla container logs
docker-compose -f docker-compose.prod.yml logs
```

### Container Metrics

```bash
# Container statistik
docker stats hsq-forms-api-prod

# Detaljerad container info
docker inspect hsq-forms-api-prod
```

## Säkerhet

### Production Dockerfile Säkerhetsfunktioner

- 🚫 **Non-root user**: Kör som `appuser` istället för root
- 🔒 **No new privileges**: Förhindrar privilege escalation
- 🏥 **Health checks**: Automatisk hälsokontroll
- 📦 **Multi-stage build**: Mindre images, färre attack vectors
- 🧹 **Minimal base image**: Python 3.11-slim

### Environment Säkerhet

```bash
# Säkra file permissions
chmod 600 .env.production

# Använd secrets för känslig data
# Undvik att commit .env.production till git
echo ".env.production" >> .gitignore
```

## Azure Deployment

För Azure-specifik deployment, se [Azure Deployment Guide](docs/AZURE_DEPLOYMENT_GUIDE.md).

### Azure Container Instances

```bash
# Exempel på Azure deployment
az container create \
  --resource-group hsq-forms-rg \
  --name hsq-forms-api \
  --image your-registry.azurecr.io/hsq-forms-api:v1.2.3 \
  --dns-name-label hsq-forms-api \
  --ports 8000 \
  --environment-variables ENVIRONMENT=production \
  --secure-environment-variables SECRET_KEY=$SECRET_KEY DATABASE_URL=$DATABASE_URL
```

## Troubleshooting

### Vanliga Problem

1. **Health check timeout**:
   ```bash
   # Kontrollera container logs
   docker-compose -f docker-compose.prod.yml logs api
   
   # Öka timeout i .env.production
   HEALTH_CHECK_TIMEOUT=120
   ```

2. **Database connection issues**:
   ```bash
   # Kontrollera databas container
   docker-compose -f docker-compose.prod.yml logs db
   
   # Testa databas anslutning
   docker exec -it hsq-forms-db-prod psql -U hsqforms -d hsqforms
   ```

3. **Image build failures**:
   ```bash
   # Bygg med verbose output
   docker build -f Dockerfile.prod -t hsq-forms-api:debug . --progress=plain
   
   # Rensa Docker cache
   docker builder prune -a
   ```

### Support

För ytterligare hjälp:
1. Kontrollera container logs
2. Verifiera environment variabler
3. Testa health endpoints
4. Kontrollera network connectivity

## Exempel på Komplett Deployment Workflow

```bash
# 1. Förbered ny version
git checkout main
git pull origin main
git tag v1.3.0

# 2. Testa lokalt
./scripts/deploy-container.sh local
curl http://localhost:8000/health

# 3. Deploy till production
cp .env.production.template .env.production
# Redigera .env.production med production värden
./scripts/deploy-production.sh deploy v1.3.0

# 4. Verifiera deployment
./scripts/deploy-production.sh status
curl http://your-production-domain/health

# 5. Om något går fel - rollback
./scripts/deploy-production.sh rollback backups/deployment-20240608-143022
```

Detta ger dig en komplett, produktionsredo container deployment med automatisk CI/CD, rollback capabilities och säkerhetsoptimering.
