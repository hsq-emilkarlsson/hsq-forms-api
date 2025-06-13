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

## Integration with HSQ Forms API

All forms submit data to the HSQ Forms API at `http://localhost:8000` (dev) or your production API URL.

The API handles:

- Form template management
- Data validation and storage
- File upload processing
- Webhook notifications
- Multi-language support
