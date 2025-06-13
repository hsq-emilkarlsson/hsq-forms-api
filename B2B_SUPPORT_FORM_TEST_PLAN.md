# B2B Support Form - Testplan

## Testmiljö
- **Docker Container**: `b2b-support-form:latest`
- **URL**: http://localhost:3005
- **Testdatum**: 2025-06-09

## Test 1: Grundläggande UI-kontroll
### Förväntade fält:
- [x] Supporttyp (dropdown: Allmän support, Teknisk support)
- [x] Kundnummer (textfält, obligatoriskt)
- [x] E-postadress (textfält, obligatoriskt)
- [x] Meddelande (textarea, obligatoriskt)
- [x] Filuppladdning (valfritt)

### Villkorliga fält (visas endast för "Teknisk support"):
- [x] Serienummer (textfält)
- [x] PNC-nummer (textfält)

## Test 2: Valideringstest
### Test 2.1: Tomma obligatoriska fält
**Steg:**
1. Lämna alla fält tomma
2. Klicka "Skicka meddelande"
**Förväntat resultat:** Alert "Vänligen fyll i alla obligatoriska fält"

### Test 2.2: Felaktig e-postadress
**Steg:**
1. Fyll i: Supporttyp, Kundnummer, Meddelande
2. Ange felaktig e-post (t.ex. "test")
3. Klicka "Skicka meddelande"
**Förväntat resultat:** Alert "Vänligen ange en giltig e-postadress"

### Test 2.3: Partiellt ifyllt formulär
**Steg:**
1. Välj supporttyp
2. Fyll i kundnummer
3. Lämna e-post tom
4. Klicka "Skicka meddelande"
**Förväntat resultat:** Valideringsfel

## Test 3: Teknisk support - villkorliga fält
**Steg:**
1. Välj "Teknisk support" från dropdown
2. Kontrollera att Serienummer och PNC-nummer fält visas
3. Växla till "Allmän support"
4. Kontrollera att de tekniska fälten försvinner

## Test 4: Komplett formulärinlämning
**Steg:**
1. Välj supporttyp: "Allmän support"
2. Ange kundnummer: "CUST12345"
3. Ange e-post: "test@example.com"
4. Ange meddelande: "Detta är ett testmeddelande"
5. Klicka "Skicka meddelande"
**Förväntat resultat:** Formulär skickas framgångsrikt

## Test 5: Teknisk support komplett
**Steg:**
1. Välj supporttyp: "Teknisk support"
2. Ange kundnummer: "CUST67890"
3. Ange e-post: "tech@example.com"
4. Ange serienummer: "SN123456"
5. Ange PNC-nummer: "PNC789012"
6. Ange meddelande: "Tekniskt problem med produkten"
7. Klicka "Skicka meddelande"
**Förväntat resultat:** Formulär skickas framgångsrikt

## Test 6: Filuppladdning
**Steg:**
1. Fyll i obligatoriska fält
2. Välj en fil för uppladdning
3. Skicka formulär
**Förväntat resultat:** Fil inkluderas i inlämningen

---

## Testresultat

| Test | Status | Kommentarer |
|------|--------|-------------|
| 1. UI-kontroll | ⏳ | |
| 2.1 Tomma fält | ⏳ | |
| 2.2 Fel e-post | ⏳ | |
| 2.3 Partiellt | ⏳ | |
| 3. Villkorliga fält | ⏳ | |
| 4. Komplett allmän | ⏳ | |
| 5. Komplett teknisk | ⏳ | |
| 6. Filuppladdning | ⏳ | |

**Legenda:**
- ⏳ Ej testat
- ✅ Godkänt
- ❌ Misslyckades
- ⚠️ Delvis godkänt

---

## Buggrapporter

### Bug #1
**Beskrivning:**
**Steg för att återskapa:**
**Förväntat beteende:**
**Faktiskt beteende:**
**Prioritet:** Hög/Medium/Låg
