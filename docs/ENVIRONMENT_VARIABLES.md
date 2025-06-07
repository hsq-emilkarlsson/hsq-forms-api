## Environment Variables

The HSQ Forms API uses environment variables for configuration. These can be set in a `.env` file in the root directory for development or configured in your deployment environment.

### Basic Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Environment type (development, staging, production) | development |
| `DEBUG` | Enable debug mode | false |
| `LOG_LEVEL` | Logging level (debug, info, warning, error) | info |

### API Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `API_TITLE` | API title shown in documentation | HSQ Forms API |
| `API_PREFIX` | API URL prefix | /api |
| `CORS_ORIGINS` | Allowed CORS origins (comma-separated) | * |

### Database Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_DB` | PostgreSQL database name | hsq_forms |
| `POSTGRES_USER` | PostgreSQL username | postgres |
| `POSTGRES_PASSWORD` | PostgreSQL password | password |
| `POSTGRES_HOST` | PostgreSQL host | postgres |
| `POSTGRES_PORT` | PostgreSQL port | 5432 |

### Storage Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `STORAGE_TYPE` | Storage type (local or azure) | local |
| `LOCAL_STORAGE_PATH` | Path for local file storage | ./uploads |
| `AZURE_STORAGE_ACCOUNT_NAME` | Azure Storage account name | |
| `AZURE_STORAGE_ACCOUNT_KEY` | Azure Storage account key | |
| `AZURE_STORAGE_CONNECTION_STRING` | Azure Storage connection string | |
| `AZURE_STORAGE_CONTAINER_NAME` | Azure Storage container name | form-attachments |

### Web Hook Settings (New)

| Variable | Description | Default |
|----------|-------------|---------|
| `WEBHOOKS_ENABLED` | Enable webhook notifications | false |
| `WEBHOOK_URLS` | Comma-separated list of webhook URLs | |
| `WEBHOOK_FORM_SPECIFIC_URLS` | JSON string mapping form IDs to webhook URLs | {} |
| `WEBHOOK_SECRET` | Secret key for signing webhook payloads | |

#### Example Web Hook Configuration

```dotenv
# Enable webhooks
WEBHOOKS_ENABLED=true

# Global webhooks for all form submissions
WEBHOOK_URLS=https://example.com/webhook1,https://example.com/webhook2

# Form-specific webhooks (JSON format)
WEBHOOK_FORM_SPECIFIC_URLS={"contact-form":"https://example.com/contact-webhook","feedback-form":"https://example.com/feedback-webhook"}

# Secret key for webhook signatures
WEBHOOK_SECRET=your-webhook-secret-key
```

### Security Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRET_KEY` | Secret key for token encryption | development_secret_key |
| `API_KEY_HEADER_NAME` | Name of API key header | X-API-Key |
| `ALLOWED_API_KEYS` | Comma-separated list of allowed API keys | |

### Form Submission Settings

| Variable | Description | Default |
|----------|-------------|---------|
| `MAX_ATTACHMENT_SIZE_MB` | Maximum attachment size in MB | 10 |
| `MAX_FORM_SIZE_KB` | Maximum form data size in KB | 2048 |
| `MAX_FILES_PER_SUBMISSION` | Maximum number of files per submission | 5 |
| `ALLOWED_FILE_TYPES` | Comma-separated list of allowed MIME types | application/pdf,image/jpeg,image/png |
