"""
API routes for the HSQ Forms API
"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import List

from src.forms_api.db import get_db
from src.forms_api.models import FormTemplate, FormSubmission
from src.forms_api.schemas import (
    FormTemplateCreate, 
    FormTemplateResponse, 
    FormSubmissionCreate, 
    FormSubmissionResponse,
    CustomerValidationRequest,
    CustomerValidationResponse,
    B2BSupportSubmissionRequest,
    B2BSupportSubmissionResponse
)
from src.forms_api.services import FormBuilderService
from src.forms_api.esb_service import esb_service
from src.forms_api.mock_esb_service import mock_esb_service
from src.forms_api.config import get_settings
import httpx
import logging
import os

router = APIRouter()


@router.post("/templates", response_model=FormTemplateResponse)
def create_template(
    template_data: FormTemplateCreate,
    db: Session = Depends(get_db)
):
    """Create a new form template"""
    try:
        template = FormBuilderService.create_form_template(db, template_data)
        return FormTemplateResponse.model_validate(template)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/templates", response_model=List[FormTemplateResponse])
def list_templates(
    project_id: str = None,
    db: Session = Depends(get_db)
):
    """List all form templates"""
    templates = FormBuilderService.list_templates(db, project_id) if project_id else FormBuilderService.list_templates(db)
    return [FormTemplateResponse.model_validate(t) for t in templates]


@router.get("/templates/{template_id}", response_model=FormTemplateResponse)
def get_template(
    template_id: str,
    db: Session = Depends(get_db)
):
    """Get a specific form template"""
    template = db.query(FormTemplate).filter(FormTemplate.id == template_id).first()
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
def get_submissions(
    template_id: str,
    db: Session = Depends(get_db)
):
    """Get all submissions for a template"""
    submissions = db.query(FormSubmission).filter(FormSubmission.template_id == template_id).all()
    return [FormSubmissionResponse.model_validate(s) for s in submissions]


# ESB Integration endpoints
@router.post("/esb/validate-customer", response_model=CustomerValidationResponse)
async def validate_customer(request: CustomerValidationRequest):
    """Validate customer number through Husqvarna ESB API"""
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
