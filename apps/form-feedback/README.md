# React + TypeScript + Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh

## Expanding the ESLint configuration

If you are developing a production application, we recommend updating the configuration to enable type-aware lint rules:

```js
export default tseslint.config({
  extends: [
    // Remove ...tseslint.configs.recommended and replace with this
    ...tseslint.configs.recommendedTypeChecked,
    // Alternatively, use this for stricter rules
    ...tseslint.configs.strictTypeChecked,
    // Optionally, add this for stylistic rules
    ...tseslint.configs.stylisticTypeChecked,
  ],
  languageOptions: {
    // other options...
    parserOptions: {
      project: ['./tsconfig.node.json', './tsconfig.app.json'],
      tsconfigRootDir: import.meta.dirname,
    },
  },
})
```

You can also install [eslint-plugin-react-x](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-x) and [eslint-plugin-react-dom](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-dom) for React-specific lint rules:

```js
// eslint.config.js
import reactX from 'eslint-plugin-react-x'
import reactDom from 'eslint-plugin-react-dom'

export default tseslint.config({
  plugins: {
    // Add the react-x and react-dom plugins
    'react-x': reactX,
    'react-dom': reactDom,
  },
  rules: {
    // other rules...
    // Enable its recommended typescript rules
    ...reactX.configs['recommended-typescript'].rules,
    ...reactDom.configs.recommended.rules,
  },
})
```

# Feedback Input Form

Detta är frontend-applikationen för feedbackformulär i HSQ Forms Platform.

## Beskrivning

- Används för att samla in feedback från användare.
- Stöd för filuppladdning, validering och modern UI.

# Deploying form-feedback as Azure Static Web App (SWA)

## Bygg och testa lokalt

```sh
cd apps/form-feedback
npm install
npm run build
npm run preview
```

## Azure Static Web Apps

1. Skapa en SWA i Azure Portal eller via CLI:
   ```sh
   az staticwebapp create \
     --name hsq-feedback-swa \
     --resource-group rg-hsq-forms-prod-westeu \
     --source https://github.com/<ditt-github-repo> \
     --location westeurope \
     --app-location "." \
     --output-location "dist"
   ```
   (Byt ut repo och namn efter behov)

2. Lägg till/uppdatera `.env.production` med:
   ```env
   VITE_API_URL=https://hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io
   ```

3. Kontrollera att din backend (API) har rätt CORS-inställning:
   ```env
   ALLOWED_ORIGINS=https://<ditt-swa-namn>.azurestaticapps.net,http://localhost:5173
   ```

4. Vid push till main skapas en GitHub Actions workflow automatiskt för SWA.

5. Besök din SWA-URL och testa integrationen mot API.

## Felsökning
- Om du får CORS-fel: kontrollera att SWA-URL är tillagd i backendens ALLOWED_ORIGINS.
- Om API-anropen inte fungerar: kontrollera att VITE_API_URL är korrekt i `.env.production`.

# HSQ Feedback Form – Azure Static Web Apps Deployment

Detta dokument beskriver hur du deployar frontend (form-feedback) som en Azure Static Web App (SWA) och kopplar den till ditt backend-API som körs som en Azure Container App.

## 1. Förbered frontend för deployment

1.1. Bygg frontend för produktion:

```sh
cd apps/form-feedback
npm install
npm run build
```

1.2. Kontrollera att du har en `.env.production`-fil i `apps/form-feedback/` med:

```
VITE_API_URL=https://hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io
```

1.3. Kontrollera att API-anropen i koden använder `import.meta.env.VITE_API_URL` i produktion.

## 2. Skapa Azure Static Web App

Du kan skapa SWA via Azure Portal eller CLI. Exempel med CLI:

```sh
az staticwebapp create \
  --name hsq-feedback-swa \
  --resource-group rg-hsq-forms-prod-westeu \
  --location westeurope \
  --source https://github.com/<ditt-github-repo> \
  --branch <main-branch> \
  --app-location . \
  --output-location dist
```

Byt ut `<ditt-github-repo>` och `<main-branch>` mot din repo och branch.

Vid skapande kopplas SWA till ditt repo och en GitHub Actions workflow genereras automatiskt.

## 3. CORS-inställning på backend

Lägg till din SWA-URL i backendens miljövariabel `ALLOWED_ORIGINS`, t.ex.:

```
ALLOWED_ORIGINS=https://hsq-feedback-swa.azurestaticapps.net,http://localhost:5173
```

## 4. Deployment och test

- När du pushar till main byggs och deployas frontend automatiskt till SWA.
- Besök din SWA-URL och testa att frontend kan prata med backend.

## 5. Felsökning

- Om du får CORS-fel: kontrollera att SWA-URL är tillagd i backendens `ALLOWED_ORIGINS`.
- Om API-anropen inte fungerar: kontrollera att `VITE_API_URL` är korrekt i `.env.production`.

## 6. Vidare läsning
- [Azure Static Web Apps documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/)
- [Vite miljövariabler](https://vitejs.dev/guide/env-and-mode.html)

---

För frågor eller vidare hjälp, kontakta utvecklingsansvarig eller se projektets README.
