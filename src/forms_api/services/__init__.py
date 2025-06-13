"""
Service-lager för formulärhantering
"""
import json
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
from src.forms_api.models import FormTemplate, FormSubmission
from src.forms_api.schemas import FormTemplateCreate, FormSubmissionCreate
import jsonschema
from jsonschema import validate, ValidationError
import asyncio
from .webhook_service import WebhookService


class FormBuilderService:
    """Service för att hantera flexibla formulär"""
    
    @staticmethod
    def generate_json_schema(fields: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Generera JSON schema från field definitions"""
        schema = {
            "type": "object",
            "properties": {},
            "required": []
        }
        
        for field in fields:
            field_schema = {
                "type": field["type"],
                "title": field["label"],
                "description": field.get("description") or ""
            }
            
            # Add type-specific properties
            if field["type"] == "string":
                if field.get("min_length"):
                    field_schema["minLength"] = field["min_length"]
                if field.get("max_length"):
                    field_schema["maxLength"] = field["max_length"]
                if field.get("pattern"):
                    field_schema["pattern"] = field["pattern"]
                if field.get("format"):
                    field_schema["format"] = field["format"]
            
            elif field["type"] in ["number", "integer"]:
                if field.get("minimum") is not None:
                    field_schema["minimum"] = field["minimum"]
                if field.get("maximum") is not None:
                    field_schema["maximum"] = field["maximum"]
            
            elif field["type"] == "array":
                field_schema["items"] = {"type": "string"}  # Default
                if field.get("min_items"):
                    field_schema["minItems"] = field["min_items"]
                if field.get("max_items"):
                    field_schema["maxItems"] = field["max_items"]
            
            # Add enum values for dropdowns
            if field.get("enum"):
                field_schema["enum"] = field["enum"]
            
            schema["properties"][field["name"]] = field_schema
            
            if field.get("required", False):
                schema["required"].append(field["name"])
        
        return schema
    
    @staticmethod
    def create_form_template(db: Session, form_data: FormTemplateCreate) -> FormTemplate:
        """Skapa en ny formulärmall"""
        # Konvertera fields till dict format
        fields_dict = [field.model_dump() for field in form_data.fields]
        
        # Generera JSON schema
        schema = FormBuilderService.generate_json_schema(fields_dict)
        
        # Skapa validation rules (kan utökas senare)
        validation_rules = {
            "strict_schema": True,
            "allow_additional_properties": False
        }
        
        form_template = FormTemplate(
            name=form_data.name,
            description=form_data.description,
            project_id=form_data.project_id,
            schema=schema,
            validation_rules=validation_rules,
            created_by=form_data.created_by
        )
        
        db.add(form_template)
        db.commit()
        db.refresh(form_template)
        
        return form_template
    
    @staticmethod
    def validate_submission_data(template: FormTemplate, data: Dict[str, Any]) -> tuple[bool, Optional[List[str]]]:
        """Validera inlämnad data mot formulärschema"""
        try:
            validate(instance=data, schema=template.schema)
            return True, None
        except ValidationError as e:
            errors = []
            
            # Format validation errors nicely
            def extract_errors(error, path=""):
                current_path = f"{path}.{error.path[0]}" if error.path else path
                current_path = current_path.lstrip(".")
                
                if error.context:
                    for sub_error in error.context:
                        extract_errors(sub_error, current_path)
                else:
                    error_msg = f"{current_path}: {error.message}" if current_path else error.message
                    errors.append(error_msg)
            
            extract_errors(e)
            return False, errors
        except Exception as e:
            return False, [f"Schema validation error: {str(e)}"]
    
    @staticmethod
    def create_form_submission(
        db: Session, 
        submission_data: FormSubmissionCreate,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        send_webhook: bool = True
    ) -> FormSubmission:
        """Skapa en ny formulärinlämning"""
        
        # Hämta template
        template = db.query(FormTemplate).filter(
            FormTemplate.id == submission_data.template_id,
            FormTemplate.is_active == True
        ).first()
        
        if not template:
            raise ValueError("Form template not found or inactive")
        
        # Validera data
        is_valid, errors = FormBuilderService.validate_submission_data(template, submission_data.data)
        if not is_valid:
            raise ValueError(f"Validation failed: {'; '.join(errors)}")
        
        # Skapa submission
        submission = FormSubmission(
            template_id=submission_data.template_id,
            data=submission_data.data,
            submitted_from=submission_data.submitted_from,
            ip_address=ip_address
        )
        
        db.add(submission)
        db.commit()
        db.refresh(submission)
        
        # Send webhook notification in a non-blocking way
        if send_webhook:
            # Create a dictionary with submission details for the webhook
            webhook_payload = {
                "id": submission.id,
                "template_id": submission.template_id,
                "template_name": template.name if template else None,
                "data": submission.data,
                "submitted_by": submission.submitted_by,
                "submitted_from_project": submission.submitted_from_project,
                "submitted_at": submission.created_at.isoformat() if submission.created_at else None
            }
            
            # Fire and forget - don't wait for webhook to complete
            asyncio.create_task(WebhookService.send_form_submission_webhook(
                event_type="submission_created",
                form_data=webhook_payload,
                template_id=submission.template_id
            ))
        
        return submission
    
    @staticmethod
    def get_project_templates(db: Session, project_id: str) -> List[FormTemplate]:
        """Hämta alla aktiva formulärmallar för ett projekt"""
        return db.query(FormTemplate).filter(
            FormTemplate.project_id == project_id,
            FormTemplate.is_active == True
        ).order_by(FormTemplate.created_at.desc()).all()
    
    @staticmethod
    def get_template_submissions(
        db: Session, 
        template_id: str, 
        limit: int = 20, 
        offset: int = 0
    ) -> tuple[List[FormSubmission], int]:
        """Hämta submissions för en template"""
        query = db.query(FormSubmission).filter(
            FormSubmission.template_id == template_id
        )
        
        total = query.count()
        submissions = query.order_by(
            FormSubmission.created_at.desc()
        ).limit(limit).offset(offset).all()
        
        return submissions, total
    
    @staticmethod
    def list_templates(db: Session, project_id: Optional[str] = None) -> List[FormTemplate]:
        """List all form templates, optionally filtered by project_id"""
        query = db.query(FormTemplate).filter(FormTemplate.is_active == True)
        if project_id:
            query = query.filter(FormTemplate.project_id == project_id)
        return query.order_by(FormTemplate.created_at.desc()).all()
