# Projektplan – Formulärplattform med AI-assisterad utveckling

En optimerad projektplan för att bygga och leverera ett formulärsystem med:
- React-baserade formulär med flerspråkstöd via `i18next`.
- Hostat i Azure (Static Web Apps + Container Apps).
- FastAPI-backend för kundnummer-validering och formulärsubmission.
- Integration med Dynamics 365 via Power Automate och n8n för automation.
- CI/CD via GitHub Actions med separata workflows och GitHub Environments.
- AI-assisterad utveckling med GitHub Copilot (GPT-4.1) och Claude 3.5 i Visual Studio.
- Tidig dev-portal med automatisk formulärupptäckt och QA-stöd, CLI för formulärskapande, och tydligt contribute flow.
- Standardiserade formulär och komponenter för återanvändbarhet och Sitecore-kompatibilitet.

---

## 🧭 FAS 0 – Kickstart och struktur

**Mål**:
- Skapa ett mono-repo för formulär, backend, och automation.
- Sätt upp vision, standarder, och CLI för att scaffolda formulär.
- Förbereda Visual Studio för AI-verktyg (GitHub Copilot och Claude 3.5).

**Steg**:
1. Skapa GitHub-repo: `form-platform`.
2. Sätt upp grundstruktur:
```
form-platform/
├─ apps/
│  ├─ api/                 # FastAPI-backend (kundvalidering, submission)
│  ├─ form-contact/        # React SPA – första formuläret
│  ├─ embed-loader/        # JS-loader för inbäddning
│  └─ dev-portal/          # Preview-app för intern testning
├─ packages/
│  ├─ shared-ui/           # Komponentbibliotek i React
│  ├─ schemas/             # Formulärdefinitioner i TS/Zod
│  ├─ sitecore-mapping/    # Fältnamnskopplingar
│  ├─ utils/               # Hooks och helpers
│  ├─ locales/             # Översättningar (sv.json, en.json)
├─ docker/                 # Docker Compose för lokal testning
├─ scripts/                # CLI-skript för att scaffolda formulär
├─ .github/workflows/      # GitHub Actions pipelines
├─ docs/
│  ├─ vision.md
│  ├─ form-standards.md
│  ├─ contribute.md
│  ├─ ai-usage.md
└─ README.md
```
3. Skapa CLI-skript för att scaffolda formulär:
```bash
npm install -D degit
```
Skapa `scripts/create-form.js`:
```javascript
const degit = require('degit');
const path = require('path');
const fs = require('fs');

const formName = process.argv[2];
const targetDir = path.join(__dirname, '../apps', `form-${formName}`);

const emitter = degit('path/to/form-template', { force: true });
emitter.clone(targetDir).then(() => {
  fs.writeFileSync(
    path.join(targetDir, 'package.json'),
    JSON.stringify({ name: `form-${formName}`, version: '1.0.0' }, null, 2)
  );
  fs.writeFileSync(
    path.join(targetDir, 'form-config.json'),
    JSON.stringify({ id: formName, theme: 'light' }, null, 2)
  );
  fs.writeFileSync(
    path.join(targetDir, 'README.md'),
    `# Form ${formName}\n\nSyfte: [Beskriv formulärets syfte]\nFält: [Lista fält]\nSitecore-koppling: [Beskriv koppling]`
  );
  console.log(`Formulär form-${formName} skapat!`);
});
```
Uppdatera `package.json`:
```json
{
  "scripts": {
    "create-form": "node scripts/create-form.js"
  }
}
```
4. Installera GitHub Copilot i Visual Studio (eller VS Code) och konfigurera med GPT-4.1.
5. Skapa ett konto på Anthropics plattform för Claude 3.5 (API eller webbgränssnitt).
6. Skapa `.eslintrc.json` för kodkonsistens:
```json
{
  "env": { "browser": true, "es2021": true },
  "extends": ["eslint:recommended", "plugin:react/recommended", "plugin:@typescript-eslint/recommended"],
  "parserOptions": { "ecmaVersion": 12, "sourceType": "module"