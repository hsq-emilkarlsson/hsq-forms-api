"""
Simplified API routes
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import List

from src.forms_api.db import get_db
from src.forms_api.schemas_simple import (
    FormTemplateCreate, 
    FormTemplateResponse, 
    FormSubmissionCreate, 
    FormSubmissionResponse
)
from src.forms_api.service_simple import SimpleFormService

router = APIRouter()


@router.post("/templates", response_model=FormTemplateResponse)
def create_template(
    template_data: FormTemplateCreate,
    db: Session = Depends(get_db)
):
    """Create a new form template"""
    try:
        template = SimpleFormService.create_form_template(db, template_data)
        return FormTemplateResponse.model_validate(template)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/templates", response_model=List[FormTemplateResponse])
def list_templates(
    project_id: str = None,
    db: Session = Depends(get_db)
):
    """List all form templates"""
    templates = SimpleFormService.list_templates(db, project_id)
    return [FormTemplateResponse.model_validate(t) for t in templates]


@router.get("/templates/{template_id}", response_model=FormTemplateResponse)
def get_template(
    template_id: str,
    db: Session = Depends(get_db)
):
    """Get a specific form template"""
    template = SimpleFormService.get_template(db, template_id)
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    return FormTemplateResponse.model_validate(template)


@router.post("/templates/{template_id}/submit", response_model=FormSubmissionResponse)
def submit_form(
    template_id: str,
    submission_data: FormSubmissionCreate,
    request: Request,
    db: Session = Depends(get_db)
):
    """Submit form data"""
    try:
        ip_address = request.client.host if request.client else None
        submission = SimpleFormService.submit_form(db, template_id, submission_data, ip_address)
        return FormSubmissionResponse.model_validate(submission)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/templates/{template_id}/submissions", response_model=List[FormSubmissionResponse])
def get_submissions(
    template_id: str,
    db: Session = Depends(get_db)
):
    """Get all submissions for a template"""
    submissions = SimpleFormService.get_submissions(db, template_id)
    return [FormSubmissionResponse.model_validate(s) for s in submissions]
