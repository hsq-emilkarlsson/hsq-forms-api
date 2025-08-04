# Miljöhantering i HSQ Forms API

## Översikt

HSQ Forms API är konfigurerat för att köras i olika miljöer (development, production) med tydlig separation mellan dessa. Miljökonfigurationen påverkar:

- Docker images och taggning
- Konfigurationsinställningar
- API-beteende
- Loggning och felsökning
- Deployment-processen

## Miljöer

### Development (Dev)

Utvecklingsmiljön är optimerad för snabb utveckling och felsökning:

- **Namnstandard**: Alla resurser har `-dev` suffix
- **Registry**: `hsqformsdevacr.azurecr.io`
- **Image namn**: `hsq-forms-api-dev`
- **Funktioner**:
  - API-dokumentation tillgänglig (`/docs` och `/redoc`)
  - Debugläge aktiverat
  - CORS tillåter alla ursprung (`*`)
  - Hot-reloading av kod

### Production (Prod)

Produktionsmiljön är optimerad för säkerhet och prestanda:

- **Namnstandard**: Inga suffix (ren namnstandard)
- **Registry**: `hsqformsprodacr.azurecr.io`
- **Image namn**: `hsq-forms-api`
- **Funktioner**:
  - API-dokumentation inaktiverad
  - Debugläge inaktiverat
  - CORS strikt konfigurerat
  - Optimerad för prestanda

## Docker-konfiguration

### Utveckling

För utveckling, använd någon av följande:

```bash
# Enkel utveckling med standard docker-compose
docker-compose up -d

# Explicit utvecklingsmiljö
docker-compose -f docker-compose.dev.yml up -d

# Med deploy-skript
./scripts/deploy.sh --env dev
```

### Produktion

För produktion:

```bash
# Med docker-compose
docker-compose -f docker-compose.prod.yml up -d

# Med deploy-skript
./scripts/deploy.sh --env prod
```

## CI/CD Pipeline

GitHub Actions-konfigurationen är uppsatt för att hantera båda miljöerna:

1. **Development Pipeline**:
   - Triggas av push till `develop`-branch
   - Bygger och taggar med `-dev` suffix
   - Använder Dockerfile för utvecklingsimage
   - Deployar till dev-miljön i Azure

2. **Production Pipeline**:
   - Triggas av GitHub-taggar (t.ex. `v1.0.0`)
   - Bygger utan suffix
   - Använder `Dockerfile.prod` för optimerad produktionsimage
   - Deployar till produktionsmiljön i Azure

## Miljövariabler

Applikationen använder `APP_ENVIRONMENT`-variabeln för att avgöra vilka inställningar som ska användas. Detta sätts:

1. Via Docker build arg i Dockerfile
2. Som miljövariabel i container
3. I GitHub Actions workflow

## Lokal utveckling med registrybilder

Om du vill använda images från registry:

```bash
# Logga in på ACR
az acr login --name hsqformsdevacr

# Hämta senaste dev-imagen
docker pull hsqformsdevacr.azurecr.io/hsq-forms-api-dev:latest

# Kör med rätt miljövariabler
docker run -p 8000:8000 -e APP_ENVIRONMENT=development hsqformsdevacr.azurecr.io/hsq-forms-api-dev:latest
```

## Att tänka på vid utveckling

1. **Namnstandard**: Följ namnstandarderna konsekvent:
   - Dev: allt har `-dev` suffix
   - Prod: rena namn utan suffix

2. **Konfiguration**: 
   - Läs miljövariabeln `APP_ENVIRONMENT` för miljöspecifika inställningar
   - Använd striktare inställningar i prod

3. **Secrets**:
   - Använd miljöspecifika secrets i GitHub
   - Lagra aldrig känsliga uppgifter i kod

4. **Azure-resurser**:
   - Håll separata resursgrupper för dev och prod
   - Följ namnstandarder för alla Azure-resurser
