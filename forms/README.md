# HSQ Forms Collection

This directory contains all deployed form applications that use the HSQ Forms API as backend.

## Current Forms

### hsq-forms-container-b2b-feedback
A multilingual B2B feedback form supporting Swedish, English, and German.

**Features:**
- Company information collection
- Service satisfaction rating
- Multi-language support (/se, /en, /de)
- Containerized deployment
- Integration with HSQ Forms API

**Quick Start:**
```bash
cd forms/hsq-forms-container-b2b-feedback
npm install
npm run dev
```

### hsq-forms-container-b2b-returns
A B2B returns processing form for handling product return requests.

**Features:**
- Return request processing
- Product information capture
- Multi-language support
- Containerized deployment
- Integration with HSQ Forms API

**Quick Start:**
```bash
cd forms/hsq-forms-container-b2b-returns
npm install
npm run dev
```

## Creating New Forms

To create a new form, you can use the copy script:

```bash
# Copy an existing form
./scripts/copy-container-form.sh hsq-forms-container-b2b-feedback your-new-form-name

# Or copy from template
./scripts/create-new-form.sh your-new-form-name
```

### Manual Creation Steps

1. Copy the template:

```bash
cp -r templates/react-form-template forms/your-new-form-name
```

2. Customize the form:
   - Update `src/components/Form.tsx` with your form fields
   - Modify translations in `src/i18n.js`
   - Update `package.json` name field
   - Configure API endpoint in `.env`

3. Test and deploy:

```bash
cd forms/your-new-form-name
npm install
npm run dev  # Development
docker-compose up --build  # Production
```

## Form Deployment Architecture

Each form is:

- ✅ Containerized with Docker
- ✅ Independently deployable
- ✅ Connected to shared HSQ Forms API backend
- ✅ Multi-language capable
- ✅ Production-ready

## Azure DevOps Deployment Strategy

### Current Status
För närvarande är enbart API:et automatiskt distribuerat via Azure DevOps-pipelinen. Formulären valideras men distribueras inte ännu.

### Planerad Deployment-strategi
Formulären kommer att distribueras som Static Web Apps eller App Service-webbappar i framtiden:

1. **Static Web Apps** (Rekommenderad för nya formulär)
   - Fördelar: Låg kostnad, global CDN, enkel deployment
   - Användning: Formulär utan backend-funktionalitet utöver API-anrop

2. **App Service Web Apps**
   - Fördelar: Fullständig servermiljö, stöd för Node.js middleware om det behövs
   - Användning: Mer komplexa formulär som kräver server-side rendering eller middleware

### Framtida CI/CD Pipeline
Pipeline-steget för formulär-deployment kommer att:
1. Detektera vilka formulär som har ändrats
2. Bygga formulären (npm build)
3. Distribuera till Static Web Apps eller App Service
4. Konfigurera API-integrationsinställningar automatiskt

## Integration med HSQ Forms API

All forms submit data to the HSQ Forms API. Use the following:

- Dev environment (local): `http://localhost:8000/api`
- Production environment: `https://hsq-forms-dev-e8g5hhgpfwgabsg5.a03.azurefd.net/api`

Configure the API URL in your Static Web App's Configuration settings:
- Name: `VITE_API_URL`
- Value: `https://hsq-forms-dev-e8g5hhgpfwgabsg5.a03.azurefd.net/api`

The API handles:

- Form template management
- Data validation and storage
- File upload processing
- Webhook notifications
- Multi-language support
