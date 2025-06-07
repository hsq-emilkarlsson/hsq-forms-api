# HSQ Forms API - Project Structure

This document provides an in-depth overview of the HSQ Forms API project structure after its reorganization.

## Overview

The project follows a clean, modular structure that separates concerns and makes the codebase easier to navigate and maintain. The main code is organized into packages based on functionality.

## Directory Structure

```plaintext
hsq-forms-api/
├── alembic/              # Database migrations
├── backups/              # Backup files directory
├── docs/                 # Documentation
│   ├── AZURE_DEPLOYMENT_GUIDE.md   # Guide för Azure-deployment
│   ├── FORM_INTEGRATION_GUIDE.md   # Guide för integration med formulären
│   ├── PROJECT_STRUCTURE.md        # Denna fil - projektstruktur
│   └── ...
├── examples/             # Example code and templates
│   ├── curl_examples.sh  # Exempel på API-anrop med curl
│   ├── html_form_example.html   # Exempel på formulär i HTML
│   ├── static-web-app-template/ # Mall för statisk webbapp
│   └── ...
├── infra/                # Infrastructure as code (Bicep templates)
├── scripts/              # Utility scripts for development and maintenance
│   ├── README.md         # Documentation for scripts
│   ├── run-tests.sh      # Test runner script
│   ├── start-dev.sh      # Development environment starter
│   ├── cleanup_old_structure.sh  # Clean up script for old structure
│   ├── validate_new_structure.sh  # Validation script for new structure
│   └── fix_imports.sh    # Script to fix imports
├── src/                  # Source code
│   ├── main.py           # Application entry point
│   └── forms_api/        # Main package
│       ├── __init__.py   # Package initialization
│       ├── app.py        # Application factory
│       ├── config.py     # Configuration settings
│       ├── constants.py  # Application constants
│       ├── crud.py       # Database operations
│       ├── db.py         # Database connection setup
│       ├── exceptions.py # Custom exception classes
│       ├── handlers.py   # Exception handlers
│       ├── models.py     # Database models
│       ├── schemas.py    # Pydantic schemas
│       ├── api/          # API routes and endpoints
│       │   ├── __init__.py
│       │   └── routes/   # Route handlers organized by resource
│       ├── middleware/   # Application middleware components
│       │   ├── __init__.py  # Middleware setup
│       │   ├── README.md    # Middleware documentation
│       │   └── base_middleware.py  # Base middleware class
│       ├── services/     # Business logic services
│       │   ├── __init__.py
│       │   ├── enhanced_services.py
│       │   └── storage/  # Storage services (Azure, local)
│       ├── utils/        # Utility functions and helpers
│       │   ├── __init__.py        # Basic utilities
│       │   ├── README.md          # Utilities documentation
│       │   ├── date_helpers.py    # Date manipulation utilities
│       │   ├── file_helpers.py    # File handling utilities
│       │   ├── logging_config.py  # Logging configuration
│       │   ├── security.py        # Authentication & authorization
│       │   ├── string_helpers.py  # String manipulation utilities
│       │   └── validation.py      # Data validation utilities
│       ├── app.py        # Application factory
│       ├── config.py     # Configuration settings
│       ├── constants.py  # Application constants
│       ├── db.py         # Database connection handling
│       ├── exceptions.py # Custom exception classes
│       ├── handlers.py   # Exception handlers
│       ├── models.py     # Database models
│       └── schemas.py    # Pydantic schemas for validation
│       ├── middleware/   # Application middleware components
│       │   └── __init__.py  # Contains LoggingMiddleware and setup functions
│       ├── utils/        # Utility functions and helpers
│       │   ├── __init__.py  # Common utility functions
│       │   └── validation.py  # Data validation utilities
│       ├── app.py        # Application factory
│       ├── config.py     # Configuration settings
│       ├── constants.py  # Application constants
│       ├── db.py         # Database connection handling
│       ├── exceptions.py # Custom exception classes
│       ├── handlers.py   # Exception handlers
│       ├── models.py     # Database models
│       ├── schemas.py    # Pydantic schemas for validation
│       └── services/     # Service layer
│           ├── __init__.py
│           ├── enhanced_services.py
│           └── storage/  # Storage services
│               ├── __init__.py
│               ├── azure_storage.py  # Azure storage implementation
│               ├── blob.py          # Blob storage interface
│               ├── blob_base.py     # Base blob storage class
│               └── local_storage.py # Local storage implementation
├── tests/                # Test suite
│   ├── conftest.py       # Test configuration and fixtures
│   ├── test_api/         # API tests
│   └── test_services/    # Service layer tests
├── .env-example          # Example environment variables
├── .gitignore           # Git ignore rules
├── Makefile             # Make targets for common operations
├── README.md            # Main project documentation
└── requirements.txt     # Project dependencies
```

## Key Components

### API Layer (src/forms_api/api/)

The API layer contains route definitions organized by resource. This includes:

- `routes/forms.py` - Form template CRUD operations
- `routes/submit.py` - Form submission endpoints
- `routes/files_router.py` - File handling endpoints
- `routes/enhanced_forms.py` - Enhanced form operations

### Middleware (src/forms_api/middleware/)

Middleware components that process requests and responses:

- `LoggingMiddleware` - Logs request and response details
- Other middleware can be added as needed

### Utilities (src/forms_api/utils/)

Helper functions and utilities:

- `filter_none_values()` - Removes None values from dictionaries
- `safe_get()` - Safely retrieves values from dictionaries
- Validation functions for common data types

### Exception Handling (src/forms_api/exceptions.py, handlers.py)

Custom exceptions and handlers:

- `BaseAPIException` - Base class for all API exceptions
- `NotFoundException` - For 404 errors
- `BadRequestException` - For 400 errors
- Handlers for various exception types

### Services Layer (src/forms_api/services/)

Business logic implementation:

- `storage/` - File storage implementations (Azure, Local)
- `enhanced_services.py` - Enhanced form processing services

### Configuration (src/forms_api/config.py, constants.py)

Application configuration:

- `config.py` - Settings and environment variables
- `constants.py` - Application-wide constants

## Architectural Patterns

The codebase follows several architectural patterns:

1. **Dependency Injection** - Services are injected where needed
2. **Repository Pattern** - Database operations are abstracted
3. **Factory Pattern** - `create_app()` constructs the application
4. **Middleware Pattern** - Request processing pipeline

## Additional Resources

- Check the `scripts/README.md` for details on available utility scripts
- The `.env-example` file shows required environment variables
- See `examples/` directory for usage examples
