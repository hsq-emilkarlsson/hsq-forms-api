# Migration Guide for Multilingual Support

This document explains how to apply the database migration for multilingual support and prepare your application for handling multiple languages.

## Understanding the Migration

The migration script `5a7b9c0d1e2f_add_language_support.py` adds three essential columns to the `form_templates` table:

1. `default_language` (String, default: "en"): The primary language for the form template
2. `available_languages` (JSON array, default: ["en"]): List of language codes this form supports
3. `translations` (JSON object, default: {}): Stores translations for all form content by language code

## Prerequisites

Before running the migration:

1. Ensure you have access to your database
2. Make sure you have the latest version of the code
3. Verify Alembic is properly configured in your environment

## Running the Migration

### Option 1: Using the Provided Script

We provide a convenient script that runs the migration:

```bash
# Navigate to the project root
cd /path/to/hsq-forms-api

# Run the migration script
bash scripts/apply_language_migration.sh
```

The script will:
- Run `alembic upgrade head` to apply all pending migrations
- Provide feedback on the migration status
- Offer suggestions for next steps

### Option 2: Manual Migration

If you prefer to run the migration manually:

```bash
# Navigate to the project root
cd /path/to/hsq-forms-api

# Set environment variables (if not already in .env)
export DATABASE_URL=postgresql://username:password@localhost:5432/hsq_forms_db

# Run alembic upgrade
alembic upgrade head
```

### Verifying the Migration

After running the migration, you can verify it was successful:

```bash
# Check current migration status
alembic current

# Should show: 5a7b9c0d1e2f (head)
```

You can also check the database directly:

```sql
-- Run in your database client
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'form_templates' 
AND column_name IN ('default_language', 'available_languages', 'translations');
```

## After Migration

Once the migration is complete, you need to:

1. **Update Existing Form Templates**: Add language data to your existing templates
2. **Update Your API Calls**: Use language parameters in your requests
3. **Update Frontend Code**: Implement language switching UI components

### Example: Updating an Existing Form Template

```python
# Example Python code to update an existing form template
from sqlalchemy.orm import Session
from src.forms_api.models import FormTemplate

def add_translation(db: Session, template_id: str, language: str, translated_data: dict):
    template = db.query(FormTemplate).filter(FormTemplate.id == template_id).first()
    
    if not template:
        raise ValueError(f"Template {template_id} not found")
    
    # Add language to available_languages if not already present
    if language not in template.available_languages:
        template.available_languages.append(language)
    
    # Initialize translations dict if it doesn't exist
    if not template.translations:
        template.translations = {}
    
    # Add the translated content
    template.translations[language] = translated_data
    
    db.commit()
    return template

# Example usage
translations = {
    "title": "Contact Form",
    "description": "Send us a message",
    "schema": {
        "properties": {
            "name": {
                "title": "Name",
                "description": "Your full name"
            },
            # ...other fields
        }
    }
}

add_translation(db_session, "contact-form-template-id", "en", translations)
```

## Troubleshooting

### Common Issues

1. **Migration Already Applied**: 
   ```
   ERROR [alembic.runtime.migration] Can't locate revision identified by '5a7b9c0d1e2f'
   ```
   
   This means the migration has already been applied. Check with `alembic current`.

2. **Database Connection Issues**:
   ```
   ERROR [alembic.runtime.migration] Can't connect to database
   ```
   
   Verify your DATABASE_URL is correct and accessible.

3. **Conflicts with Existing Columns**:
   ```
   ERROR [alembic.runtime.migration] Column already exists
   ```
   
   Run `alembic current` to check your current migration state. You might need to downgrade first.

### Getting Help

If you encounter issues with the migration, please:

1. Check the application logs for detailed error messages
2. Review the Alembic documentation for migration commands
3. Contact the development team with specifics about your environment and the exact error message

## Next Steps

After successfully running the migration:

1. Review the [Multilingual Support Documentation](/docs/MULTILINGUAL_SUPPORT.md)
2. Update your frontend application following the [Form App Template Guide](/templates/form-app-template/GETTING_STARTED.md)
3. Test your forms in different languages to ensure proper functionality
