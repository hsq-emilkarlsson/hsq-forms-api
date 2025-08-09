# HSQ Forms API Diagnostikverktyg

Detta är ett paket med verktyg för att felsöka och testa kommunikationen mellan HSQ Forms och API:et.

## Översikt

Det finns två huvudsakliga verktyg:

1. **API-diagnostikskript** (Bash): Ett kommandoradsverktyg för att testa API-anslutning, CORS, autentisering, m.m.
2. **JavaScript-debugger**: Ett klientbaserat verktyg för att övervaka och logga API-anrop direkt i webbläsaren.

## 1. API-diagnostikskript

Detta Bash-skript hjälper dig att testa anslutningen till API:et från kommandoraden.

### Användning

```bash
cd /workspaces/hsq-forms-api
./scripts/api-diagnostics.sh
```

### Funktioner

- Kontrollera API-tillgänglighet
- Testa CORS-konfiguration
- Testa API-autentisering med API-nyckel
- Testa formulärsinlämning
- Samla in information om API-konfiguration

### Exempel

```
========================================
  HSQ Forms API Diagnostikverktyg  
========================================

Välj ett diagnostiktest att köra:
1) Kontrollera API-tillgänglighet
2) Testa CORS-konfiguration
3) Testa API-autentisering
4) Testa formulärsinlämning
5) Samla in API-konfiguration
6) Kör alla tester
7) Ändra API URL (nuvarande: https://hsq-forms-dev-e8g5hhgpfwgabsg5.a03.azurefd.net)
8) Ändra API-nyckel (nuvarande: dev-api-key-1)
q) Avsluta
```

## 2. JavaScript-debugger

Detta JavaScript-verktyg hjälper dig att övervaka API-anrop direkt i webbläsaren.

### Installation

Lägg till följande rad i slutet av ditt HTML-formulär (innan </body>-taggen):

```html
<script src="https://hsq-forms-dev-e8g5hhgpfwgabsg5.a03.azurefd.net/scripts/hsq-forms-debugger.js"></script>
```

Alternativt kan du kopiera koden manuellt i webbläsarkonsolen.

### Användning

1. När skriptet är inläst visas en liten 🔍-ikon i det nedre högra hörnet av formuläret.
2. Klicka på ikonen för att visa debug-panelen.
3. Alla API-anrop kommer automatiskt att loggas i panelen.
4. Använd knappen "Testa API" för att utföra diagnostiktester.

### Funktioner

- Loggar alla API-anrop (fetch och XHR) med headers, request-body och response
- Visar tidtagning för API-anrop
- Testar anslutningen till API:et
- Visar CORS-headers
- Visar miljövariabler och konfiguration

## Felsökningsguide

### Vanliga problem och lösningar

#### 1. CORS-fel (Access-Control-Allow-Origin)

**Problem**: Formuläret kan inte anropa API:et på grund av CORS-begränsningar.

**Lösning**: 
- Kontrollera att API:et har korrekt CORS-konfiguration.
- Använd API-diagnostikskriptet för att testa CORS-konfigurationen.
- Verifiera att formulärets URL finns med i API:ets CORS-konfiguration.

#### 2. Autentiseringsfel (401 Unauthorized)

**Problem**: API:et nekar åtkomst med felmeddelandet "Unauthorized".

**Lösning**:
- Kontrollera att formuläret använder rätt API-nyckel.
- Verifiera att API-nyckeln skickas med rätt header-namn (X-API-Key).
- Använd JavaScript-debuggern för att verifiera att headern skickas korrekt.

#### 3. Nätverksfel (Failed to fetch)

**Problem**: Formuläret kan inte nå API:et på grund av nätverksfel.

**Lösning**:
- Kontrollera att API:et är online och tillgängligt.
- Verifiera att API-URL:en är korrekt.
- Kontrollera om det finns DNS-problem eller VNet-begränsningar.

#### 4. JSON-parsningsfel

**Problem**: API-anropet misslyckas med ett JSON-parsningsfel.

**Lösning**:
- Använd JavaScript-debuggern för att se exakt vilken data som skickas.
- Kontrollera att formuläret skickar korrekt formaterad JSON.
- Verifiera att alla obligatoriska fält finns med i begäran.

## Avancerad felsökning

### Kontrollera API-loggar

För att se API-loggarna i Azure:

1. Gå till Azure Portal
2. Navigera till App Service-resursen (hsq-forms-api-dev)
3. Välj "Loggar" eller "Logstream"
4. Filtrera efter felnivå (Error, Warning, etc.)

### Kontrollera API-konfiguration

För att verifiera API-konfigurationen:

1. Gå till Azure Portal
2. Navigera till App Service-resursen
3. Välj "Konfiguration"
4. Kontrollera att alla miljövariabler är korrekt konfigurerade

### Testa API med Postman

För mer avancerad API-testning, använd Postman:

1. Skapa en ny begäran i Postman
2. Ange API-URL:en (t.ex. https://hsq-forms-dev-e8g5hhgpfwgabsg5.a03.azurefd.net/api/v1/submissions)
3. Lägg till X-API-Key-headern med rätt API-nyckel
4. Skapa en JSON-body baserad på formulärets data
5. Skicka begäran och analysera svaret

## Kontakt och support

Om du stöter på problem som inte kan lösas med dessa verktyg, kontakta utvecklingsteamet.
