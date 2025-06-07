# HSQ Forms API Integration Guide

This guide provides detailed information about connecting to the HSQ Forms API, working with file attachments, and understanding how form responses are stored in PostgreSQL.

## Table of Contents

1. [Connecting to the HSQ Forms API](#connecting-to-the-hsq-forms-api)
2. [File Attachment Handling](#file-attachment-handling)
3. [Form Response Storage in PostgreSQL](#form-response-storage-in-postgresql)
4. [API Endpoints Reference](#api-endpoints-reference)
5. [Troubleshooting](#troubleshooting)

## Connecting to the HSQ Forms API

The HSQ Forms API is built with FastAPI and provides a RESTful interface for form submission and management. This section explains how to connect to the API from different clients.

### API Base URL

The base URL for connecting to the API depends on your deployment environment:

- **Local Development**: `http://localhost:8001`
- **Production**: Your deployed API endpoint (e.g., `https://api.example.com`)

### Authentication

Depending on your configuration, the API may require authentication:

- **API Key**: Pass your API key in the header as `X-API-Key: your_api_key_here`
- **OAuth**: For advanced integrations, OAuth2 authentication may be configured

### Connection Methods

#### 1. Using the React Form Template

The provided React form template in `templates/form-app-template` already includes configured API integration. It uses axios for HTTP requests with built-in error handling and retry mechanisms.

Key files:
- `src/api/formsApi.ts` - Contains API connection methods
- `src/utils/errorHandling.ts` - Handles errors and retries
- `src/utils/azureIntegration.ts` - For Azure-specific functionality

To use the template:

```javascript
// Import the API methods
import { submitForm, getFormConfig } from '../api/formsApi';

// Submit form data
const response = await submitForm({
  formId: 'your-form-id',
  data: formData,
  files: filesList,  // Optional
  metadata: {        // Optional
    source: 'your-app',
    browser: getBrowserInfo()
  }
});

// Check response
if (response.success) {
  // Handle success
  console.log('Submission ID:', response.data.submission.id);
} else {
  // Handle error
  console.error('Error:', response.error);
}
```

#### 2. Direct HTTP Requests

You can connect directly using any HTTP client:

**Python Example**:

```python
import requests

# Submit form data
response = requests.post(
    "http://localhost:8001/api/forms/templates/your-form-id/submit",
    json={
        "data": {
            "name": "John Doe",
            "email": "john@example.com",
            "message": "Hello world!"
        },
        "metadata": {
            "source": "python-client",
            "timestamp": "2025-06-05T12:00:00Z"
        }
    },
    headers={
        "Content-Type": "application/json",
        "X-API-Key": "your_api_key_here"  # If required
    }
)

# Check response
result = response.json()
if response.status_code == 201:
    print(f"Success! Submission ID: {result['submission']['id']}")
else:
    print(f"Error: {result.get('error', 'Unknown error')}")
```

**JavaScript/TypeScript Example**:

```javascript
// Submit form data
const response = await fetch('http://localhost:8001/api/forms/templates/your-form-id/submit', {
  method: 'POST',
  headers: { 
    'Content-Type': 'application/json',
    'X-API-Key': 'your_api_key_here'  // If required
  },
  body: JSON.stringify({
    data: {
      name: "Jane Smith",
      email: "jane@example.com",
      message: "Hello from JavaScript!"
    },
    metadata: {
      source: "js-client",
      timestamp: new Date().toISOString()
    }
  })
});

const result = await response.json();
if (response.ok) {
  console.log(`Success! Submission ID: ${result.submission.id}`);
} else {
  console.error(`Error: ${result.error || 'Unknown error'}`);
}
```

#### 3. Using Docker Compose for Local Development

To integrate with your local development environment:

```yaml
# docker-compose.yml
services:
  # Your existing services
  
  forms-api:
    image: hsq-forms-api:latest
    ports:
      - "8001:8000"
    environment:
      DATABASE_URL: postgresql://postgres:password@postgres:5432/hsq_forms
      USE_AZURE_STORAGE: "false"
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

## File Attachment Handling

The HSQ Forms API supports file uploads with built-in security features. Files can be stored either locally or in Azure Blob Storage depending on configuration.

### Storage Options

1. **Local Storage** (Development)
   - Files are stored in a local directory on the server
   - Default path: `uploads/` directory

2. **Azure Blob Storage** (Production)
   - Files are stored in Azure Blob Storage
   - Secured with SAS tokens for access

### File Upload Process

The file upload process follows these steps:

1. **Client-side preparation**:
   - Collect files from form input
   - Validate file size and type (if needed)
   
2. **Initial form submission**:
   - Submit form data first to create a submission record
   - Get back a submission ID
   
3. **File upload**:
   - Upload files to `/files/upload/{submission_id}` endpoint
   - Associate files with the submission

### Example: File Upload with the React Template

```javascript
// Using the formApi.ts in the React template
import { submitForm } from '../api/formsApi';

// Collect form data and files
const formData = {
  name: "User Name",
  email: "user@example.com",
  message: "My message with attachments"
};

const fileInput = document.querySelector('input[type="file"]');
const files = fileInput.files;

// Submit form with files
const response = await submitForm({
  formId: 'contact-form',
  data: formData,
  files: Array.from(files), // Convert FileList to array
  metadata: {
    source: 'file-upload-example'
  }
});

// The API handles both the form submission and file uploads
if (response.success) {
  console.log('Form with files submitted successfully');
} else {
  console.error('Error submitting form with files:', response.error);
}
```

### Example: Direct File Upload with Axios

```javascript
import axios from 'axios';

// Step 1: Submit form data first
const formResponse = await axios.post(
  'http://localhost:8001/api/forms/templates/contact-form/submit',
  {
    data: {
      name: "User Name",
      email: "user@example.com",
      message: "My message with attachments"
    },
    metadata: { source: 'custom-integration' }
  }
);

// Step 2: Get the submission ID
const submissionId = formResponse.data.submission.id;

// Step 3: Upload files
const fileFormData = new FormData();
const fileInput = document.querySelector('input[type="file"]');
Array.from(fileInput.files).forEach(file => {
  fileFormData.append('files', file);
});

// Upload files to the submission
await axios.post(
  `http://localhost:8001/files/upload/${submissionId}`,
  fileFormData,
  {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  }
);
```

### File Storage Security

The API implements several security measures for file uploads:

1. **File type validation** - Restricts allowed file types
2. **Size limits** - Maximum 10MB per file and 5 files per submission
3. **Content scanning** - Basic content analysis to detect malicious files
4. **Secure naming** - Files are stored with randomized names, not original filenames

### Accessing Uploaded Files

Files can be accessed through these endpoints:

- **Get file info**: `GET /files/{file_id}/info`
- **Download file**: `GET /files/{file_id}`
- **List submission files**: `GET /files/submission/{submission_id}`

## Form Response Storage in PostgreSQL

Form submissions and file attachments are stored in PostgreSQL using a well-structured database schema. Understanding this structure helps when building integrations or querying the data.

### Database Schema

#### Form Submissions Table

The `form_submissions` table stores basic form submissions:

```sql
CREATE TABLE form_submissions (
    id VARCHAR PRIMARY KEY,
    form_type VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    form_metadata JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    is_processed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
```

#### File Attachments Table

The `file_attachments` table stores information about uploaded files:

```sql
CREATE TABLE file_attachments (
    id VARCHAR PRIMARY KEY,
    submission_id VARCHAR NOT NULL REFERENCES form_submissions(id),
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL,
    file_size INTEGER NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    blob_url VARCHAR(500),
    upload_status VARCHAR(20) NOT NULL DEFAULT 'uploaded',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    FOREIGN KEY (submission_id) REFERENCES form_submissions(id) ON DELETE CASCADE
);
```

#### Flexible Forms Tables

For dynamic form templates:

- `form_templates` - Stores JSON schemas for dynamic form templates
- `flexible_form_submissions` - Stores submissions with dynamic data structure
- `flexible_form_attachments` - Stores file attachments for flexible forms

### Querying Form Data

To query form data directly from PostgreSQL:

```sql
-- Get all form submissions for a specific form type
SELECT * FROM form_submissions
WHERE form_type = 'contact'
ORDER BY created_at DESC;

-- Get submissions with their attachments
SELECT 
    fs.id, fs.name, fs.email, fs.message, fs.created_at,
    fa.original_filename, fa.file_size, fa.content_type
FROM form_submissions fs
LEFT JOIN file_attachments fa ON fs.id = fa.submission_id
WHERE fs.form_type = 'contact'
ORDER BY fs.created_at DESC;

-- Get submissions that have file attachments
SELECT DISTINCT fs.*
FROM form_submissions fs
JOIN file_attachments fa ON fs.id = fa.submission_id
WHERE fs.form_type = 'contact';
```

### Data Retention and Backups

The HSQ Forms API includes a data retention policy:

1. **Default Retention Period**: 90 days for form submissions
2. **Backup Schedule**: Daily automated backups
3. **Backup Location**: `/backups` directory or Azure Storage

## API Endpoints Reference

### Form Management

- `POST /api/forms/templates` - Create form template
- `GET /api/forms/templates` - List all templates
- `GET /api/forms/templates/{template_id}` - Get specific template
- `GET /api/forms/templates/{template_id}/schema` - Get JSON schema
- `DELETE /api/forms/templates/{template_id}` - Delete template

### Submission Endpoints

- `POST /api/forms/templates/{template_id}/submit` - Submit form
- `GET /api/forms/submissions` - List all submissions
- `GET /api/forms/submissions/{submission_id}` - Get submission details
- `PUT /api/forms/submissions/{submission_id}/status` - Update status

### File Management

- `POST /files/upload/{submission_id}` - Upload files to submission
- `POST /files/upload/temp` - Upload temporary files
- `GET /files/submission/{submission_id}` - List submission files
- `GET /files/{file_id}` - Download file
- `GET /files/{file_id}/info` - Get file info
- `DELETE /files/{file_id}` - Delete file

### Legacy Endpoints

- `POST /submit` - Legacy form submission endpoint
- `GET /submissions` - List legacy submissions
- `GET /submission/{submission_id}` - Get legacy submission

## Troubleshooting

### Common Issues and Solutions

#### Connection Issues

**Problem**: Unable to connect to the API
- **Check**: Ensure the API is running (`docker-compose up`)
- **Check**: Verify API URL is correct
- **Check**: Look for CORS issues in browser console

#### Authentication Issues

**Problem**: API returns 401 Unauthorized
- **Check**: API key is correctly set in headers
- **Check**: API key is valid and not expired

#### File Upload Issues

**Problem**: File upload fails
- **Check**: File size is under 10MB
- **Check**: Not exceeding 5 files per submission
- **Check**: Server has write permissions to upload directory
- **Check**: Valid file types

#### Database Issues

**Problem**: Database errors
- **Check**: PostgreSQL container is running
- **Check**: Database credentials are correct
- **Check**: Database migrations are up to date

### Logs and Debugging

To debug issues, check the logs:

```bash
# API logs
docker-compose logs api

# Database logs
docker-compose logs postgres
```

### Getting Help

For additional help:
- Check the `docs` directory for more documentation
- Examine examples in the `examples` directory
- Run test scripts in the `tests` directory
