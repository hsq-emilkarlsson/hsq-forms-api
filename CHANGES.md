# Uppdateringar för Azure-anslutningstestning

Detta commit innehåller följande uppdateringar:

1. **Pipeline-integration för Azure-anslutningstester**
   - Lagt till ett steg i Azure DevOps-pipelinen som automatiskt testar Azure-anslutningar efter deployment
   - Skriptet `scripts/test-azure-connection.py` är nu inkluderat i deployment-paketet

2. **Förbättrat testskript**
   - Mer användarvänliga felmeddelanden för lokal utveckling
   - Detektering av pipeline vs. lokal miljö
   - Returnerar olika exit-koder beroende på kontext

3. **Uppdaterad dokumentation**
   - Ny sektion i README.md om Azure-anslutningstestning
   - Information om hur man kör tester lokalt
   - Tydligare instruktioner om miljövariabler

4. **Förbättrad utvecklarupplevelse**
   - Uppdaterad `.env.example` med fler kommentarer och exempel
   - Lagt till `.gitignore` för att undvika att känsliga uppgifter checkas in

## Hur du testar

1. Pusha dessa ändringar till `develop`-branchen:
   ```bash
   git add .
   git commit -m "Integrera Azure-anslutningstester i pipeline"
   git push origin develop
   ```

2. Detta kommer att trigga Azure DevOps-pipelinen som:
   - Bygger och testar applikationen
   - Distribuerar Azure-resurser via Bicep
   - Distribuerar applikationen till App Service
   - Kör anslutningstesterna för att verifiera att allt fungerar

3. Följ build-processen i Azure DevOps och kontrollera att anslutningstesterna godkänns
