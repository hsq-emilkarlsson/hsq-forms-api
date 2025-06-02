# Azure Cosmos DB för Formulärplattformen

Detta dokument beskriver hur du konfigurerar och använder Azure Cosmos DB som backend för formulärplattformen.

## Lokal utveckling

### Alternativ 1: Azure Cosmos DB Emulator

För lokal utveckling kan du använda Azure Cosmos DB Emulator:

1. Docker Compose är redan uppsatt med en Cosmos DB Emulator-container
2. Starta miljön med:
   ```
   cd docker
   docker compose up -d
   ```
3. Notera att emulatorn kräver minst 3GB RAM

### Alternativ 2: Azure Cosmos DB-tjänst

För att använda en riktig Cosmos DB-instans:

1. Logga in på [Azure Portal](https://portal.azure.com)
2. Skapa en "Azure Cosmos DB for NoSQL"-resurs
3. Välj API: Core (SQL)
4. Skapa databas "formdb" och container "submissions" med partition key "/form_type"
5. Under "Keys", kopiera PRIMARY KEY och URI
6. Uppdatera .env-filen:
   ```
   COSMOS_ENDPOINT=https://your-cosmosdb.documents.azure.com:443/
   COSMOS_KEY=your-primary-key
   COSMOS_DATABASE=formdb
   COSMOS_CONTAINER=submissions
   ```

## Produktion i Azure

För produktionssättning i Azure:

1. Skapa en Azure Cosmos DB-resurs i samma region som din Container Apps-resurs
2. Sätt upp autoskalning vid behov
3. Konfigurera Azure Container Apps med miljövariabler för Cosmos DB-anslutningen
4. För maximal säkerhet, använd Azure Key Vault för att lagra COSMOS_KEY

## Datastruktur

Varje formulärinskickning sparas som ett dokument med strukturen:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "form_type": "contact",
  "name": "Anna Andersson",
  "email": "anna@example.com",
  "message": "Hej, jag har en fråga om produkten...",
  "metadata": {
    "source": "web",
    "page": "/products/lawn-mower"
  },
  "created_at": "2023-05-30T14:30:00Z",
  "ip_address": "192.168.1.1",
  "user_agent": "Mozilla/5.0...",
  "is_processed": false
}
```

## Fördelar med Cosmos DB jämfört med PostgreSQL

- **Global distribution** - Formulär kan tas emot från kunder globalt med låg latens
- **Skalbarhet** - Automatisk skalning vid höga volymer av formulär
- **Flexibla scheman** - Enkelt att lägga till nya formulärtyper utan schema-migrering
- **Integrerad med Azure ekosystemet** - Fungerar bra med Azure Functions, Logic Apps, etc.
- **Snabb utveckling** - Mindre behov av att hantera schema-migrering och DB-versioner
