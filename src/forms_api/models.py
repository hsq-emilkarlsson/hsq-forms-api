"""
SQLAlchemy database models.
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, JSON, ForeignKey, Table
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid

from src.forms_api.db import Base

# Constants
CASCADE_DELETE = "all, delete-orphan"

class FormSubmission(Base):
    """
    SQLAlchemy modell för formulärinlämningar i PostgreSQL
    """
    __tablename__ = "form_submissions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    form_type = Column(String(50), nullable=False, default="contact")
    name = Column(String(100), nullable=False)
    email = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    form_metadata = Column(JSON, nullable=True)  # Changed from metadata to form_metadata
    ip_address = Column(String(45), nullable=True)  # Supports both IPv4 and IPv6
    user_agent = Column(Text, nullable=True)
    is_processed = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationship to file attachments
    attachments = relationship("FileAttachment", back_populates="submission", cascade=CASCADE_DELETE)

    def to_dict(self):
        """Convert model to dictionary"""
        return {
            "submission_id": self.id,
            "form_type": self.form_type,
            "name": self.name,
            "email": self.email,
            "message": self.message,
            "metadata": self.form_metadata,
            "is_processed": self.is_processed,
            "submitted_at": self.created_at.isoformat() if self.created_at else None,
        }


class FileAttachment(Base):
    """
    SQLAlchemy modell för filbilagor kopplade till formulärinlämningar
    """
    __tablename__ = "file_attachments"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    submission_id = Column(String, ForeignKey("form_submissions.id"))
    filename = Column(String(255), nullable=False)
    original_filename = Column(String(255), nullable=False)
    content_type = Column(String(100), nullable=False)
    file_size = Column(Integer, nullable=False)  # Size in bytes
    storage_path = Column(String(255), nullable=True)  # Only for local storage
    storage_provider = Column(String(50), default="local", nullable=False)  # local or azure
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationship to submission
    submission = relationship("FormSubmission", back_populates="attachments")

    def to_dict(self):
        """Convert model to dictionary"""
        return {
            "file_id": self.id,
            "submission_id": self.submission_id,
            "filename": self.original_filename,
            "content_type": self.content_type,
            "file_size": self.file_size,
            "uploaded_at": self.created_at.isoformat() if self.created_at else None,
        }


# Models for flexible forms

class FormTemplate(Base):
    """
    SQLAlchemy modell för flexibla formulärmallar
    """
    __tablename__ = "form_templates"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    title = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    project_id = Column(String(100), nullable=False, index=True)
    schema = Column(JSON, nullable=False)  # JSON schema for the form
    settings = Column(JSON, nullable=False, default=lambda: {})  # Form settings
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Language support
    default_language = Column(String(5), nullable=False, default="en")  # Default language code (e.g., en, sv)
    available_languages = Column(JSON, nullable=False, default=lambda: ["en"])  # List of available language codes
    translations = Column(JSON, nullable=False, default=lambda: {})  # Translations for all text content by language
    
    # Relationship to submissions
    submissions = relationship("FlexibleFormSubmission", back_populates="template", cascade=CASCADE_DELETE)

    def to_dict(self):
        """Convert model to dictionary"""
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "project_id": self.project_id,
            "schema": self.schema,
            "settings": self.settings,
            "is_active": self.is_active,
            "default_language": self.default_language,
            "available_languages": self.available_languages,
            "translations": self.translations,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class FlexibleFormSubmission(Base):
    """
    SQLAlchemy modell för flexibla formulärinlämningar
    """
    __tablename__ = "flex_form_submissions"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    template_id = Column(String, ForeignKey("form_templates.id"))
    data = Column(JSON, nullable=False)  # Form data
    form_metadata = Column(JSON, nullable=True)  # Changed from metadata to form_metadata
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    is_processed = Column(Boolean, default=False, nullable=False)
    processing_result = Column(JSON, nullable=True)  # Result of any automated processing
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationship to template
    template = relationship("FormTemplate", back_populates="submissions")
    
    # Relationship to file attachments
    attachments = relationship("FlexibleFormAttachment", back_populates="submission", cascade=CASCADE_DELETE)

    def to_dict(self):
        """Convert model to dictionary"""
        return {
            "submission_id": self.id,
            "template_id": self.template_id,
            "data": self.data,
            "metadata": self.form_metadata,
            "is_processed": self.is_processed,
            "processing_result": self.processing_result,
            "submitted_at": self.created_at.isoformat() if self.created_at else None,
        }


class FlexibleFormAttachment(Base):
    """
    SQLAlchemy modell för filbilagor kopplade till flexibla formulärinlämningar
    """
    __tablename__ = "flex_form_file_attachments"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    submission_id = Column(String, ForeignKey("flex_form_submissions.id"))
    field_name = Column(String(100), nullable=False)  # The form field this attachment belongs to
    filename = Column(String(255), nullable=False)
    original_filename = Column(String(255), nullable=False)
    content_type = Column(String(100), nullable=False)
    file_size = Column(Integer, nullable=False)
    storage_path = Column(String(255), nullable=True)
    storage_provider = Column(String(50), default="local", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationship to submission
    submission = relationship("FlexibleFormSubmission", back_populates="attachments")

    def to_dict(self):
        """Convert model to dictionary"""
        return {
            "file_id": self.id,
            "submission_id": self.submission_id,
            "field_name": self.field_name,
            "filename": self.original_filename,
            "content_type": self.content_type,
            "file_size": self.file_size,
            "uploaded_at": self.created_at.isoformat() if self.created_at else None,
        }
