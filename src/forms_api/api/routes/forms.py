"""
Router för flexibla formulär
"""
from fastapi import APIRouter, Depends, HTTPException, Request, Query, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
from src.forms_api.db import get_db
from src.forms_api.models import FormTemplate, FlexibleFormSubmission
from src.forms_api.schemas import (
    FormTemplateCreate, 
    FormTemplateResponse, 
    FlexibleFormSubmissionCreate, 
    FlexibleFormSubmissionResponse
)
from src.forms_api.services import FormBuilderService
from src.forms_api.services.webhook_service import WebhookService

router = APIRouter(tags=["Flexible Forms"])

@router.post("/templates", response_model=FormTemplateResponse, status_code=201)
async def create_form_template(
    form_data: FormTemplateCreate,
    db: Session = Depends(get_db)
):
    """Skapa en ny formulärmall"""
    try:
        template = FormBuilderService.create_form_template(db, form_data)
        return template
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/templates/project/{project_id}", response_model=List[FormTemplateResponse])
async def get_project_templates(
    project_id: str,
    db: Session = Depends(get_db)
):
    """Hämta alla formulärmallar för ett projekt"""
    templates = FormBuilderService.get_project_templates(db, project_id)
    return templates

@router.get("/templates/{template_id}", response_model=FormTemplateResponse)
async def get_template(
    template_id: str,
    language: Optional[str] = Query(None, description="Language code for localized content"),
    db: Session = Depends(get_db)
):
    """Hämta en specifik formulärmall"""
    template = db.query(FormTemplate).filter(
        FormTemplate.id == template_id,
        FormTemplate.is_active == True
    ).first()
    
    if not template:
        raise HTTPException(status_code=404, detail="Form template not found")
    
    # If language is specified and available, prepare localized response
    if language and language in template.available_languages:
        # Clone the template to avoid modifying the database object
        template_dict = template.to_dict()
        
        # Apply translations if they exist for the requested language
        if language in template.translations:
            lang_data = template.translations.get(language, {})
            if "title" in lang_data:
                template_dict["title"] = lang_data["title"]
            if "description" in lang_data:
                template_dict["description"] = lang_data["description"]
            if "schema" in lang_data:
                template_dict["schema"] = lang_data["schema"]
            
            # Return the translated template as the response
            return template_dict
    
    return template

