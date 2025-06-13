# HSQ Forms API Scripts

This directory contains various scripts for development, testing, deployment, and maintenance of the HSQ Forms API project.

## Setup and Development Scripts

- `setup_dev.sh` - Initializes the development environment (creates directories, installs dependencies).
- `start-dev.sh` - Starts the development server.
- `run-tests.sh` - Runs tests with options for different test types and verbosity levels.

## Form Management Scripts

- `create-new-form.sh` - Creates a new form based on the react-form-template.
- `setup_form_app.sh` - Sets up form applications.
- `setup_new_form.sh` - Alternative form setup script.

## Deployment Scripts

- `deploy-container.sh` - Comprehensive container deployment script for the API.
- `deploy-production.sh` - Production deployment automation.
- `registry-deploy.sh` - Container registry deployment.

## Structural Scripts

These scripts were used for migrating from the older project structure to the new one, and may be useful for reference or future restructuring:

- `validate_new_structure.sh` - Validates that the new structure works correctly.
- `cleanup_old_structure.sh` - Removes the old structure after validation (creates backups).
- `fix_imports.sh` - Fixes imports to match the new structure.

## Database Scripts

- `apply_language_migration.sh` - Applies language support database migrations.
- `init-db.sql` - Database initialization script.

## Usage

All scripts can be run from the project root with:

```bash
./scripts/[script_name].sh
```

### Examples

Development:
```bash
./scripts/setup_dev.sh
./scripts/start-dev.sh
./scripts/run-tests.sh -v
```

Form Creation:
```bash
./scripts/create-new-form.sh my-contact-form
```

Deployment:
```bash
./scripts/deploy-container.sh local
./scripts/deploy-container.sh status
```
