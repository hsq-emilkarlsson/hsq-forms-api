"""
Helper module for skipping API tests in CI environment.
"""
import os
import pytest

# Check if we're in CI and should skip API tests
def should_skip_api_tests():
    """Return True if API tests should be skipped (no API server running)"""
    return os.environ.get("SKIP_API_TESTS", "").lower() == "true"

# Create a decorator for skipping API tests
skip_api_test = pytest.mark.skipif(
    should_skip_api_tests(),
    reason="API tests are skipped in CI environment (no API server running)"
)