@router.post("/templates/{template_id}/submit", response_model=dict, status_code=201)
async def submit_flexible_form(
    template_id: str,
    submission_data: dict,  # Dynamisk data baserad på template
    request: Request,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Skicka in formulärdata för en flexibel mall"""
    try:
        # Skapa submission object
        form_submission = FlexibleFormSubmissionCreate(
            template_id=template_id,
            data=submission_data.get("data", submission_data),  # Acceptera både {"data": {...}} och direkta data
            submitted_by=submission_data.get("submitted_by"),
            submitted_from_project=request.headers.get("x-project-id", submission_data.get("project_id"))
        )
        
        # Set send_webhook=False because we'll handle it manually with background_tasks
        submission = FormBuilderService.create_form_submission(
            db=db,
            submission_data=form_submission,
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent"),
            send_webhook=False
        )
        
        # Get template for additional information
        template = db.query(FormTemplate).filter(
            FormTemplate.id == template_id,
            FormTemplate.is_active == True
        ).first()
        
        # Send webhook in background task
        webhook_payload = {
            "id": submission.id,
            "template_id": submission.template_id,
            "template_name": template.name if template else None,
            "data": submission.data,
            "submitted_by": submission.submitted_by,
            "submitted_from_project": submission.submitted_from_project,
            "submitted_at": submission.created_at.isoformat() if submission.created_at else None
        }
        
        background_tasks.add_task(
            WebhookService.send_form_submission_webhook,
            event_type="submission_created",
            form_data=webhook_payload,
            template_id=submission.template_id
        )
        
        return {
            "status": "success",
            "message": "Formulär skickat framgångsrikt",
            "submission_id": submission.id,
            "submitted_at": submission.created_at.isoformat()
        }
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server error: {str(e)}")

@router.get("/templates/{template_id}/submissions", response_model=dict)
async def get_template_submissions(
    template_id: str,
    page: int = Query(1, ge=1, description="Sidnummer"),
    limit: int = Query(20, ge=1, le=100, description="Antal per sida"),
    db: Session = Depends(get_db)
):
    """Hämta inlämningar för en formulärmall"""
    offset = (page - 1) * limit
    
    submissions, total = FormBuilderService.get_template_submissions(
        db, template_id, limit, offset
    )
    
    return {
        "status": "success",
        "data": [submission.to_dict() for submission in submissions],
        "pagination": {
            "page": page,
            "limit": limit,
            "total": total,
            "pages": (total + limit - 1) // limit
        }
    }

@router.get("/submissions/{submission_id}", response_model=FlexibleFormSubmissionResponse)
async def get_submission(
    submission_id: str,
    db: Session = Depends(get_db)
):
    """Hämta en specifik inlämning"""
    submission = db.query(FlexibleFormSubmission).filter(
        FlexibleFormSubmission.id == submission_id
    ).first()
    
    if not submission:
        raise HTTPException(status_code=404, detail="Submission not found")
    
    return submission

@router.put("/submissions/{submission_id}/status")
async def update_submission_status(
    submission_id: str,
    status_data: dict,
    db: Session = Depends(get_db)
):
    """Uppdatera bearbetningsstatus för en inlämning"""
    submission = db.query(FlexibleFormSubmission).filter(
        FlexibleFormSubmission.id == submission_id
    ).first()
    
    if not submission:
        raise HTTPException(status_code=404, detail="Submission not found")
    
    # Uppdatera status
    if "is_processed" in status_data:
        submission.is_processed = status_data["is_processed"]
    
    if "processing_notes" in status_data:
        submission.processing_notes = status_data["processing_notes"]
    
    db.commit()
    
    return {
        "status": "success",
        "message": "Status uppdaterad",
        "submission_id": submission.id
    }

# Endpoint för att hämta formulärschema (för frontend att rendera formulär)
@router.get("/templates/{template_id}/schema")
async def get_template_schema(
    template_id: str,
    language: Optional[str] = Query(None, description="Language code for localized content"),
    db: Session = Depends(get_db)
):
    """Hämta JSON schema för en formulärmall (för frontend rendering)"""
    template = db.query(FormTemplate).filter(
        FormTemplate.id == template_id,
        FormTemplate.is_active == True
    ).first()
    
    if not template:
        raise HTTPException(status_code=404, detail="Form template not found")
    
    response = {
        "template_id": template.id,
        "name": template.name,
        "description": template.description,
        "schema": template.schema,
        "validation_rules": template.validation_rules,
        "default_language": template.default_language,
        "available_languages": template.available_languages
    }
    
    # If language is specified and available, use translated content
    if language and language in template.available_languages and language in template.translations:
        lang_data = template.translations.get(language, {})
        if "name" in lang_data:
            response["name"] = lang_data["name"]
        if "description" in lang_data:
            response["description"] = lang_data["description"]
        if "schema" in lang_data:
            response["schema"] = lang_data["schema"]
        if "validation_rules" in lang_data:
            response["validation_rules"] = lang_data["validation_rules"]
    
    return response

@router.get("/{language_code}/templates", response_model=List[FormTemplateResponse])
async def get_templates_by_language(
    language_code: str,
    project_id: Optional[str] = Query(None, description="Filter by project ID"),
    db: Session = Depends(get_db)
):
    """Hämta formulärmallar för specifikt språk"""
    # Base query to get templates
    query = db.query(FormTemplate).filter(FormTemplate.is_active == True)
    
    # Filter by project if specified
    if project_id:
        query = query.filter(FormTemplate.project_id == project_id)
    
    # Filter to include only templates that support the specified language
    # This uses the JSON 'available_languages' field with Postgres-specific JSON operators
    query = query.filter(language_code.in_(FormTemplate.available_languages))
    
    templates = query.all()
    
    # Process each template to use translations if available
    localized_templates = []
    for template in templates:
        # Start with the original template
        template_dict = template.to_dict()
        
        # Apply translations if they exist
        if language_code in template.translations:
            lang_data = template.translations.get(language_code, {})
            if "title" in lang_data:
                template_dict["title"] = lang_data["title"]
            if "description" in lang_data:
                template_dict["description"] = lang_data["description"]
            if "schema" in lang_data:
                template_dict["schema"] = lang_data["schema"]
        
        localized_templates.append(template_dict)
    
    return localized_templates
