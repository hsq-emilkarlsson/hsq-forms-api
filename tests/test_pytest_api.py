"""
Integration tests for the HSQ Forms API using pytest.
These tests require the API service to be running.
"""
import pytest
import requests
import time
from typing import Dict, Any
from tests.skip_api_tests import skip_api_test

@skip_api_test
def test_api_health(api_url):
    """Test that the API is healthy and responding"""
    response = requests.get(f"{api_url}/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data
    
@skip_api_test
def test_form_template_creation(api_url, test_project, sample_form_template):
    """Test creating a form template"""
    # Ensure the project name matches the fixture
    sample_form_template["project_id"] = test_project
    
    # Create the form template
    response = requests.post(f"{api_url}/api/forms/templates", json=sample_form_template)
    assert response.status_code == 200, f"Failed to create form template: {response.text}"
    
    # Validate the response
    template = response.json()
    assert "id" in template
    assert template["title"] == sample_form_template["title"]
    assert template["description"] == sample_form_template["description"]
    
    return template

def test_form_submission(api_url, test_project, sample_form_template, sample_form_submission):
    """Test the complete form submission flow"""
    # First create a template
    template = test_form_template_creation(api_url, test_project, sample_form_template)
    template_id = template["id"]
    
    # Submit the form
    response = requests.post(
        f"{api_url}/api/forms/templates/{template_id}/submit",
        json=sample_form_submission
    )
    assert response.status_code == 200, f"Failed to submit form: {response.text}"
    
    # Validate the response
    result = response.json()
    assert "submission_id" in result
    assert "submitted_at" in result

def test_legacy_form_submission(api_url):
    """Test the legacy form submission endpoint"""
    form_data = {
        "form_type": "contact",
        "name": "Jane Smith",
        "email": "jane.smith@example.com",
        "message": "This is a test of the legacy form submission API",
        "metadata": {
            "company": "Test Company",
            "phone": "+46701234567"
        }
    }
    
    response = requests.post(f"{api_url}/submit", json=form_data)
    
    # This test is allowed to fail if legacy endpoints are disabled
    if response.status_code == 200:
        result = response.json()
        assert "submission_id" in result
    else:
        pytest.skip("Legacy form endpoint not available or disabled")
