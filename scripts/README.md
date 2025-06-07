# HSQ Forms API Scripts

This directory contains various scripts for development, testing, and maintenance of the HSQ Forms API project.

## Setup and Development Scripts

- `setup_dev.sh` - Initializes the development environment (creates directories, installs dependencies).
- `start-dev.sh` - Starts the development server.
- `run-tests.sh` - Runs tests with options for different test types and verbosity levels.

## Structural Scripts

These scripts were used for migrating from the older project structure to the new one, and may be useful for reference or future restructuring:

- `validate_new_structure.sh` - Validates that the new structure works correctly.
- `cleanup_old_structure.sh` - Removes the old structure after validation (creates backups).
- `fix_imports.sh` - Fixes imports to match the new structure.

## Usage

All scripts can be run from the project root with:

```bash
./scripts/[script_name].sh
```

For example:
```bash
./scripts/setup_dev.sh
./scripts/start-dev.sh
./scripts/run-tests.sh -v
```
