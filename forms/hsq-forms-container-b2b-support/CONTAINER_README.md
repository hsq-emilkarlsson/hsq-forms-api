# HSQ Forms - B2B Support Container

B2B Support Form med Husqvarna Group API-integration, paketerad som Docker-container för enkel distribution och körning.

## 🚀 Snabbstart från Docker Desktop

### Metod 1: Via Docker Desktop GUI
1. Öppna Docker Desktop
2. Gå till **Images** fliken
3. Hitta `hsq-forms-container-b2b-support:latest`
4. Klicka på **Run** knappen
5. Konfigurera port mapping: `3003:3003`
6. Lägg till miljövariabler (se nedan)
7. Klicka **Run**

### Metod 2: Via Docker Compose (Rekommenderat)
```bash
# Navigera till projektmappen
cd /Users/emilkarlsson/Documents/Dev/hsq-forms-api/forms/hsq-forms-container-b2b-support

# Starta containern
docker-compose up -d
```

### Metod 3: Via Docker CLI
```bash
docker run -d \
  --name hsq-forms-b2b-support \
  -p 3003:3003 \
  -e VITE_API_URL=http://localhost:8000/api \
  -e VITE_HUSQVARNA_API_BASE_URL=https://api-qa.integration.husqvarnagroup.com/hqw170/v1 \
  -e VITE_HUSQVARNA_API_KEY=3d9c4d8a3c5c47f1a2a0ec096496a786 \
  hsq-forms-container-b2b-support:latest
```

## 📱 Åtkomst

När containern körs är formuläret tillgängligt på:
- **URL**: http://localhost:3003
- **Port**: 3003

## 🔧 Miljövariabler

| Variabel | Beskrivning | Standard |
|----------|-------------|----------|
| `VITE_API_URL` | HSQ Forms API endpoint | `http://localhost:8000/api` |
| `VITE_HUSQVARNA_API_BASE_URL` | Husqvarna Group API bas-URL | `https://api-qa.integration.husqvarnagroup.com/hqw170/v1` |
| `VITE_HUSQVARNA_API_KEY` | Husqvarna Group API nyckel | `3d9c4d8a3c5c47f1a2a0ec096496a786` |

## 🔍 API Integration

### Triple Submission Architecture
Formuläret implementerar en robust tre-stegs arkitektur:

1. **Primär Submission** → HSQ Forms API (PostgreSQL)
2. **Kompletterande Submissions**:
   - Husqvarna Group Cases API (primärt externt system)
   - ESB System (fallback för CRM ticket creation)

### Customer Validation
3-stegs fallback-system för kundvalidering:
1. Husqvarna Group API validation
2. ESB validation (fallback)
3. Lokal regex validation (final fallback)

## 🏥 Health Check

Containern inkluderar automatisk hälsokontroll:
- **Endpoint**: `http://localhost:3003/`
- **Intervall**: 30 sekunder
- **Timeout**: 10 sekunder
- **Retries**: 3 försök

## 📊 Status Monitoring

### Från Docker Desktop
1. Gå till **Containers** fliken
2. Hitta `hsq-forms-b2b-support`
3. Kontrollera status-ikonen (grön = hälsosam)

### Via CLI
```bash
# Kontrollera container status
docker ps | grep hsq-forms-b2b-support

# Se logs
docker logs hsq-forms-b2b-support

# Följ logs i realtid
docker logs -f hsq-forms-b2b-support
```

## 🛠 Utveckling

### Bygga om containern
```bash
# Bygg ny version
docker build -t hsq-forms-container-b2b-support:latest .

# Uppdatera och starta om
docker-compose down && docker-compose up -d
```

### Testning
```bash
# Kör API integration tests
node test-api-integration.js
```

## 🔄 Stops och Restarts

### Via Docker Desktop
1. Gå till **Containers** fliken
2. Hitta `hsq-forms-b2b-support`
3. Använd **Stop**/**Start**/**Restart** knapparna

### Via CLI
```bash
# Stoppa container
docker stop hsq-forms-b2b-support

# Starta container
docker start hsq-forms-b2b-support

# Starta om container
docker restart hsq-forms-b2b-support
```

## 📋 Troubleshooting

### Container startar inte
1. Kontrollera att port 3003 inte används av annan process
2. Verifiera att imagen finns: `docker images | grep hsq-forms-container-b2b-support`
3. Kontrollera logs: `docker logs hsq-forms-b2b-support`

### API Integration Issues
1. Kontrollera nätverksanslutning till HSQ Forms API
2. Verifiera Husqvarna Group API credentials
3. Testa endpoints manuellt med test script

### Health Check Failures
1. Vänta 40 sekunder efter start (start_period)
2. Kontrollera att port 3003 svarar internt
3. Kontrollera container logs för fel

## 🎯 Production Deployment

För production-deployment:
1. Uppdatera API URLs till production endpoints
2. Säkra API nycklar med Docker secrets eller external config
3. Använd reverse proxy (nginx) för SSL/TLS termination
4. Implementera logging aggregation
5. Sätt upp monitoring och alerting

## 📝 Version Info

- **Version**: 1.0.0
- **Build Date**: 2025-06-10
- **Node.js**: 18-alpine
- **Framework**: React + Vite
- **Port**: 3003

## 🔗 Relaterade Länkar

- [HSQ Forms API Documentation](../../../docs/)
- [Husqvarna Group API Documentation](./HUSQVARNA_API_INTEGRATION.md)
- [Customer Code Routing Documentation](./CUSTOMER_CODE_ROUTING.md)
- [Implementation Status](./IMPLEMENTATION_COMPLETE.md)
