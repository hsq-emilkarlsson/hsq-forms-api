"""
Simplified Pydantic schemas for validation
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
