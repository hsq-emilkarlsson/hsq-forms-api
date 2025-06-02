from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, JSON
from sqlalchemy.sql import func
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
    metadata = Column(JSON, nullable=True)
    ip_address = Column(String(45), nullable=True)  # Supports both IPv4 and IPv6
    user_agent = Column(Text, nullable=True)
    is_processed = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    def to_dict(self):
        """Konvertera modell till dictionary för API-respons"""
        return {
            "id": self.id,
            "form_type": self.form_type,
            "name": self.name,
            "email": self.email,
            "message": self.message,
            "metadata": self.metadata,
            "ip_address": self.ip_address,
            "user_agent": self.user_agent,
            "is_processed": self.is_processed,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
