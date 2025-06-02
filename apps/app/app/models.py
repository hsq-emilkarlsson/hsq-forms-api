from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, JSON, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .db import Base
import uuid

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
    attachments = relationship("FileAttachment", back_populates="submission", cascade="all, delete-orphan")

    def to_dict(self):
        """Konvertera modell till dictionary för API-respons"""
        return {
            "id": self.id,
            "form_type": self.form_type,
            "name": self.name,
            "email": self.email,
            "message": self.message,
            "metadata": self.form_metadata,  # Map back to metadata for API consistency
            "ip_address": self.ip_address,
            "user_agent": self.user_agent,
            "is_processed": self.is_processed,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "attachments": [attachment.to_dict() for attachment in self.attachments] if self.attachments else []
        }


class FileAttachment(Base):
    """
    SQLAlchemy modell för filbilagor kopplade till formulärinlämningar
    """
    __tablename__ = "file_attachments"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    submission_id = Column(String, ForeignKey("form_submissions.id"), nullable=False)
    original_filename = Column(String(255), nullable=False)
    stored_filename = Column(String(255), nullable=False)
    file_size = Column(Integer, nullable=False)
    content_type = Column(String(100), nullable=False)
    blob_url = Column(String(500), nullable=True)  # Azure Blob Storage URL
    upload_status = Column(String(20), default="uploaded", nullable=False)  # uploaded, processing, error
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationship back to submission
    submission = relationship("FormSubmission", back_populates="attachments")
    
    def to_dict(self):
        """Konvertera modell till dictionary för API-respons"""
        return {
            "id": self.id,
            "submission_id": self.submission_id,
            "original_filename": self.original_filename,
            "stored_filename": self.stored_filename,
            "file_size": self.file_size,
            "content_type": self.content_type,
            "blob_url": self.blob_url,
            "upload_status": self.upload_status,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }
