"""
API routes for the HSQ Forms API
"""
from fastapi import APIRouter, Depends, HTTPException, Request, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from slowapi import Limiter
from slowapi.util import get_remote_address
import json

from src.forms_api.db import get_db
from src.forms_api.models import FormTemplate, FormSubmission, FlexibleFormAttachment
from src.forms_api.schemas import (
    FormTemplateCreate, 
    FormTemplateResponse, 
    FormSubmissionCreate, 
    FormSubmissionResponse,
    FormSubmissionWithFilesCreate,
    FormSubmissionWithFilesResponse,
    FileAttachmentResponse,
    FileUploadResponse,
    CustomerValidationRequest,
    CustomerValidationResponse,
    B2BSupportSubmissionRequest,
    B2BSupportSubmissionResponse
)
from src.forms_api.services import FormBuilderService
from src.forms_api.esb_service import esb_service
from src.forms_api.mock_esb_service import mock_esb_service
from src.forms_api.config import get_settings
from src.forms_api.services.storage.azure_storage import AzureStorageService
from src.forms_api.services.storage.local_storage import LocalStorageService
import httpx
import logging
import os

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)
logger = logging.getLogger(__name__)

# Storage service dependency
def get_storage_service():
    """Get storage service based on configuration"""
    settings = get_settings()
    if settings.storage_type == "azure":
        return AzureStorageService()
    else:
        return LocalStorageService()


@router.post("/templates", response_model=FormTemplateResponse)
@limiter.limit("5/minute")  # Admin endpoint - low rate limit
def create_template(
    request: Request,
    template_data: FormTemplateCreate,
    db: Session = Depends(get_db)
):
    """Create a new form template - Admin endpoint with rate limiting"""
    try:
        template = FormBuilderService.create_form_template(db, template_data)
        return FormTemplateResponse.model_validate(template)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/templates", response_model=List[FormTemplateResponse])
@limiter.limit("30/minute")  # Read endpoint - higher rate limit
def list_templates(
    request: Request,
    project_id: str = None,
    db: Session = Depends(get_db)
):
    """List all form templates"""
    templates = FormBuilderService.list_templates(db, project_id) if project_id else FormBuilderService.list_templates(db)
    return [FormTemplateResponse.model_validate(t) for t in templates]


