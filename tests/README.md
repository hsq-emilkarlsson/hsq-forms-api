# HSQ Forms API Tests

This directory contains all test files for the HSQ Forms API project.

## Structure

- `test_api.py` - Main API test suite that validates core functionality
- `test_pytest_api.py` - Pytest-based API tests with fixtures
- `test_file_storage.py` - Tests for file upload/download functionality
- `test_azure_integration.py` - Tests for Azure integration
- `conftest.py` - Pytest fixtures and configuration
- `TESTING.md` - Detailed testing strategy and documentation
- `scripts/` - Contains shell scripts for testing and deployment

## Running Tests

### Using Make Commands (recommended)

From the project root:

```bash
# Run all tests
make test

# Run tests with coverage report
make test-cov

# Run only the API tests
make run-tests
```

### Using Python directly

```bash
# Run API tests
python -m tests.test_api

# Run file storage tests
python -m tests.test_file_storage

# Run Azure integration tests
python -m tests.test_azure_integration
```

### Using pytest

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_pytest_api.py
```

## Shell Scripts

Scripts in the `scripts` directory can be run as:

```bash
# Deployment script
./tests/scripts/deploy-simple.sh

# Clean up Python cache files
./tests/scripts/cleanup_cache.sh
```

See `TESTING.md` for complete testing documentation.
