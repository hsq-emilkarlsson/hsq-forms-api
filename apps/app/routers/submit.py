from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session
from app import schemas, crud
from app.db import get_db
from typing import List, Optional
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/submit", status_code=status.HTTP_201_CREATED)
def submit_form(
    data: schemas.FormSubmissionCreate, 
    request: Request,
    db: Session = Depends(get_db)
):
    """Skicka in formulärdata"""
    try:
        # Hämta IP-adress och user agent från request
        ip_address = request.client.host if request.client else None
        user_agent = request.headers.get("user-agent")
        
        logger.info(f"Formulär mottaget: {data.form_type} från {data.email}")
        
        # Skapa formulärinlämning
        submission = crud.create_submission(
            db=db, 
            submission_data=data, 
            ip_address=ip_address, 
            user_agent=user_agent
        )
        
        return {
            "status": "success",
            "message": "Formuläret har sparats!",
            "submission_id": submission.id
        }
    except Exception as e:
        logger.error(f"Fel vid sparande av formulär: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ett fel uppstod vid sparande av formuläret"
        )

@router.get("/submissions")
def get_submissions(
    form_type: Optional[str] = None,
    limit: int = 50,
    skip: int = 0,
    db: Session = Depends(get_db)
):
    """Hämta alla formulärinlämningar"""
    try:
        submissions = crud.get_submissions(
            db=db, 
            form_type=form_type, 
            limit=limit, 
            skip=skip
        )
        
        # Convert SQLAlchemy objects to dictionaries and map form_metadata to metadata
        result = []
        for submission in submissions:
            submission_dict = {
                "id": submission.id,
                "form_type": submission.form_type,
                "name": submission.name,
                "email": submission.email,
                "message": submission.message,
                "metadata": submission.form_metadata,  # Map form_metadata to metadata
                "ip_address": submission.ip_address,
                "user_agent": submission.user_agent,
                "is_processed": submission.is_processed,
                "created_at": submission.created_at,
                "updated_at": submission.updated_at
            }
            result.append(submission_dict)
        
        return result
    except Exception as e:
        logger.error(f"Fel vid hämtning av formulär: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ett fel uppstod vid hämtning av formulär"
        )

@router.get("/submission/{submission_id}")
def get_submission(submission_id: str, db: Session = Depends(get_db)):
    """Hämta en specifik formulärinlämning"""
    try:
        submission = crud.get_submission(db=db, submission_id=submission_id)
        
        # Convert SQLAlchemy object to dictionary and map form_metadata to metadata
        submission_dict = {
            "id": submission.id,
            "form_type": submission.form_type,
            "name": submission.name,
            "email": submission.email,
            "message": submission.message,
            "metadata": submission.form_metadata,  # Map form_metadata to metadata
            "ip_address": submission.ip_address,
            "user_agent": submission.user_agent,
            "is_processed": submission.is_processed,
            "created_at": submission.created_at,
            "updated_at": submission.updated_at
        }
        
        return submission_dict
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Fel vid hämtning av formulär {submission_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ett fel uppstod vid hämtning av formuläret"
        )

@router.patch("/submission/{submission_id}/status")
def update_submission_status(
    submission_id: str, 
    is_processed: bool,
    db: Session = Depends(get_db)
):
    """Uppdatera bearbetningsstatus för en formulärinlämning"""
    try:
        submission = crud.update_submission_status(
            db=db, 
            submission_id=submission_id, 
            is_processed=is_processed
        )
        return {
            "status": "success",
            "message": "Status uppdaterad",
            "submission_id": submission.id,
            "is_processed": submission.is_processed
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Fel vid uppdatering av status för {submission_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ett fel uppstod vid uppdatering av status"
        )

@router.get("/debug/submissions")
def debug_submissions(db: Session = Depends(get_db)):
    """Debug endpoint to check raw database data"""
    try:
        submissions = crud.get_submissions(db=db, limit=1)
        if not submissions:
            return {"message": "No submissions found"}
        
        submission = submissions[0]
        
        # Debug what's in form_metadata
        metadata_value = submission.form_metadata
        
        return {
            "raw_submission": str(submission.__dict__),
            "form_metadata": metadata_value,
            "form_metadata_type": str(type(metadata_value)),
            "is_none": metadata_value is None,
            "actual_value": str(metadata_value),
            "repr_value": repr(metadata_value)
        }
    except Exception as e:
        return {"error": str(e), "type": str(type(e))}