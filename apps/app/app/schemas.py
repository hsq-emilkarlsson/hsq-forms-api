from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Dict, Any, Optional, Literal
from datetime import datetime

# Definiera tillåtna formulärtyper
FormType = Literal["contact", "newsletter", "job_application", "support_ticket"]

class FormSubmissionBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="Namn på avsändaren")
    email: EmailStr = Field(..., description="E-postadress för kontakt")
    message: str = Field(..., min_length=10, description="Meddelandetext")

class FormSubmissionCreate(FormSubmissionBase):
    form_type: FormType = Field(default="contact", description="Typ av formulär")
    metadata: Optional[Dict[str, Any]] = Field(default=None, description="Valfri metadata för formuläret")

class FormSubmissionResponse(FormSubmissionBase):
    model_config = ConfigDict(
        from_attributes=True,
        json_schema_extra={
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "name": "Anna Andersson",
                "email": "anna@example.com",
                "message": "Hej, jag har en fråga om produkten...",
                "form_type": "contact",
                "created_at": "2023-05-30T14:30:00Z",
                "updated_at": "2023-05-30T14:30:00Z",
                "is_processed": False,
                "ip_address": "192.168.1.1",
                "user_agent": "Mozilla/5.0...",
                "metadata": {"source": "website"}
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