@router.get("/templates/{template_id}", response_model=FormTemplateResponse)
@limiter.limit("60/minute")  # Template read - high rate limit
def get_template(
    request: Request,
    template_id: str,
    db: Session = Depends(get_db)
):
    """Get a specific form template"""
    template = db.query(FormTemplate).filter(FormTemplate.id == template_id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    return FormTemplateResponse.model_validate(template)


@router.post("/templates/{template_id}/submit", response_model=FormSubmissionResponse)
@limiter.limit("10/minute")  # Form submission - moderate rate limit
def submit_form(
    request: Request,
    template_id: str,
    submission_data: FormSubmissionCreate,
    db: Session = Depends(get_db)
):
    """Submit form data - Rate limited to prevent spam"""
    try:
        ip_address = request.client.host if request.client else None
        # Create form submission directly
        submission = FormSubmission(
            template_id=template_id,
            data=submission_data.data,
            submitted_from=submission_data.submitted_from,
            ip_address=ip_address
        )
        db.add(submission)
        db.commit()
        db.refresh(submission)
        return FormSubmissionResponse.model_validate(submission)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/templates/{template_id}/submissions", response_model=List[FormSubmissionResponse])
@limiter.limit("20/minute")  # Admin endpoint - moderate rate limit
def get_submissions(
    request: Request,
    template_id: str,
    db: Session = Depends(get_db)
):
    """Get all submissions for a template - Admin endpoint"""
    submissions = db.query(FormSubmission).filter(FormSubmission.template_id == template_id).all()
    return [FormSubmissionResponse.model_validate(s) for s in submissions]


# File upload endpoints
@router.post("/templates/{template_id}/upload", response_model=FileUploadResponse)
@limiter.limit("10/minute")  # File upload - moderate rate limit
async def upload_file_to_template(
    request: Request,
    template_id: str,
    file: UploadFile = File(...),
    field_name: str = Form(...),
    submission_id: Optional[str] = Form(None),
    db: Session = Depends(get_db),
    storage_service = Depends(get_storage_service)
):
    """
    Upload file for a specific template and form submission
    Organiserar filer i mappstruktur: forms/{template_id}/{year}/{month}/{submission_id}/
    """
    try:
        # Validate template exists
        template = db.query(FormTemplate).filter(FormTemplate.id == template_id).first()
        if not template:
            raise HTTPException(status_code=404, detail="Template not found")
        
        # If no submission_id provided, we're doing a temporary upload
        if not submission_id:
            import uuid
            submission_id = f"temp_{str(uuid.uuid4())[:8]}"
        
        # Validate file size and type
        settings = get_settings()
        if hasattr(file, 'size') and file.size > settings.max_attachment_size_mb * 1024 * 1024:
            raise HTTPException(
                status_code=400, 
                detail=f"File too large. Max size: {settings.max_attachment_size_mb}MB"
            )
        
        # Upload file with organized folder structure
        form_type = template_id  # Use template_id as form_type
        blob_path, file_size, content_type, blob_url = await storage_service.upload_file(
            file=file,
            submission_id=submission_id,
            form_type=form_type,
            field_name=field_name
        )
        
        # Create attachment record
        attachment = FlexibleFormAttachment(
            submission_id=submission_id,
            field_name=field_name,
            original_filename=file.filename or "unknown",
            stored_filename=blob_path.split('/')[-1],  # Just the filename part
            file_size=file_size,
            content_type=content_type,
            blob_url=blob_url if hasattr(storage_service, 'account_name') else None,
            upload_status="uploaded",
            form_type=form_type,
            storage_path=blob_path
        )
        
        db.add(attachment)
        db.commit()
        db.refresh(attachment)
        
        logger.info(f"File uploaded successfully: {file.filename} -> {blob_path}")
        
        return FileUploadResponse(
            success=True,
            attachment_id=attachment.id,
            filename=file.filename or "unknown",
            file_size=file_size,
            content_type=content_type,
            storage_path=blob_path,
            message=f"File uploaded successfully to {form_type} folder structure"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"File upload error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


@router.post("/templates/{template_id}/submit-with-files", response_model=FormSubmissionWithFilesResponse)
@limiter.limit("10/minute")  # Form submission with files - moderate rate limit  
async def submit_form_with_files(
    request: Request,
    template_id: str,
    data: str = Form(...),  # JSON string of form data
    submitted_from: Optional[str] = Form(None),
    files: List[UploadFile] = File(default=[]),
    file_fields: List[str] = Form(default=[]),  # Which field each file belongs to
    db: Session = Depends(get_db),
    storage_service = Depends(get_storage_service)
):
    """
    Submit form data with file attachments
    Skapar submission först, sedan laddar upp filer till rätt mappar
    """
    try:
        # Validate template exists
        template = db.query(FormTemplate).filter(FormTemplate.id == template_id).first()
        if not template:
            raise HTTPException(status_code=404, detail="Template not found")
        
        # Parse form data
        try:
            form_data = json.loads(data)
        except json.JSONDecodeError:
            raise HTTPException(status_code=400, detail="Invalid JSON in form data")
        
        # Create form submission first
        ip_address = request.client.host if request.client else None
        submission = FormSubmission(
            template_id=template_id,
            data=form_data,
            submitted_from=submitted_from,
            ip_address=ip_address
        )
        db.add(submission)
        db.commit()
        db.refresh(submission)
        
        # Upload files if any
        attachments = []
        if files and len(files) > 0:
            # Ensure we have field names for each file
            if len(file_fields) != len(files):
                # If not enough field names, use generic names
                file_fields = file_fields + [f"attachment_{i}" for i in range(len(file_fields), len(files))]
            
            for file, field_name in zip(files, file_fields):
                if file.filename:  # Skip empty files
                    try:
                        # Upload with organized folder structure
                        blob_path, file_size, content_type, blob_url = await storage_service.upload_file(
                            file=file,
                            submission_id=submission.id,
                            form_type=template_id,
                            field_name=field_name
                        )
                        
                        # Create attachment record
                        attachment = FlexibleFormAttachment(
                            submission_id=submission.id,
                            field_name=field_name,
                            original_filename=file.filename,
                            stored_filename=blob_path.split('/')[-1],
                            file_size=file_size,
                            content_type=content_type,
                            blob_url=blob_url if hasattr(storage_service, 'account_name') else None,
                            upload_status="uploaded",
                            form_type=template_id,
                            storage_path=blob_path
                        )
                        
                        db.add(attachment)
                        attachments.append(attachment)
                        
                    except Exception as e:
                        logger.error(f"Failed to upload file {file.filename}: {str(e)}")
                        # Continue with other files, but log the error
        
        db.commit()
        
        # Refresh attachments from DB
        for attachment in attachments:
            db.refresh(attachment)
        
        logger.info(f"Form submitted with {len(attachments)} files to {template_id} folder structure")
        
        # Return response with attachments
        response_data = FormSubmissionResponse.model_validate(submission)
        attachment_responses = [FileAttachmentResponse.model_validate(att) for att in attachments]
        
        return FormSubmissionWithFilesResponse(
            **response_data.model_dump(),
            attachments=attachment_responses
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Form submission with files error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Submission failed: {str(e)}")


@router.get("/attachments/{attachment_id}", response_model=FileAttachmentResponse)
@limiter.limit("30/minute")  # File info endpoint - higher rate limit
def get_attachment_info(
    request: Request,
    attachment_id: str,
    db: Session = Depends(get_db)
):
    """Get file attachment information"""
    attachment = db.query(FlexibleFormAttachment).filter(FlexibleFormAttachment.id == attachment_id).first()
    if not attachment:
        raise HTTPException(status_code=404, detail="Attachment not found")
    
    return FileAttachmentResponse.model_validate(attachment)


@router.delete("/attachments/{attachment_id}")
@limiter.limit("10/minute")  # Delete endpoint - moderate rate limit
async def delete_attachment(
    request: Request,
    attachment_id: str,
    db: Session = Depends(get_db),
    storage_service = Depends(get_storage_service)
):
    """Delete file attachment from storage and database"""
    try:
        # Get attachment record
        attachment = db.query(FlexibleFormAttachment).filter(FlexibleFormAttachment.id == attachment_id).first()
        if not attachment:
            raise HTTPException(status_code=404, detail="Attachment not found")
        
        # Delete from storage
        try:
            if hasattr(storage_service, 'delete_file'):
                await storage_service.delete_file(attachment.storage_path, attachment.submission_id)
        except Exception as e:
            logger.warning(f"Failed to delete file from storage: {str(e)}")
            # Continue to delete DB record even if storage deletion fails
        
        # Delete from database
        db.delete(attachment)
        db.commit()
        
        return {"success": True, "message": "Attachment deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Delete attachment error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Delete failed: {str(e)}")



# ESB Integration endpoints
@router.post("/esb/validate-customer", response_model=CustomerValidationResponse)
@limiter.limit("30/minute")  # Customer validation - higher rate limit
async def validate_customer(
    request: Request,
    validation_request: CustomerValidationRequest
):
    """Validate customer number through Husqvarna ESB API - Rate limited"""
    try:
        settings = get_settings()
        
        # Use mock service for testing if in development mode
        if settings.environment == "development":
            account_id = await mock_esb_service.validate_customer(
                request.customer_number, 
                request.customer_code
            )
        else:
            account_id = await esb_service.validate_customer(
                request.customer_number, 
                request.customer_code
            )
        
        if account_id:
            return CustomerValidationResponse(
                is_valid=True,
                account_id=account_id,
                message="Kundnummer giltigt"
            )
        else:
            return CustomerValidationResponse(
                is_valid=False,
                account_id=None,
                message="Ogiltigt kundnummer"
            )
            
    except Exception as e:
        return CustomerValidationResponse(
            is_valid=False,
            account_id=None,
            message=f"Validering misslyckades: {str(e)}"
        )


@router.post("/esb/b2b-support", response_model=B2BSupportSubmissionResponse)
async def submit_b2b_support(
    request: B2BSupportSubmissionRequest,
    db: Session = Depends(get_db),
    http_request: Request = None
):
    """Submit B2B support form with ESB integration"""
    try:
        settings = get_settings()
        
        # Step 1: Validate customer
        if settings.environment == "development":
            account_id = await mock_esb_service.validate_customer(
                request.customer_number,
                request.customer_code
            )
        else:
            account_id = await esb_service.validate_customer(
                request.customer_number,
                request.customer_code
            )
        
        if not account_id:
            return B2BSupportSubmissionResponse(
                success=False,
                submission_id="",
                message="Ogiltigt kundnummer"
            )
        
        # Step 2: Store form data in database
        form_data = {
            "customerNumber": request.customer_number,
            "customerCode": request.customer_code,
            "accountId": account_id,
            "description": request.description,
            "companyName": request.company_name,
            "contactPerson": request.contact_person,
            "email": request.email,
            "phone": request.phone,
            "supportType": request.support_type,
            "subject": request.subject,
            "urgency": request.urgency
        }
        
        # Create form submission record
        ip_address = http_request.client.host if http_request and http_request.client else None
        
        # Use a specific template ID for B2B support forms
        b2b_template_id = "958915ec-fed1-4e7e-badd-4598502fe6a1"
        
        # Create form submission record directly
        submission = FormSubmission(
            template_id=b2b_template_id,
            data=form_data,
            submitted_from="B2B Support Form",
            ip_address=ip_address
        )
        db.add(submission)
        db.commit()
        db.refresh(submission)
        
        # Step 3: Create case in ESB
        try:
            if settings.environment == "development":
                esb_response = await mock_esb_service.create_case(
                    account_id=account_id,
                    customer_number=request.customer_number,
                    customer_code=request.customer_code,
                    description=request.description
                )
            else:
                esb_response = await esb_service.create_case(
                    account_id=account_id,
                    customer_number=request.customer_number,
                    customer_code=request.customer_code,
                    description=request.description
                )
            
            case_id = esb_response.get("caseId") or esb_response.get("id")
            
            return B2BSupportSubmissionResponse(
                success=True,
                submission_id=submission.id,
                case_id=case_id,
                account_id=account_id,
                message="Ärende skapat framgångsrikt"
            )
            
        except Exception as esb_error:
            # Form data is saved, but ESB case creation failed
            return B2BSupportSubmissionResponse(
                success=True,
                submission_id=submission.id,
                case_id=None,
                account_id=account_id,
                message=f"Formulär sparat men ärendeeskapande misslyckades: {str(esb_error)}"
            )
        
    except Exception as e:
        return B2BSupportSubmissionResponse(
            success=False,
            submission_id="",
            message=f"Fel vid submission: {str(e)}"
        )


# Direct Husqvarna Group API validation (bypasses CORS)
@router.get("/husqvarna/validate-customer")
async def validate_customer_husqvarna(
    customer_number: str,
    customer_code: str = "DOJ"
):
    """
    Validate customer number directly against Husqvarna Group API
    
    This endpoint acts as a proxy to avoid CORS issues when calling external APIs
    from the frontend. It validates the customer number against Husqvarna Group's
    accounts API and returns validation status and account information.
    """
    logger = logging.getLogger(__name__)
    
    # Input validation
    if not customer_number or len(customer_number) < 3:
        return {
            "valid": False,
            "source": "input_validation",
            "customer_number": customer_number,
            "customer_code": customer_code,
            "message": f"❌ Kundnummer för kort: '{customer_number}' (minimum 3 tecken)"
        }
    
    # Get Husqvarna API configuration from environment
    husqvarna_api_base_url = os.getenv(
        'HUSQVARNA_API_BASE_URL', 
        'https://api-qa.integration.husqvarnagroup.com/hqw170/v1'
    )
    husqvarna_api_key = os.getenv(
        'HUSQVARNA_API_KEY', 
        '3d9c4d8a3c5c47f1a2a0ec096496a786'
    )
    
    if not husqvarna_api_key:
        logger.error("Husqvarna API key not configured")
        return {
            "valid": False,
            "source": "configuration_error",
            "customer_number": customer_number,
            "customer_code": customer_code,
            "message": "⚠️ API-konfigurationsfel"
        }
    
    # Log the validation attempt
    logger.info(f"Validating customer {customer_number} with code {customer_code}")
    
    try:
        # Call Husqvarna Group API
        url = f"{husqvarna_api_base_url}/accounts"
        params = {
            "customerNumber": customer_number,
            "customerCode": customer_code
        }
        headers = {
            "Ocp-Apim-Subscription-Key": husqvarna_api_key,
            "Content-Type": "application/json"
        }
        
        logger.debug(f"Making request to {url} with params {params}")
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url, params=params, headers=headers)
            
        logger.debug(f"Husqvarna API response status: {response.status_code}")
        
        if response.status_code == 200:
            try:
                result = response.json()
                logger.debug(f"Husqvarna API response: {result}")
                
                if result.get("accountId"):
                    return {
                        "valid": True,
                        "source": "husqvarna_api",
                        "customer_number": customer_number,
                        "account_id": result["accountId"],
                        "customer_code": customer_code,
                        "message": f"✅ Kundnummer {customer_number} verifierat! (Account ID: {result['accountId'][:8]}...)"
                    }
                else:
                    return {
                        "valid": False,
                        "source": "husqvarna_api",
                        "customer_number": customer_number,
                        "customer_code": customer_code,
                        "message": f"❌ Kundnummer {customer_number} hittades inte i Husqvarna Group systemet"
                    }
                    
            except Exception as json_error:
                logger.error(f"Failed to parse Husqvarna API response: {json_error}")
                logger.error(f"Response content: {response.text}")
                return {
                    "valid": False,
                    "source": "api_response_error",
                    "customer_number": customer_number,
                    "customer_code": customer_code,
                    "message": "⚠️ Ogiltigt svar från Husqvarna API"
                }
                
        elif response.status_code == 404:
            return {
                "valid": False,
                "source": "husqvarna_api",
                "customer_number": customer_number,
                "customer_code": customer_code,
                "message": f"❌ Kundnummer {customer_number} hittades inte i Husqvarna Group systemet"
            }
            
        else:
            logger.warning(f"Husqvarna API returned status {response.status_code}: {response.text}")
            # Fall back to basic format validation
            return await fallback_validation_local(customer_number, customer_code)
            
    except httpx.TimeoutException:
        logger.error("Timeout when calling Husqvarna API")
        return await fallback_validation_local(customer_number, customer_code)
        
    except httpx.RequestError as e:
        logger.error(f"Request error when calling Husqvarna API: {e}")
        return await fallback_validation_local(customer_number, customer_code)
        
    except Exception as e:
        logger.error(f"Unexpected error validating customer: {e}")
        return await fallback_validation_local(customer_number, customer_code)


async def fallback_validation_local(customer_number: str, customer_code: str):
    """
    Fallback validation using basic format checking
    """
    # Basic format validation
    is_valid_format = (
        len(customer_number) >= 3 and 
        len(customer_number) <= 20 and 
        customer_number.replace(" ", "").replace("-", "").isalnum()
    )
    
    if is_valid_format:
        return {
            "valid": True,
            "source": "format_validation",
            "customer_number": customer_number,
            "customer_code": customer_code,
            "message": f"🟡 Kundnummer {customer_number} har giltigt format (offline validering - ej verifierat)"
        }
    else:
        return {
            "valid": False,
            "source": "format_validation", 
            "customer_number": customer_number,
            "customer_code": customer_code,
            "message": f"❌ Ogiltigt kundnummer format: '{customer_number}'"
        }
