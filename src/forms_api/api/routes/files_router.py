"""
File upload router för HSQ Forms API
Hanterar säker filuppladdning till Azure Blob Storage eller lokal lagring
"""
import os
import io
import logging
from typing import List, Optional
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, status, Form
from fastapi.responses import JSONResponse, StreamingResponse
from sqlalchemy.orm import Session

from src.forms_api.db import get_db
from src.forms_api.models import FormSubmission, FileAttachment
from src.forms_api.schemas import FileUploadResponse, FileAttachmentResponse
from src.forms_api.services.storage import get_storage_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Files"])

@router.post("/upload/{submission_id}", response_model=FileUploadResponse)
async def upload_file(
    submission_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Ladda upp en fil kopplad till ett formulär
    """
    # Kontrollera att submission finns
    submission = db.query(FormSubmission).filter(
        FormSubmission.submission_id == submission_id
    ).first()
    
    if not submission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Ingen formulärdata med ID {submission_id} hittades"
        )
        
    try:
        # Hämta lämplig lagringstjänst
        storage_service, _ = get_storage_service()
        
        # Ladda upp filen
        file_id, file_size, content_type = await storage_service.upload_file(
            file, submission_id
        )
        
        # Skapa en post i databasen om filen
        file_attachment = FileAttachment(
            file_id=file_id,
            submission_id=submission_id,
            filename=file.filename,
            content_type=content_type,
            size=file_size
        )
        db.add(file_attachment)
        db.commit()
        
        return {
            "file_id": file_id,
            "submission_id": submission_id,
            "filename": file.filename,
            "size": file_size,
            "content_type": content_type,
            "status": "success"
        }
        
    except Exception as e:
        logger.error(f"Filuppladdning misslyckades: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Filuppladdning misslyckades: {str(e)}"
        )
