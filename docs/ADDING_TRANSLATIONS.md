# Adding Multilingual Support to Existing Forms

This guide provides step-by-step instructions for adding multilingual support to your existing forms after applying the language migration.

## Prerequisites

1. You have successfully run the language migration script (`apply_language_migration.sh`)
2. Your database now has the new language-related columns

## Adding Translations to Existing Forms

### Using the API

#### 1. Fetch Existing Form Template

First, retrieve your existing form template:

```bash
curl http://localhost:8000/api/forms/templates/{template_id} -H "Content-Type: application/json"
```

#### 2. Add Translations and Update Template

Update the template with language fields:

```bash
curl -X PUT http://localhost:8000/api/forms/templates/{template_id} \
  -H "Content-Type: application/json" \
  -d '{
    "default_language": "en",
    "available_languages": ["en", "sv"],
    "translations": {
      "sv": {
        "title": "Kontaktformulär",
        "description": "Skicka oss ett meddelande",
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
  }'
```

### Using SQL (Direct Database Update)

If you prefer to update via SQL:

```sql
UPDATE form_templates
SET 
  default_language = 'en',
  available_languages = '["en", "sv"]'::jsonb,
  translations = '{
    "sv": {
      "title": "Kontaktformulär",
      "description": "Skicka oss ett meddelande",
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
  }'::jsonb
WHERE id = '{template_id}';
```

### Using Python (Backend Code)

```python
from sqlalchemy.orm import Session
from src.forms_api.models import FormTemplate

def add_multilingual_support(db: Session, template_id: str):
    template = db.query(FormTemplate).filter(FormTemplate.id == template_id).first()
    
    if not template:
        raise ValueError(f"Template {template_id} not found")
    
    # Set default language
    template.default_language = "en"
    
    # Set available languages
    template.available_languages = ["en", "sv"]
    
    # Add translations
    template.translations = {
        "sv": {
            "title": "Kontaktformulär",
            "description": "Skicka oss ett meddelande",
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
    
    db.commit()
    return template
```

## Translation Schema Structure

When creating translations, follow this structure:

```json
{
  "language_code": {
    "title": "Translated title",
    "description": "Translated description",
    "schema": {
      "properties": {
        "field_name": {
          "title": "Translated field label",
          "description": "Translated field description"
        }
        // Other fields
      }
    }
  }
}
```

You should translate:
- Form title and description
- Field labels (title)
- Field descriptions
- Placeholder text
- Validation messages
- Any displayed text in the form

## Best Practices for Form Translations

1. **Start with your primary language** as the base, then add translations
2. **Be consistent with terminology** across languages 
3. **Test form validation** in each language
4. **Consider cultural differences** in form fields (e.g., name formats, address formats)
5. **Update all languages** when changing the form structure

## Translation Workflow

1. **Extract text:** Identify all translatable text in your forms
2. **Create translation files:** Use the JSON structure above
3. **Professional translation:** Consider using professional translation services for accuracy
4. **Review:** Have native speakers review the translations
5. **Test:** Test forms in each language to ensure everything works correctly

## Testing Multilingual Forms

To test your form in different languages:

1. Access the language-specific endpoint: `/{language_code}/templates`
2. Use API requests with the language parameter: `?language=sv`
3. Test the frontend with different language routes: `/sv/form`
4. Verify that validation messages appear in the correct language

## Common Issues

1. **Missing translations:** Ensure all text elements have translations
2. **Invalid JSON structure:** Check that your JSON structure matches the expected format
3. **Language code mismatch:** Ensure language codes are consistent (e.g., 'en' not 'en-US')
4. **Frontend not showing translations:** Verify API calls include language parameters

## Next Steps

After adding translations to your forms:

1. Update your frontend to include language switching functionality
2. Add more languages as needed
3. Consider implementing region-specific forms (e.g., `/us/`, `/se/`)
