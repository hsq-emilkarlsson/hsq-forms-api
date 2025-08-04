# HSQ Forms API

A flexible form handling API built with FastAPI and PostgreSQL.

## Architecture

This repository contains **only the backend API**. The frontend applications are maintained in separate repositories:

- **Backend API** (this repo): `hsq-forms-api`
- **Frontend UI**: `hsq-forms-externalinput` (separate repository)

This separation allows for:
- Independent development cycles
- Different deployment strategies  
- Team autonomy
- Better security isolation

## Environments

This project uses a clear separation between development and production environments:

- **Development**: All resources have `-dev` suffix (e.g., `hsq-forms-api-dev`)
- **Production**: Clean naming without suffixes (e.g., `hsq-forms-api`)

See [Environment Management Guide](docs/ENVIRONMENT_MANAGEMENT.md) for details.
- Better security isolation

## Key Features

- **Flexible Form Schemas**: Create custom form templates with JSON Schema
- **File Attachments**: Support for file uploads and storage
- **Web Hooks**: Integration with external systems via web hooks
- **Azure Integration**: Built-in support for Azure services
- **Multilingual Support**: Forms and UI in multiple languages
- **API Documentation**: Comprehensive API documentation with Swagger

## Multilingual Support

The API now includes comprehensive support for multilingual forms:

- Language-specific routes (`/en/templates`, `/sv/templates`)
- Translated form content (titles, descriptions, field labels)
- Language parameter support in API calls
- Frontend integration with i18next

**Important:** Before using multilingual features, run the migration script:

```bash
bash scripts/apply_language_migration.sh
```

For detailed documentation:

- [Multilingual Support Guide](docs/MULTILINGUAL_SUPPORT.md)
- [Migration Guide](docs/MIGRATION_GUIDE.md)
- [Adding Translations](docs/ADDING_TRANSLATIONS.md)

## Project Structure

The project follows a standard Python package structure:

```plaintext
hsq-forms-api/
├── alembic/              # Database migrations
├── backups/              # Backup files directory  
├── docs/                 # Documentation
├── infra/                # Infrastructure as code (Bicep templates)
├── scripts/              # Utility scripts for development and maintenance
│   ├── run-tests.sh      # Test script
│   ├── start-dev.sh      # Development environment starter
│   └── ...
├── src/                  # Source code
│   ├── main.py           # Application entry point
│   └── forms_api/        # Main package
│       ├── app.py        # FastAPI application factory
│       ├── config.py     # Configuration settings
│       ├── db.py         # Database connection handling
│       ├── models.py     # Database models (SQLAlchemy)
│       ├── routes.py     # API route handlers
│       ├── schemas.py    # Pydantic schemas for validation
│       └── services.py   # Business logic service layer
├── templates/            # Ready-to-use frontend templates
│   ├── form-app-template/# Basic form application template
│   └── react-form-template/# React form application template with Azure integration
├── tests/                # Test suite
├── docker-compose.yml    # Docker container configuration
├── Dockerfile           # Docker image definition
├── requirements.txt     # Python dependencies
└── main.py              # Application entry point
```

## Quick Start

### Local Development with Docker

1. **Run the entire stack:**

   ```bash
   # Option 1: Use start script (recommended)
   ./scripts/start-dev.sh
   
   # Option 2: Use docker-compose directly
   docker-compose up --build
   ```

2. **API is available at:**
   - <http://localhost:8000>
   - API documentation: <http://localhost:8000/docs>

### Test the API

Run the test script to create and test forms:

```bash
python tests/test_api.py
```

### Explore Examples

Check out the `examples/` directory for integration examples:

- HTML/JavaScript form
- React component
- Vue.js component
- Python client library
- curl examples

See `examples/README.md` for detailed usage instructions.

## API Endpoints

### Form Templates

- `POST /api/forms/templates` - Create form template
- `GET /api/forms/templates` - List all templates
- `GET /api/forms/templates/{template_id}` - Get specific template
- `GET /api/forms/templates/{template_id}/schema` - Get JSON schema

### Project Forms

- `GET /api/forms/projects/{project_name}/forms` - List forms for project

### Submissions

- `POST /api/forms/templates/{template_id}/submit` - Submit form
- `GET /api/forms/submissions` - List all submissions

## Example: Create Form

```python
import requests

# Create form template
template_data = {
    "name": "Contact Form",
    "description": "Simple contact form",
    "project_name": "website",
    "fields": [
        {
            "name": "name",
            "label": "Name", 
            "field_type": "text",
            "required": True
        },
        {
            "name": "email",
            "label": "Email",
            "field_type": "email", 
            "required": True
        },
        {
            "name": "message",
            "label": "Message",
            "field_type": "textarea",
            "required": True
        }
    ]
}

response = requests.post("http://localhost:8000/api/templates", json=template_data)
template = response.json()

# Submit form
submission_data = {
    "name": "John Doe",
    "email": "john@example.com", 
    "message": "Hello, I'm interested in your services!"
}

response = requests.post(
    f"http://localhost:8000/api/templates/{template['id']}/submit",
    json=submission_data
)
```

## Multilingual Support 

The API now includes comprehensive support for multilingual forms:

### Features

- Language-specific routes (`/en/templates`, `/sv/templates`)
- Translated form content (titles, descriptions, field labels)
- Language parameter support in API calls
- Frontend integration with i18next

### Important Migration Note

Before using multilingual features, run the migration script:

```bash
bash scripts/apply_language_migration.sh
```

### Documentation

For detailed documentation on multilingual support:

- [Multilingual Support Guide](docs/MULTILINGUAL_SUPPORT.md)
- [Migration Guide](docs/MIGRATION_GUIDE.md)
- [Adding Translations](docs/ADDING_TRANSLATIONS.md)

