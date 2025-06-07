# Komma igång med HSQ Forms Template-projektet

Detta dokument ger dig en konkret, steg-för-steg guide för att komma igång med HSQ Forms API template-projektet, med särskilt fokus på flerspråksstödet.

## Innehållsförteckning

1. [Översikt](#översikt)
2. [Installation och uppsättning](#installation-och-uppsättning)
3. [Databasmigration för flerspråksstöd](#databasmigration-för-flerspråksstöd)
4. [Frontend-konfiguration](#frontend-konfiguration)
5. [Att arbeta med flerspråksformulär](#att-arbeta-med-flerspråksformulär)
6. [Testa flerspråksfunktionaliteten](#testa-flerspråksfunktionaliteten)
7. [Vanliga problem och lösningar](#vanliga-problem-och-lösningar)

## Översikt

HSQ Forms API template-projektet ger dig en komplett lösning för att:
- Skapa formulär på flera språk
- Skicka in formulärdata till API:et
- Hantera formulärdata i backend
- Integrera med externa system via webhooks

Från och med version 2.5.0 (juni 2025) har flerspråksstöd lagts till, vilket kräver att du kör en databasmigration.

## Installation och uppsättning

### 1. Klona projektet

```bash
git clone https://github.com/your-organization/hsq-forms-api.git
cd hsq-forms-api
```

### 2. Installera beroenden

Sätt upp backend:
```bash
# Skapa och aktivera en Python virtual environment (rekommenderas)
python -m venv venv
source venv/bin/activate  # För macOS/Linux

# Installera beroenden
pip install -r requirements.txt
```

Sätt upp frontend:
```bash
cd templates/form-app-template
npm install
```

### 3. Konfigurera miljövariabler

För backend:
```bash
# I projektroten
cp .env.example .env
```

Redigera `.env` och sätt:
```
DATABASE_URL=postgresql://username:password@localhost:5432/hsq_forms_db
```

För frontend:
```bash
# I templates/form-app-template
cp .env.example .env.local
```

Redigera `.env.local` och sätt:
```
VITE_API_URL=http://localhost:8000/api
```

## Databasmigration för flerspråksstöd

### 1. Konfigurera och kör migration

**VIKTIGT:** Du måste köra databasmigrationen även om du börjar med ett nytt projekt.

```bash
# Från projektroten
bash scripts/apply_language_migration.sh
```

Om scriptet inte körs av någon anledning, kör:

```bash
# Se till att du är i projektroten
export PYTHONPATH=$PYTHONPATH:$(pwd)
alembic upgrade head
```

### 2. Verifiera migrationen

Kontrollera att migrationen har körts:

```bash
alembic current
```

Utdatan bör visa att den senaste migrationen (`5a7b9c0d1e2f_add_language_support`) har körts.

### 3. Förstå migrationsändringarna

Denna migration lägger till följande kolumner i `form_templates` tabellen:

1. `default_language` (default: "en")
2. `available_languages` (default: ["en"]) 
3. `translations` (default: {})

## Frontend-konfiguration

### 1. Starta utvecklingsservern

```bash
# I backend-projektroten
python -m uvicorn src.forms_api.app:app --reload
```

I ett annat terminalfönster:

```bash
# I templates/form-app-template
npm run dev
```

### 2. Navigera till applikationen

Öppna [http://localhost:5173](http://localhost:5173) i webbläsaren.
Du ska automatiskt omdirigeras till [http://localhost:5173/en](http://localhost:5173/en).

## Att arbeta med flerspråksformulär

### 1. Skapa ett flerspråksformulär

Via API:et:

```bash
curl -X POST http://localhost:8000/api/forms/templates \
  -H "Content-Type: application/json" \
  -d '{
    "name": "contact_form",
    "title": "Kontaktformulär",
    "description": "Skicka ett meddelande",
    "project_id": "website",
    "schema": {
      "type": "object",
      "properties": {
        "name": {
          "type": "string",
          "title": "Namn"
        },
        "email": {
          "type": "string",
          "format": "email",
          "title": "E-post"
        },
        "message": {
          "type": "string",
          "title": "Meddelande"
        }
      },
      "required": ["name", "email", "message"]
    },
    "default_language": "sv",
    "available_languages": ["sv", "en"],
    "translations": {
      "en": {
        "title": "Contact Form",
        "description": "Send us a message",
        "schema": {
          "properties": {
            "name": {
              "title": "Name"
            },
            "email": {
              "title": "Email"
            },
            "message": {
              "title": "Message"
            }
          }
        }
      }
    }
  }'
```

### 2. Hämta formulär på ett specifikt språk

```bash
# Hämta alla svenska formulär
curl http://localhost:8000/api/sv/templates

# Hämta ett specifikt formulär på engelska
curl http://localhost:8000/api/forms/templates/{template_id}?language=en
```

### 3. Använda språkväljaren

I frontend-applikationen kan användaren:

- Byta språk via språkväljaren i gränssnittet
- Besöka URL:er med språkkod: `/en/form`, `/sv/form`

## Testa flerspråksfunktionaliteten

### 1. Testa API:et

```bash
# Hämta formulär på svenska
curl http://localhost:8000/api/sv/templates

# Hämta formulär på engelska
curl http://localhost:8000/api/en/templates

# Hämta ett specifikt formulär och schema på engelska
curl http://localhost:8000/api/forms/templates/{template_id}?language=en
curl http://localhost:8000/api/forms/templates/{template_id}/schema?language=en
```

### 2. Testa frontend

1. Öppna [http://localhost:5173/en](http://localhost:5173/en) för att se engelska versionen
2. Öppna [http://localhost:5173/sv](http://localhost:5173/sv) för att se svenska versionen
3. Klicka på språkväljaren för att växla mellan språken
4. Testa att skicka in formulärdata på båda språken

## Vanliga problem och lösningar

### Problem: Migrationsfel

**Symptom:** Felmeddelande när migrations-skriptet körs.

**Lösning:**
- Kontrollera att du har korrekt databas-URL i `.env`
- Kör `alembic history` för att se alla tillgängliga migrationer
- För mer hjälp, se [MIGRATION_GUIDE.md](/docs/MIGRATION_GUIDE.md)

### Problem: Formulär visar inte rätt språk

**Symptom:** Formuläret visas alltid på standardspråket trots att du valt annat språk.

**Lösning:**
- Kontrollera att URL:en innehåller språkkoden: `/sv/form`
- Verifiera att formuläret har översättningar för det önskade språket
- Inspektera API-anrop i webbläsarens utvecklarverktyg och se till att `language`-parametern skickas med

### Problem: React-appen startar inte

**Symptom:** Fel när du kör `npm run dev`.

**Lösning:**
- Kör `npm install` igen för att säkerställa att alla beroenden är installerade
- Kontrollera att Node.js version 18+ används (`node --version`)
- Se till att `.env.local` är korrekt konfigurerad

## Ytterligare resurser

- [Detaljerad GETTING_STARTED.md guide](/templates/form-app-template/GETTING_STARTED.md)
- [Dokumentation för flerspråksstöd](/docs/MULTILINGUAL_SUPPORT.md)
- [Migreringsguide](/docs/MIGRATION_GUIDE.md)
- [Guide för att lägga till översättningar](/docs/ADDING_TRANSLATIONS.md)

## Nästa steg

När du har kört migrationen och konfigurerat template-projektet:

1. Anpassa formulären efter dina behov
2. Lägg till fler språk vid behov
3. Integrera med dina befintliga system
4. Utforska webhooks för extern integrering

Lycka till med ditt HSQ Forms API-projekt!
