"""
Pydantic schema models for HSQ Forms API
"""
from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Dict, Any, Optional, Literal, List
from datetime import datetime

# Define allowed form types
FormType = Literal["contact", "newsletter", "job_application", "support_ticket"]

class FileAttachmentResponse(BaseModel):
    """Schema for file attachments in API response"""
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    submission_id: str
    original_filename: str
    stored_filename: str
    file_size: int
    content_type: str
    blob_url: Optional[str] = None
    upload_status: str
    created_at: datetime

class FormSubmissionBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="Sender name")
    email: EmailStr = Field(..., description="Contact email address")
    message: str = Field(..., min_length=10, description="Message text")

class FormSubmissionCreate(FormSubmissionBase):
    form_type: FormType = Field(default="contact", description="Form type")
    metadata: Optional[Dict[str, Any]] = Field(default=None, description="Optional form metadata")

class FormSubmissionResponse(FormSubmissionBase):
    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "name": "Anna Andersson",
                "email": "anna@example.com",
                "message": "Hello, I have a question about your product...",
                "form_type": "contact",
                "created_at": "2023-05-30T14:30:00Z",
                "updated_at": "2023-05-30T14:30:00Z",
                "is_processed": False,
                "ip_address": "192.168.1.1",
                "user_agent": "Mozilla/5.0...",
                "metadata": {"source": "website"},
                "attachments": []
            }
        }
    )
    
    id: str
    form_type: str
    created_at: datetime
    updated_at: datetime
    is_processed: bool = False
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    attachments: List[FileAttachmentResponse] = Field(default_factory=list, description="Attached files")

class FileUploadResponse(BaseModel):
    """Response for file upload"""
    success: bool
    message: str
    file_id: Optional[str] = None
    original_filename: Optional[str] = None
    file_size: Optional[int] = None

# Schemas for flexible forms
class FormFieldCreate(BaseModel):
    """Schema for creating form fields"""
    name: str = Field(..., min_length=1, max_length=50, description="Field name")
    label: str = Field(..., min_length=1, max_length=100, description="Field label")
    type: Literal["string", "number", "integer", "boolean", "array", "object", "file"] = Field(..., description="Field type")
    description: Optional[str] = Field(None, max_length=500, description="Field description")
    required: bool = Field(False, description="If the field is required")
    placeholder: Optional[str] = Field(None, max_length=100, description="Placeholder text")
    
    # Type-specific properties
    min_length: Optional[int] = Field(None, ge=0, description="Minimum length for string")
    max_length: Optional[int] = Field(None, ge=1, description="Maximum length for string")
    pattern: Optional[str] = Field(None, description="Regex pattern for validation")
    format: Optional[Literal["email", "date", "datetime", "url", "phone"]] = Field(None, description="Format for string")
    
    minimum: Optional[float] = Field(None, description="Minimum value for number/integer")
    maximum: Optional[float] = Field(None, description="Maximum value for number/integer")
    
    enum: Optional[List[str]] = Field(None, description="Allowed values (dropdown)")
    multiple: Optional[bool] = Field(False, description="Allow multiple selections for array/file")
    
    # File-specific
    accepted_types: Optional[List[str]] = Field(None, description="Allowed file types for file fields")
    max_file_size: Optional[int] = Field(None, ge=1, description="Maximum file size in bytes")

class FormTemplateCreate(BaseModel):
    """Schema for creating form templates"""
    name: str = Field(..., min_length=1, max_length=100, description="Form name")
    description: Optional[str] = Field(None, max_length=500, description="Form description")
    project_id: str = Field(default="default", max_length=50, description="Project ID")
    fields: List[FormFieldCreate] = Field(..., min_items=1, description="Form fields")
    created_by: Optional[str] = Field(None, max_length=100, description="Creator")
    default_language: str = Field(default="en", min_length=2, max_length=5, description="Default language code (e.g., en, sv)")
    available_languages: List[str] = Field(default=["en"], description="List of available language codes")
    translations: Dict[str, Dict[str, Any]] = Field(default_factory=dict, description="Translations for form content by language")

class FormTemplateResponse(BaseModel):
    """Schema for form template in response"""
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    name: str
    description: Optional[str]
    project_id: str
    form_schema: Dict[str, Any] = Field(alias="schema")
    validation_rules: Optional[Dict[str, Any]]
    is_active: bool
    created_by: Optional[str]
    default_language: str = "en"
    available_languages: List[str] = ["en"]
    translations: Dict[str, Dict[str, Any]] = Field(default_factory=dict)
    created_at: datetime
    updated_at: datetime

class FlexibleFormSubmissionCreate(BaseModel):
    """Schema for flexible form submission"""
    template_id: str = Field(..., description="Template ID")
    data: Dict[str, Any] = Field(..., description="Form data according to template schema")
    submitted_by: Optional[str] = Field(None, max_length=100, description="Submitter")
    submitted_from_project: Optional[str] = Field(None, max_length=50, description="Project that submitted")

class FlexibleFormSubmissionResponse(BaseModel):
    """Schema for flexible form submission in response"""
    model_config = ConfigDict(from_attributes=True)
    
    id: str
    template_id: str
    data: Dict[str, Any]
    submitted_by: Optional[str]
    submitted_from_ip: Optional[str]
    submitted_from_project: Optional[str]
    user_agent: Optional[str]
    is_processed: bool
    processing_notes: Optional[str]
    created_at: datetime
    updated_at: datetime
    template: Optional[FormTemplateResponse]
    attachments: List[FileAttachmentResponse] = []