## Use from Other Projects

### Docker Compose Integration

Add to your project's `docker-compose.yml`:

```yaml
services:
  # Your other services...
  
  forms-api:
    image: hsq-forms-api:latest
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://postgres:password@postgres:5432/hsq_forms
    depends_on:
      - postgres
      
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: hsq_forms
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Direct HTTP Calls

```javascript
// Create form from your frontend
const createForm = async (formData) => {
  const response = await fetch('http://localhost:8000/api/templates', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(formData)
  });
  return response.json();
};

// Submit form
const submitForm = async (templateId, data) => {
  const response = await fetch(`http://localhost:8000/api/templates/${templateId}/submit`, {
    method: 'POST', 
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  });
  return response.json();
};
```

### Web Hook Integration (New!)

The API now supports web hook notifications for form submissions, which can be used to integrate with external systems like Microsoft Power Automate, automation platforms, or custom applications.

#### Configuration

Enable web hooks by setting the following environment variables:

```bash
# Enable webhooks
WEBHOOKS_ENABLED=true

# Global webhook URLs (for all form submissions)
WEBHOOK_URLS=https://example.com/webhook1,https://example.com/webhook2

# Form-specific webhooks (JSON format)
WEBHOOK_FORM_SPECIFIC_URLS={"template-id-1":"https://example.com/webhook1"}

# Secret for signing webhook payloads
WEBHOOK_SECRET=your-secure-secret-key
```

#### Example Web Hook Payload

```json
{
  "event_type": "submission_created",
  "timestamp": "2025-06-06T12:34:56.789Z",
  "form_data": {
    "id": "abc123",
    "template_id": "template-123",
    "template_name": "Contact Form",
    "data": {
      "name": "John Doe",
      "email": "john@example.com",
      "message": "Hello, I'm interested in your services!"
    },
    "submitted_at": "2025-06-06T12:34:56.789Z"
  }
}
```

For detailed documentation on web hooks and Power Automate integration, see:
- [Web Hook API Documentation](docs/WEBHOOK_API.md)
- [Power Automate Integration Guide](docs/POWER_AUTOMATE_INTEGRATION.md)
- [Environment Variables Reference](docs/ENVIRONMENT_VARIABLES.md)

## Development

### Project Structure

```text
├── src/                # Source code package
│   ├── main.py         # FastAPI runner
│   └── forms_api/      # Main application package
│       ├── __init__.py # Package definition
│       ├── app.py      # FastAPI app factory
│       ├── config.py   # Configuration settings
│       ├── crud.py     # Database operations
│       ├── db.py       # Database connection
│       ├── models.py   # Database models
│       ├── api/        # API layer
│       │   ├── __init__.py
│       │   └── routes/ # Route handlers
│       │       ├── __init__.py
│       │       ├── enhanced_forms.py # Enhanced form handling
│       │       ├── files.py         # File handling
│       │       ├── forms.py         # Flexible form endpoints
│       │       └── submit.py        # Legacy form submission
│       ├── schemas/    # Data schemas
│       │   └── __init__.py
│       └── services/   # Business logic
│           ├── __init__.py
│           ├── enhanced_services.py
│           └── storage/
│               ├── __init__.py
│               ├── azure_storage.py # Azure storage integration
│               ├── blob_base.py     # Generic blob storage interface
│               ├── blob.py          # Blob handling utilities
│               └── local_storage.py # Local file storage
├── alembic/            # Database migrations
│   ├── env.py
│   ├── README
│   ├── script.py.mako
│   └── versions/       # Migration scripts
├── docs/               # Documentation
│   ├── FORM_INTEGRATION_GUIDE.md  # Integration documentation
│   ├── AZURE_DEPLOYMENT_GUIDE.md  # Deployment guide
│   ├── WEBHOOK_API.md             # Web Hook API documentation
│   ├── POWER_AUTOMATE_INTEGRATION.md # Power Automate integration guide
│   └── ENVIRONMENT_VARIABLES.md   # Environment variables reference
├── examples/           # Example code for integration
│   ├── html_form_example.html     # Plain HTML example
│   ├── react_form_example.jsx     # React component
│   ├── vue_form_example.vue       # Vue component
│   ├── python_client.py           # Python client
│   ├── curl_examples.sh           # curl commands
│   ├── ContactForm.css            # CSS för HTML-exempel
│   ├── FlexibleForm.css           # CSS för flexibla formulär
│   ├── react_flexible_form.jsx    # React-komponent för flexibla formulär
│   ├── README.md                  # Exempel-dokumentation
│   └── static-web-app-template/   # Azure Static Web App example
├── tests/              # Test files
│   ├── test_api.py     # API test script
│   ├── test_pytest_api.py # Pytest-based API tests
│   ├── test_file_storage.py # File storage tests
│   ├── test_azure_integration.py # Azure integration tests
│   ├── conftest.py     # Pytest fixtures and configuration
│   ├── TESTING.md      # Testing documentation
│   └── scripts/        # Test and deployment scripts
│       ├── deploy-simple.sh  # Simple deployment script
│       └── cleanup_cache.sh  # Script to clean __pycache__ directories
├── infra/              # Azure infrastructure
│   ├── main.bicep      # Infrastructure as code
│   └── main.parameters.json # Deployment parameters
├── docker-compose.yml  # Docker configuration
├── azure.yaml          # Azure Developer CLI config
├── Makefile            # Development commands
├── scripts/
│   ├── run-tests.sh        # Test script för enkel testkörning
│   ├── start-dev.sh        # Script för att starta utvecklingsmiljö# Test deployment with correct tenant ID
