"""
Pydantic schemas for HSQ Forms API validation
"""
from pydantic import BaseModel, Field, ConfigDict
from typing import Dict, Any, Optional, List
from datetime import datetime


class FormFieldCreate(BaseModel):
    """Schema for creating a form field"""
    name: str = Field(..., description="Field name")
    type: str = Field(..., description="Field type: string, number, boolean, email, etc.")
    label: str = Field(..., description="Human readable label")
    required: bool = Field(default=False, description="Is this field required")
    placeholder: Optional[str] = Field(None, description="Placeholder text")
    options: Optional[List[str]] = Field(None, description="Options for select/radio fields")


class FormTemplateCreate(BaseModel):
    """Schema for creating a form template"""
    name: str = Field(..., description="Template name")
    description: Optional[str] = Field(None, description="Template description")
    project_id: str = Field(..., description="Project ID")
    fields: List[FormFieldCreate] = Field(..., description="Form fields")


class FormTemplateResponse(BaseModel):
    """Schema for form template response"""
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    name: str
    description: Optional[str]
    project_id: str
    schema: Dict[str, Any]
    is_active: bool
    created_at: datetime


class FormSubmissionCreate(BaseModel):
    """Schema for creating a form submission"""
    data: Dict[str, Any] = Field(..., description="Form data")
    submitted_from: Optional[str] = Field(None, description="App/site that submitted this")


class FormSubmissionResponse(BaseModel):
    """Schema for form submission response"""
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    template_id: str
    data: Dict[str, Any]
    submitted_from: Optional[str]
    ip_address: Optional[str]
    created_at: datetime


# File attachment schemas
class FileAttachmentResponse(BaseModel):
    """Schema for file attachment response"""
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    submission_id: str
    field_name: str
    original_filename: str
    stored_filename: str
    file_size: int
    content_type: str
    blob_url: Optional[str]
    upload_status: str
    form_type: str
    storage_path: str
    created_at: datetime


class FileUploadResponse(BaseModel):
    """Schema for file upload response"""
    success: bool = Field(..., description="Upload success")
    attachment_id: str = Field(..., description="Attachment ID")
    filename: str = Field(..., description="Original filename")
    file_size: int = Field(..., description="File size in bytes")
    content_type: str = Field(..., description="MIME content type")
    storage_path: str = Field(..., description="Storage path with folder structure")
    message: str = Field(..., description="Success message")


class FormSubmissionWithFilesCreate(BaseModel):
    """Schema for form submission with file attachments"""
    data: Dict[str, Any] = Field(..., description="Form data")
    submitted_from: Optional[str] = Field(None, description="App/site that submitted this")
    form_type: str = Field(..., description="Type of form (b2b-feedback, b2b-support, etc.)")


class FormSubmissionWithFilesResponse(BaseModel):
    """Schema for form submission response with attachments"""
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    template_id: str
    data: Dict[str, Any]
    submitted_from: Optional[str]
    ip_address: Optional[str]
    created_at: datetime
    attachments: List[FileAttachmentResponse] = Field(default_factory=list)


# ESB Integration schemas
class CustomerValidationRequest(BaseModel):
    """Schema for customer validation request"""
    customer_number: str = Field(..., description="Customer number to validate")
    customer_code: str = Field(default="DOJ", description="Customer code")


class CustomerValidationResponse(BaseModel):
    """Schema for customer validation response"""
    is_valid: bool = Field(..., description="Whether customer is valid")
    account_id: Optional[str] = Field(None, description="Account ID if valid")
    message: str = Field(..., description="Validation result message")


class B2BSupportSubmissionRequest(BaseModel):
    """Schema for B2B support form submission with ESB integration"""
    customer_number: str = Field(..., description="Customer number")
    customer_code: str = Field(default="DOJ", description="Customer code")
    description: str = Field(..., description="Problem description")
    # Additional form data
    company_name: Optional[str] = Field(None, description="Company name")
    contact_person: Optional[str] = Field(None, description="Contact person")
    email: Optional[str] = Field(None, description="Email address")
    phone: Optional[str] = Field(None, description="Phone number")
    support_type: Optional[str] = Field(None, description="Support type")
    subject: Optional[str] = Field(None, description="Subject")
    urgency: Optional[str] = Field(None, description="Urgency level")


class B2BSupportSubmissionResponse(BaseModel):
    """Schema for B2B support form submission response"""
    success: bool = Field(..., description="Whether submission was successful")
    submission_id: str = Field(..., description="Form submission ID")
    case_id: Optional[str] = Field(None, description="ESB case ID if created")
    account_id: Optional[str] = Field(None, description="Customer account ID")
    message: str = Field(..., description="Success or error message")
