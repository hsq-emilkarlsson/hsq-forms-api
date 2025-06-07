# Steg för steg-guide för HSQ Forms API Template-projektet

Denna guide hjälper dig att komma igång med HSQ Forms API template-projektet inklusive flerspråksstödet.

## Innehållsförteckning

1. [Förutsättningar](#förutsättningar)
2. [Installation](#installation)
3. [Konfiguration](#konfiguration)
4. [Flerspråkshantering](#flerspråkshantering)
5. [Köra applikationen](#köra-applikationen)
6. [Anpassa formuläret](#anpassa-formuläret)
7. [Deployment](#deployment)
8. [Felsökning](#felsökning)

## Förutsättningar

För att köra HSQ Forms API template-projektet behöver du:

- Node.js 18.x eller senare
- npm 9.x eller senare
- Git
- Tillgång till HSQ Forms API-backend
- PostgreSQL-databas (för utveckling)

## Installation

1. Klona repository:

```bash
git clone https://github.com/your-organization/hsq-forms-api.git
cd hsq-forms-api
```

2. Installera backend-beroenden:

```bash
pip install -r requirements.txt
```

3. Installera frontend-beroenden:

```bash
cd templates/form-app-template
npm install
```

## Konfiguration

### Backend-konfiguration

1. Kopiera `.env.example` till `.env` och anpassa den:

```bash
cp .env.example .env
```

2. Uppdatera databasanslutningen i `.env`-filen:

```
DATABASE_URL=postgresql://username:password@localhost:5432/hsq_forms_db
```

3. **VIKTIGT**: Kör databasmigrationen för flerspråksstöd:

```bash
# Från projektets rotmapp
bash scripts/apply_language_migration.sh
```

Denna migration är nödvändig för att lägga till språkkolumner i databasen:
- `default_language`
- `available_languages` 
- `translations`

### Frontend-konfiguration

1. I `templates/form-app-template`, kopiera `.env.example` till `.env.local`:

```bash
cd templates/form-app-template
cp .env.example .env.local
```

2. Anpassa `.env.local` med din backend-URL:

```
VITE_API_URL=http://localhost:8000/api
```

## Flerspråkshantering

HSQ Forms API stöder nu flerspråkiga formulär. Följ dessa steg för att använda flerspråksfunktionerna:

### 1. Språkspecifika endpoints

Backend-API:et erbjuder språkspecifika endpoints:

- `/en/templates` - Engelska formulär
- `/sv/templates` - Svenska formulär
- `/us/templates` - USA-specifika formulär (engelska)
- `/se/templates` - Sverigespecifika formulär (svenska)

För att hämta formulär för ett specifikt språk:

```typescript
import { getFormsByLanguage } from './api/formsApi';

// Hämta alla svenska formulär
const response = await getFormsByLanguage('sv');

// Hämta svenska formulär för ett specifikt projekt
const projectForms = await getFormsByLanguage('sv', 'project-name');
```

### 2. Språkval i frontend

Projektet använder i18next för översättning. Språk kan bytas på flera sätt:

- Via URL: `/en/form`, `/sv/form`
- Via språkväljaren i gränssnittet
- Automatisk detektering från webbläsare

Språkväljaren finns redan implementerad i `components/LanguageSelector.tsx`:

```jsx
<LanguageSelector 
  availableLanguages={['en', 'sv']} 
  currentLanguage={currentLanguage} 
/>
```

### 3. Lägga till nya översättningar

Översättningsfiler finns i:

- `/public/locales/en/translation.json` - Engelska
- `/public/locales/sv/translation.json` - Svenska

För att lägga till ett nytt språk:

1. Skapa en ny mapp under `/public/locales/`, t.ex. `/public/locales/no/`
2. Kopiera och översätt `translation.json`
3. Uppdatera tillgängliga språk i `src/i18n.ts`

### 4. Översätta formulärscheman

Formuläröversättningar lagras i databasen i `translations`-fältet. Exempel på formulärdata:

```json
{
  "title": "Kontaktformulär",
  "description": "Skicka ett meddelande",
  "default_language": "sv",
  "available_languages": ["sv", "en"],
  "translations": {
    "en": {
      "title": "Contact Form",
      "description": "Send us a message",
      "schema": {
        "properties": {
          "name": {
            "title": "Name",
            "description": "Your full name"
          }
        }
      }
    }
  }
}
```

## Köra applikationen

### Backend

Starta backend-servern:

```bash
# Från projektets rotmapp
python -m uvicorn src.forms_api.app:app --reload
```

### Frontend

Starta frontend-utvecklingsservern:

```bash
cd templates/form-app-template
npm run dev
```

Applikationen är nu tillgänglig på `http://localhost:5173`.

## Anpassa formuläret

### Skapa ett anpassat formulär

1. Definiera formulärschema enligt JSON Schema-standarden
2. Lägg till översättningar för varje språk du stödjer
3. Använd API:et för att skapa formulärtemplate:

```bash
curl -X POST http://localhost:8000/api/forms/templates \
  -H "Content-Type: application/json" \
  -d '{
    "name": "contact_form",
    "title": "Kontaktformulär",
    "description": "Skicka oss ett meddelande",
    "project_id": "website",
    "schema": { ... },
    "default_language": "sv",
    "available_languages": ["sv", "en"],
    "translations": {
      "en": {
        "title": "Contact Form",
        "description": "Send us a message",
        "schema": { ... }
      }
    }
  }'
```

### Anpassa frontend

1. Uppdatera `FormPage.tsx` för att visa formulärfälten
2. Anpassa stilar i `src/styles`
3. Lägg till valideringsregler i `src/hooks/useFormHook.ts`

## Deployment

### Förbereda för deployment

1. Bygg frontend-applikationen:

```bash
cd templates/form-app-template
npm run build
```

2. För att köra migrationen i produktionsmiljö:

```bash
# Se till att alembic-konfigurationen pekar på produktionsdatabas
export DATABASE_URL=your-production-db-url
bash scripts/apply_language_migration.sh
```

### Azure Static Web Apps

Se `AZURE_DEPLOYMENT.md` för detaljerade instruktioner om deployment till Azure Static Web Apps.

## Felsökning

### Problem med flerspråksstöd

1. **Formuläret visar inte korrekt språk**:
   - Kontrollera att URL:en innehåller rätt språkkod (`/en/`, `/sv/`)
   - Verifiera att formuläret har översättningar för det valda språket
   - Använd browserns utvecklarverktyg för att kontrollera API-anrop

2. **Migrationsfel**:
   - Om du får fel med "kolumner finns redan", kör `alembic current` för att se aktuell migrationsnivå
   - Kör `alembic history` för att se alla tillgängliga migrationer

3. **Språkväxling fungerar inte**:
   - Kontrollera att i18n är korrekt konfigurerat i `src/i18n.ts`
   - Verifiera att språkfiler finns i `/public/locales/{language}/translation.json`

För mer detaljerad information om flerspråksstöd, se `docs/MULTILINGUAL_SUPPORT.md`.

## Viktigt om databasmigrationen för flerspråksstöd

När du använder HSQ Forms API template-projektet måste du köra databasmigrationen för att stödja flerspråksfunktionerna. **Detta gäller även om du börjar med ett nytt projekt.**

Migrationen `5a7b9c0d1e2f_add_language_support.py` lägger till de kolumner som behövs i databasen:

```bash
# Från projektets rotmapp
bash scripts/apply_language_migration.sh
```

### Vad migrationen gör

Följande kolumner läggs till i tabellen `form_templates`:

1. `default_language` - Standardspråket för formulär (t.ex. "en", "sv")
2. `available_languages` - Lista med tillgängliga språk för varje formulär
3. `translations` - JSON-objekt med översättningar för olika språk

### Verifiering av migrationen

För att kontrollera att migrationen har körts:

```bash
alembic current
```

Du bör se migrationen `5a7b9c0d1e2f` listad som aktuell (head).

För mer information, se dokumentationen:
- [Migration Guide](../docs/MIGRATION_GUIDE.md)
- [Adding Translations](../docs/ADDING_TRANSLATIONS.md)
