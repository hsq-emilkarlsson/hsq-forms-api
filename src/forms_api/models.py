"""
SQLAlchemy database models for HSQ Forms API
"""
from sqlalchemy import Column, String, Text, DateTime, Boolean, JSON, ForeignKey, Integer
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid

from src.forms_api.db import Base


class FormTemplate(Base):
    """
    Simple form template model
    """
    __tablename__ = "form_templates"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    project_id = Column(String(100), nullable=False)
    schema = Column(JSON, nullable=False)  # JSON schema for the form
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationship to submissions
    submissions = relationship("FormSubmission", back_populates="template", cascade="all, delete-orphan")

    def to_dict(self):
        """Convert model to dictionary"""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "project_id": self.project_id,
            "schema": self.schema,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class FormSubmission(Base):
    """
    Simple form submission model
    """
    __tablename__ = "form_submissions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    template_id = Column(String, ForeignKey("form_templates.id"), nullable=False)
    data = Column(JSON, nullable=False)  # Form data
    submitted_from = Column(String(255), nullable=True)  # Which app/site submitted this
    ip_address = Column(String(45), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationship to template and attachments
    template = relationship("FormTemplate", back_populates="submissions")
    attachments = relationship("FlexibleFormAttachment", back_populates="submission", cascade="all, delete-orphan")

    def to_dict(self):
        """Convert model to dictionary"""
        return {
            "id": self.id,
            "template_id": self.template_id,
            "data": self.data,
            "submitted_from": self.submitted_from,
            "ip_address": self.ip_address,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


class FlexibleFormAttachment(Base):
    """
    File attachment model for form submissions
    Organiserar filer per formulärtyp i Azure Blob Storage
    """
    __tablename__ = "flexible_form_attachments"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    submission_id = Column(String, ForeignKey("form_submissions.id"), nullable=False)
    field_name = Column(String(100), nullable=False)  # Namnet på fältet i formuläret
    original_filename = Column(String(255), nullable=False)  # Originalfilens namn
    stored_filename = Column(String(255), nullable=False)  # Säkert filnamn i storage
    file_size = Column(Integer, nullable=False)  # Filstorlek i bytes
    content_type = Column(String(100), nullable=False)  # MIME type
    blob_url = Column(String(500), nullable=True)  # URL till Azure blob (om Azure storage)
    upload_status = Column(String(20), nullable=False, default="pending")  # pending, uploaded, failed
    form_type = Column(String(50), nullable=False)  # b2b-feedback, b2b-support, etc.
    storage_path = Column(String(500), nullable=False)  # Full sökväg i storage (inkl. mapp)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationship to submission
    submission = relationship("FormSubmission", back_populates="attachments")
    
    def to_dict(self):
        """Convert model to dictionary"""
        return {
            "id": self.id,
            "submission_id": self.submission_id,
            "field_name": self.field_name,
            "original_filename": self.original_filename,
            "stored_filename": self.stored_filename,
            "file_size": self.file_size,
            "content_type": self.content_type,
            "blob_url": self.blob_url,
            "upload_status": self.upload_status,
            "form_type": self.form_type,
            "storage_path": self.storage_path,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

