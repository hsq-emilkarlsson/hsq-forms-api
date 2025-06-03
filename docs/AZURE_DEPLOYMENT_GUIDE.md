# HSQ Forms API – Azure Deployment Guide

Senast uppdaterad: 2025-06-02

## 1. Förberedelser
- Kontrollera att du har rätt behörighet till Azure och Container Registry.
- Se till att du har senaste versionen av koden i din lokala miljö.
- Kontrollera att `.env`-filer och secrets är korrekt konfigurerade för produktion.

## 2. Bygg och pusha Docker-images

Bygg backend och frontend images lokalt:

```zsh
# Backend (API)
cd apps/app

docker build -t hsq-forms-api:latest .
docker tag hsq-forms-api:latest hsqformsprodacr1748847162.azurecr.io/hsq-forms-api:latest
docker push hsqformsprodacr1748847162.azurecr.io/hsq-forms-api:latest

# Frontend (Feedback Form)
cd ../form-feedback
docker build -t hsq-feedback-form:latest .
docker tag hsq-feedback-form:latest hsqformsprodacr1748847162.azurecr.io/hsq-feedback-form:latest
docker push hsqformsprodacr1748847162.azurecr.io/hsq-feedback-form:latest

# Frontend (Support Form)
cd ../form-support
docker build -t hsq-forms-support:latest .
docker tag hsq-forms-support:latest hsqformsprodacr1748847162.azurecr.io/hsq-forms-support:latest
docker push hsqformsprodacr1748847162.azurecr.io/hsq-forms-support:latest
```

## 3. Uppdatera Container Apps i Azure

1. Gå till Azure Portal → din resursgrupp `rg-hsq-forms-prod-westeu`.
2. Välj respektive Container App (`hsq-forms-api`, `ca-hsq-feedback-form`, `hsq-forms-support`).
3. Klicka på "Containers" och ange den nya image-taggen (t.ex. `hsqformsprodacr1748847162.azurecr.io/hsq-forms-api:latest`).
4. Spara och rulla ut ny revision.

## 4. Kontrollera deployment

- Kontrollera att alla Container Apps startar korrekt och har status "Running".
- Testa API-endpoints och frontend i produktion.
- Kontrollera loggar i Azure Portal (Log Analytics Workspace: `hsq-forms-logs-workspace`).

## 5. Hantera miljövariabler och secrets

- Hantera känsliga värden (t.ex. databaslösenord) via Azure Portal → "Secrets" för respektive Container App.
- Kontrollera att Storage Account (`hsqformsstorage`) och Container Registry (`hsqformsprodacr1748847162`) är korrekt kopplade.

## 6. Rensning och underhåll

- Ta bort överflödiga Container Registries och gamla images vid behov.
- Kontrollera att endast en Storage Account används för filuppladdningar.
- Rensa gamla, ej använda revisioner av Container Apps.

## 7. Felsökning

- Kontrollera loggar i Log Analytics Workspace vid problem.
- Kontrollera att rätt image används i Container Apps.
- Kontrollera att alla miljövariabler är korrekt satta.

## 8. Dokumentation

- Uppdatera denna guide vid förändringar i deployment-flödet.
- Dokumentera eventuella specialfall eller manuella steg.

---

**Tips:**
- Använd alltid den Container Registry som är kopplad till produktion: `hsqformsprodacr1748847162.azurecr.io`.
- Kontrollera alltid status på Container Apps efter deployment.
- Spara denna guide i projektets `docs/`-mapp.
