from fastapi import APIRouter, Request, status, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
from src.forms_api import schemas, crud, models
from src.forms_api.db import get_db
import logging

# Konfigurera loggning
logger = logging.getLogger(__name__)

router = APIRouter()

@router.post("/submit", response_model=dict, status_code=status.HTTP_201_CREATED)
async def submit_form(
    data: schemas.FormSubmissionCreate, 
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Spara formulärdata i PostgreSQL.
    
    - Validerar formulärdata med Pydantic
    - Sparar i PostgreSQL-databas
    - Returnerar ett bekräftelsemeddelande
    """
    try:
        # Hämta klient-info
        ip_address = request.client.host if request.client else None
        user_agent = request.headers.get("user-agent")
        
        # Skapa inlämning i databasen
        submission = crud.create_submission(db, data, ip_address, user_agent)
        
        logger.info(f"Formulär mottaget: {data.form_type} från {data.email}")
        
        return {
            "status": "success", 
            "message": "Formuläret har sparats!",
            "submission_id": submission.id
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Fel vid formulärhantering: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ett fel uppstod vid hantering av formuläret"
        )

@router.get("/submissions")
async def get_submissions(
    form_type: Optional[str] = None, 
    limit: int = 50, 
    skip: int = 0,
    db: Session = Depends(get_db)
):
    """
    Hämta formulär från PostgreSQL.
    Kan filtreras per formulärtyp.
    """
    try:
        submissions = crud.get_submissions(db, form_type, limit, skip)
        
        # Convert to dictionaries manually to avoid Pydantic validation issues
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
async def get_submission(
    submission_id: str,
    db: Session = Depends(get_db)
):
    """
    Hämta ett specifikt formulär från PostgreSQL.
    """
    submission = crud.get_submission(db, submission_id)
    
    # Convert to dictionary manually to avoid Pydantic validation issues
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

@router.put("/submission/{submission_id}/status")
async def update_submission_status(
    submission_id: str,
    is_processed: bool,
    db: Session = Depends(get_db)
):
    """
    Uppdatera bearbetningsstatus för en formulärinlämning.
    """
    try:
        submission = crud.update_submission_status(db, submission_id, is_processed)
        return {
            "status": "success",
            "message": "Status uppdaterad",
            "submission_id": submission.id,
            "is_processed": submission.is_processed
        }
    except Exception as e:
        logger.error(f"Fel vid uppdatering av status: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Ett fel uppstod vid uppdatering av status"
        )