"""
Simplified form service
"""
from sqlalchemy.orm import Session
from typing import Dict, Any, List, Optional
import json

from src.forms_api.models_simple import FormTemplate, FormSubmission
from src.forms_api.schemas_simple import FormTemplateCreate, FormSubmissionCreate


class SimpleFormService:
    """Service for handling simple form operations"""
    
    @staticmethod
    def create_form_template(db: Session, template_data: FormTemplateCreate) -> FormTemplate:
        """Create a new form template"""
        
        # Convert fields to JSON schema
        schema = {
            "type": "object",
            "properties": {},
            "required": []
        }
        
        for field in template_data.fields:
            field_schema = {
                "type": field.type,
                "title": field.label
            }
            
            if field.placeholder:
                field_schema["description"] = field.placeholder
                
            if field.options:
                field_schema["enum"] = field.options
                
            schema["properties"][field.name] = field_schema
            
            if field.required:
                schema["required"].append(field.name)
        
        # Create template
        template = FormTemplate(
            name=template_data.name,
            description=template_data.description,
            project_id=template_data.project_id,
            schema=schema
        )
        
        db.add(template)
        db.commit()
        db.refresh(template)
        
        return template
    
    @staticmethod
    def get_template(db: Session, template_id: str) -> Optional[FormTemplate]:
        """Get a form template by ID"""
        return db.query(FormTemplate).filter(FormTemplate.id == template_id).first()
    
    @staticmethod
    def list_templates(db: Session, project_id: Optional[str] = None) -> List[FormTemplate]:
        """List all form templates, optionally filtered by project"""
        query = db.query(FormTemplate)
        
        if project_id:
            query = query.filter(FormTemplate.project_id == project_id)
            
        return query.filter(FormTemplate.is_active == True).all()
    
    @staticmethod
    def submit_form(db: Session, template_id: str, submission_data: FormSubmissionCreate, ip_address: str = None) -> FormSubmission:
        """Submit form data"""
        
        # Verify template exists
        template = db.query(FormTemplate).filter(FormTemplate.id == template_id).first()
        if not template:
            raise ValueError(f"Template {template_id} not found")
        
        # Create submission
        submission = FormSubmission(
            template_id=template_id,
            data=submission_data.data,
            submitted_from=submission_data.submitted_from,
            ip_address=ip_address
        )
        
        db.add(submission)
        db.commit()
        db.refresh(submission)
        
        return submission
    
    @staticmethod
    def get_submissions(db: Session, template_id: str) -> List[FormSubmission]:
        """Get all submissions for a template"""
        return db.query(FormSubmission).filter(FormSubmission.template_id == template_id).all()
