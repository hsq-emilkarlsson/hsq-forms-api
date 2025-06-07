# Multilingual Support for HSQ Forms API

## Overview
This document describes the multilingual capabilities of the HSQ Forms API system, which enables form templates, submissions, and the user interface to support multiple languages.

## Features

### 1. Language-Specific Routes
The API now supports language-specific routes for accessing form templates:
- `/en/templates` - English forms
- `/sv/templates` - Swedish forms
- `/us/templates` - US-specific forms (English language)
- `/se/templates` - Sweden-specific forms (Swedish language)

### 2. Form Template Translations
Form templates can be defined with multiple language translations, including:
- Form name/title
- Description
- Form fields (labels, placeholders, validation messages)
- Form schema definitions

### 3. Frontend Language Support
- Automatic language detection based on URL path
- Language selector component
- Translated UI elements
- Persisting language preference

## Database Schema

### Language-Related Fields in `FormTemplate` Model
```python
# Added to FormTemplate model
default_language = Column(String(5), nullable=False, default="en")  # Default language code (e.g., en, sv)
available_languages = Column(JSON, nullable=False, default=lambda: ["en"])  # List of available language codes
translations = Column(JSON, nullable=False, default=lambda: {})  # Translations for all text content by language
```

### Translation JSON Structure
```json
{
  "en": {
    "title": "Contact Form",
    "description": "Send us a message",
    "schema": {
      "properties": {
        "name": {
          "title": "Name",
          "description": "Your full name"
        },
        "email": {
          "title": "Email"
        },
        "message": {
          "title": "Message"
        }
      }
    }
  },
  "sv": {
    "title": "Kontaktformulär",
    "description": "Skicka ett meddelande till oss",
    "schema": {
      "properties": {
        "name": {
          "title": "Namn",
          "description": "Ditt fullständiga namn"
        },
        "email": {
          "title": "E-post"
        },
        "message": {
          "title": "Meddelande"
        }
      }
    }
  }
}
```

## API Endpoints

### Get Form Templates by Language
```
GET /{language_code}/templates?project_id={project_id}
```

### Get Form Template with Language
```
GET /forms/templates/{template_id}?language={language}
```

### Get Form Schema with Language
```
GET /forms/templates/{template_id}/schema?language={language}
```

## Frontend Implementation

### URL Structure
The frontend application uses language prefixes in URLs:
- `/en/form` - English form
- `/sv/form` - Swedish form
- `/us/form` - US form
- `/se/form` - Swedish form

### Language Detection and Routing
The application can detect the language from:
1. URL path (primary)
2. Browser settings
3. User preferences stored in localStorage

### i18next Integration
The frontend uses i18next for UI translations with:
- Language detection plugin
- HTTP backend for loading translation files
- Support for dynamically loading language resources

## Usage Examples

### Creating a Multilingual Form Template
```python
template_data = {
    "title": "Contact Form",
    "description": "Send us a message",
    "project_id": "website",
    "fields": [...],
    "default_language": "en",
    "available_languages": ["en", "sv"],
    "translations": {
        "sv": {
            "title": "Kontaktformulär",
            "description": "Skicka ett meddelande till oss",
            "schema": {...}
        }
    }
}
```

### Submitting a Form with Language Metadata
```javascript
const formData = {
  formId: "contact-form",
  data: {
    name: "John Doe",
    email: "john@example.com",
    message: "Hello, I have a question."
  },
  language: "en",
  metadata: {
    source: "website"
  }
};

await formsApi.submitForm(formData);
```

### Retrieving a Form in a Specific Language
```javascript
const formSchema = await formsApi.getFormSchema("contact-form", "sv");
```

## Deployment Migration

When deploying this update, you will need to run a database migration to add the new language support columns:

```bash
# Run the alembic migration
alembic upgrade head
```

This will execute the migration `5a7b9c0d1e2f_add_language_support.py`, which adds the required columns to the `form_templates` table.
