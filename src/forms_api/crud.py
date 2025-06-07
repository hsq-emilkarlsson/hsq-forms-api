from sqlalchemy.orm import Session
from sqlalchemy import desc
from . import models, schemas
from .db import get_db
from fastapi import HTTPException, status, Depends
from typing import List, Optional
import uuid

def create_submission(
    db: Session,
    submission_data: schemas.FormSubmissionCreate, 
    ip_address: Optional[str] = None, 
    user_agent: Optional[str] = None
) -> models.FormSubmission:
    """
    Skapa en ny formulärinlämning i PostgreSQL-databasen
    """
    try:
        # Skapa ny FormSubmission-instans
        db_submission = models.FormSubmission(
            id=str(uuid.uuid4()),
            name=submission_data.name,
            email=submission_data.email,
            message=submission_data.message,
            form_type=submission_data.form_type,
            form_metadata=submission_data.metadata,  # Map to form_metadata column
            ip_address=ip_address,
            user_agent=user_agent
        )
        
        # Lägg till i databassessionen
        db.add(db_submission)
        db.commit()
        db.refresh(db_submission)
        
        return db_submission
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Databasfel: {str(e)}"
        )

def get_submission(db: Session, submission_id: str) -> Optional[models.FormSubmission]:
    """
    Hämta ett specifikt formulär från databasen
    """
    submission = db.query(models.FormSubmission).filter(
        models.FormSubmission.id == submission_id
    ).first()
    
    if not submission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Formulärinlämningen hittades inte"
        )
    return submission

def get_submissions(
    db: Session, 
    form_type: Optional[str] = None, 
    limit: int = 50, 
    skip: int = 0
) -> List[models.FormSubmission]:
    """
    Hämta alla formulär, eventuellt filtrerade per typ
    """
    query = db.query(models.FormSubmission)
    
    if form_type:
        query = query.filter(models.FormSubmission.form_type == form_type)
    
    return query.order_by(desc(models.FormSubmission.created_at)).offset(skip).limit(limit).all()

def update_submission_status(
    db: Session, 
    submission_id: str, 
    is_processed: bool
) -> models.FormSubmission:
    """
    Uppdatera bearbetningsstatus för en formulärinlämning
    """
    submission = get_submission(db, submission_id)
    submission.is_processed = is_processed
    
    try:
        db.commit()
        db.refresh(submission)
        return submission
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Kunde inte uppdatera status: {str(e)}"
        )

def delete_submission(db: Session, submission_id: str) -> bool:
    """
    Ta bort en formulärinlämning
    """
    submission = get_submission(db, submission_id)
    
    try:
        db.delete(submission)
        db.commit()
        return True
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Kunde inte ta bort formulärinlämning: {str(e)}"
        )