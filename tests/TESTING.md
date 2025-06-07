# Testing Strategy for HSQ Forms API

This document outlines the testing approach for the HSQ Forms API project.

## Overview

The project uses multiple testing methods:

1. **Integration Tests**: Test the API endpoints and their interaction with the database
2. **Unit Tests**: Test individual components and functions
3. **Azure Integration Tests**: Test integration with Azure services
4. **File Storage Tests**: Test file upload, download, and management

## Test Organization

- `tests/test_api.py` - Script-based API tests (can be run directly)
- `tests/test_pytest_api.py` - Pytest-based API tests
- `tests/test_file_storage.py` - Tests for file storage functionality
- `tests/test_azure_integration.py` - Tests for Azure integration
- `tests/conftest.py` - Pytest fixtures and configuration

## Running Tests

### Using Make Commands (recommended)

```bash
# Run all tests
make test

# Run tests with coverage report
make test-cov

# Run only the API tests
make run-tests
```

### Using pytest directly

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_pytest_api.py

# Run specific test
pytest tests/test_pytest_api.py::test_api_health

# Run with verbose output
pytest -v
```

### Using Python directly

```bash
python -m tests.test_api
```

## Test Environment Variables

The tests use the following environment variables:

- `TEST_API_URL`: The URL of the API to test (default: http://localhost:8001)
- `AZURE_STORAGE_CONNECTION_STRING`: For Azure storage tests
- `AZURE_STORAGE_ACCOUNT_NAME`: For Azure storage tests
- `AZURE_STORAGE_ACCOUNT_KEY`: For Azure storage tests

## Adding New Tests

When adding new tests:

1. Add unit tests for new functionality
2. Add integration tests for new API endpoints
3. Follow the existing patterns for test organization
4. Update fixtures in conftest.py as needed
5. Ensure tests are properly isolated and don't depend on each other

## CI/CD Integration

The tests are designed to be run in a CI/CD pipeline with:
```yaml
- name: Run tests
  run: make test-cov
```

## Test Data Management

Test data is managed through fixtures defined in `conftest.py`. Use these fixtures in your tests to ensure consistency.
