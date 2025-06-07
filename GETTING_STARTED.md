# Kom igång med HSQ Forms API

Denna guide beskriver hur du startar projektet lokalt för utveckling och hur du deployar det.

## Starta projektet lokalt för utveckling

Det finns flera sätt att starta projektet för utvecklingsändamål:

### 1. Använd setup_dev.sh-skriptet för att förbereda miljön:

```bash
./scripts/setup_dev.sh
```

Detta script kommer att:
- Skapa nödvändiga mappar (uploads/temp, logs, backups)
- Skapa en .env-fil från .env-example om den inte finns
- Skapa en Python virtual environment
- Installera alla beroenden
- Göra alla scripts körbara

### 2. Starta utvecklingsservern:

Du kan starta utvecklingsservern på flera sätt:

#### Alternativ 1: Använda Makefile-kommandot:

```bash
make start-dev
```

#### Alternativ 2: Använda start-dev.sh-skriptet direkt:

```bash
./scripts/start-dev.sh
```

#### Alternativ 3: Starta med uvicorn direkt:

```bash
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

### 3. Alternativt: Starta med Docker Compose:

Om du föredrar att använda Docker:

```bash
make docker-compose-up
```

eller 

```bash
docker-compose up
```

Detta startar projektet och alla dess beroenden (t.ex. PostgreSQL) i Docker-containrar.

## Deployment av projektet

För att deploya projektet till Azure finns det detaljerad information i dokumentationen.

### 1. Läs Azure-deploymentguiden:

Se `docs/AZURE_DEPLOYMENT_GUIDE.md` för fullständig information.

### 2. Infrastruktur med Bicep:

Projektet använder Bicep för att definiera infrastrukturen. Filerna finns i `infra/`-mappen.

För att deploya infrastrukturen:

```bash
cd infra
az deployment group create --resource-group YOUR_RESOURCE_GROUP --template-file main.bicep --parameters main.parameters.json
```

### 3. Bygga Docker-image:

Bygg Docker-imagen för projektet:

```bash
make build-docker
```

eller

```bash
docker build -t hsq-forms-api .
```

### 4. Pusha Docker-imagen:

```bash
docker tag hsq-forms-api YOUR_CONTAINER_REGISTRY/hsq-forms-api:latest
docker push YOUR_CONTAINER_REGISTRY/hsq-forms-api:latest
```

### 5. Kör migrationer:

Innan du använder applikationen, se till att köra databasmigrationerna:

```bash
make migrate
```

eller

```bash
alembic upgrade head
```

## React Form Template

The project includes a ready-to-use React form template that connects to the HSQ Forms API. This can be used to quickly create form applications that work with the API.

### Using the Form Template

1. Copy the template to a new project folder:

```bash
cp -r templates/form-app-template /path/to/your-new-project
cd /path/to/your-new-project
```

2. Install dependencies:

```bash
npm install
```

3. Configure the API URL in `.env.local`:

```bash
cp .env.example .env.local
# Edit .env.local to set VITE_API_URL to your API endpoint
```

4. Start the development server:

```bash
npm run dev
```

### Template Features

The form template includes:

- Basic contact forms with validation
- File upload forms
- Dynamic form generation
- Azure integration for file storage
- Ready-to-use deployment configuration for Azure Static Web Apps

See `templates/form-app-template/README.md` for more details.

## Ytterligare information

- API-dokumentationen finns tillgänglig på `/docs` när applikationen körs lokalt
- För tester, kör `make test` eller `make test-cov` för att få kodtäckning
- För att se alla tillgängliga kommandon, kör `make help`
- För exempel på hur man använder API:et, se `examples/`-mappen
