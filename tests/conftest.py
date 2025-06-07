"""
Configuration file for pytest.
"""
import os
import sys
import pytest
from pathlib import Path

# Add the project root to Python path so imports work correctly
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Add src directory to path for package-specific tests
src_path = project_root / "src"
if src_path.exists():
    sys.path.insert(0, str(src_path))

# Define API URL for tests
API_URL = os.environ.get("TEST_API_URL", "http://localhost:8001")

@pytest.fixture
def api_url():
    """Return the API URL for tests"""
    return API_URL

@pytest.fixture
def test_project():
    """Return a test project name"""
    return "test-project"

@pytest.fixture
def sample_form_template():
    """Return a sample form template for testing"""
    return {
        "title": "Contact Form",
        "description": "Simple contact form for testing",
        "project_id": "test-project",
        "schema": {
            "fields": [
                {
                    "name": "name",
                    "label": "Name", 
                    "type": "text",
                    "required": True,
                    "placeholder": "Your full name"
                },
                {
                    "name": "email",
                    "label": "Email",
                    "type": "email", 
                    "required": True,
                    "placeholder": "Your email address"
                },
                {
                    "name": "message",
                    "label": "Message",
                    "type": "textarea",
                    "required": True,
                    "placeholder": "Write your message here"
                }
            ]
        },
        "settings": {
            "submit_button_text": "Send Message",
            "success_message": "Thank you for contacting us!",
            "store_submissions": True
        }
    }

@pytest.fixture
def sample_form_submission():
    """Return a sample form submission data for testing"""
    return {
        "data": {
            "name": "John Doe",
            "email": "john.doe@example.com",
            "message": "Hello, I'm interested in your services. Can you please contact me?"
        }
    }
