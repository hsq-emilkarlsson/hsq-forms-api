"""
Simplified SQLAlchemy database models - Clean restart.
"""
from sqlalchemy import Column, String, Text, DateTime, Boolean, JSON, ForeignKey
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
    
    # Relationship to template
    template = relationship("FormTemplate", back_populates="submissions")

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
