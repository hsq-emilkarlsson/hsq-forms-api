"""
File upload router för HSQ Forms API
Hanterar säker filuppladdning till Azure Blob Storage eller lokal lagring
"""
import os
import    except Exception as e:
        logger.error(f"Oväntat fel vid temporär filuppladdning: {str(e)}")
        
        # Rensa upp eventuella framgångsrika uppladdningar vid fel
        for file_attachment in successful_uploads:
            try:
                await storage_service.delete_file(file_attachment.stored_filename, temp_submission_id)
                db.delete(file_attachment)
            except Exception as cleanup_error:
                logger.error(f"Fel vid upprensning: {str(cleanup_error)}") logging
from typing import List, Optional
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, status, Form
from fastapi.responses import JSONResponse, StreamingResponse
from sqlalchemy.orm import Session
from ..db import get_db
from ..models import FormSubmission, FileAttachment
from ..schemas import FileUploadResponse, FileAttachmentResponse

# Importera rätt storage service baserat på miljö
try:
    from ..blob_storage import blob_storage_service
    use_azure = True
except Exception as e:
    logging.warning(f"Azure Blob Storage not available: {e}")
    use_azure = False

if not use_azure or os.getenv("ENVIRONMENT", "development") == "development":
    from ..local_storage import local_storage_service
    storage_service = local_storage_service
    use_azure = False
else:
    storage_service = blob_storage_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/files", tags=["files"])

@router.post("/upload/{submission_id}", response_model=List[FileUploadResponse])
async def upload_files(
    submission_id: str,
    files: List[UploadFile] = File(..., description="Filer att ladda upp (max 5 filer)"),
    db: Session = Depends(get_db)
):
    """
    Ladda upp filer till en befintlig formulärinlämning
    
    - **submission_id**: ID för formulärinlämningen som filerna ska kopplas till
    - **files**: Lista med filer att ladda upp (max 5 filer, 10MB vardera)
    
    Säkerhetsfunktioner:
    - Filtypsvalidering
    - Storleksbegränsning
    - Virusscanning via innehållsanalys
    - Säker filnamnshantering
    """
    
    # Kontrollera att formulärinlämningen finns
    submission = db.query(FormSubmission).filter(FormSubmission.id == submission_id).first()
    if not submission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Formulärinlämning med ID {submission_id} hittades inte"
        )
    
    # Begränsa antal filer
    if len(files) > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximalt 5 filer tillåtna per uppladdning"
        )
    
    # Kontrollera att inga filer är tomma
    if not files or all(file.filename == "" for file in files):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inga filer valda för uppladdning"
        )
    
    upload_results = []
    successful_uploads = []
    
    try:
        for file in files:
            if not file.filename:
                upload_results.append(FileUploadResponse(
                    success=False,
                    message="Filnamn saknas",
                    original_filename=None
                ))
                continue
            
            # Ladda upp fil med vald storage service
            try:
                file_id, file_size, content_type = await storage_service.upload_file(file, submission_id)
                
                # Spara filinformation i databasen
                file_attachment = FileAttachment(
                    submission_id=submission_id,
                    original_filename=file.filename,
                    stored_filename=file_id,  # För lokal lagring används file_id som stored_filename
                    file_size=file_size,
                    content_type=content_type,
                    blob_url=f"/files/{file_id}" if not use_azure else f"https://{storage_service.account_name}.blob.core.windows.net/{storage_service.container_name}/{file_id}",
                    upload_status="uploaded"
                )
                
                db.add(file_attachment)
                db.commit()
                db.refresh(file_attachment)
                
                successful_uploads.append(file_attachment)
                
                upload_results.append(FileUploadResponse(
                    success=True,
                    message=f"Fil {file.filename} uppladdad framgångsrikt",
                    file_id=file_attachment.id,
                    original_filename=file.filename,
                    file_size=file_attachment.file_size
                ))
                
                logger.info(f"Fil {file.filename} uppladdad för submission {submission_id}")
                
            except HTTPException as http_error:
                upload_results.append(FileUploadResponse(
                    success=False,
                    message=str(http_error.detail),
                    original_filename=file.filename
                ))
                continue
            except Exception as upload_error:
                logger.error(f"Uppladdningsfel för {file.filename}: {str(upload_error)}")
                upload_results.append(FileUploadResponse(
                    success=False,
                    message=f"Uppladdningsfel för fil {file.filename}",
                    original_filename=file.filename
                ))
                continue
                
    except Exception as e:
        logger.error(f"Oväntat fel vid filuppladdning: {str(e)}")
        
        # Rensa upp eventuella framgångsrika uppladdningar vid fel
        for file_attachment in successful_uploads:
            try:
                await storage_service.delete_file(file_attachment.stored_filename, submission_id)
                db.delete(file_attachment)
            except Exception:
                pass
        
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Oväntat fel vid filuppladdning"
        )
    
    return upload_results


@router.get("/submission/{submission_id}", response_model=List[FileAttachmentResponse])
async def get_submission_files(
    submission_id: str,
    db: Session = Depends(get_db)
):
    """
    Hämta alla filer kopplade till en formulärinlämning
    """
    
    # Kontrollera att formulärinlämningen finns
    submission = db.query(FormSubmission).filter(FormSubmission.id == submission_id).first()
    if not submission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Formulärinlämning med ID {submission_id} hittades inte"
        )
    
    # Hämta alla filer för denna submission
    files = db.query(FileAttachment).filter(FileAttachment.submission_id == submission_id).all()
    
    return [FileAttachmentResponse.model_validate(file) for file in files]


@router.delete("/{file_id}")
async def delete_file(
    file_id: str,
    db: Session = Depends(get_db)
):
    """
    Ta bort en fil
    
    - **file_id**: ID för filen som ska tas bort
    """
    
    # Hitta filen i databasen
    file_attachment = db.query(FileAttachment).filter(FileAttachment.id == file_id).first()
    if not file_attachment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Fil med ID {file_id} hittades inte"
        )
    
    try:
        # Ta bort fil med storage service
        if use_azure:
            success, error_msg = await storage_service.delete_file(file_attachment.stored_filename)
            if not success and "not found" not in error_msg.lower():
                logger.warning(f"Kunde inte ta bort fil från storage: {error_msg}")
        else:
            success = await storage_service.delete_file(file_attachment.stored_filename, file_attachment.submission_id)
        
        # Ta bort från databasen
        db.delete(file_attachment)
        db.commit()
        
        logger.info(f"Fil {file_attachment.original_filename} borttagen")
        
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={"message": f"Fil {file_attachment.original_filename} har tagits bort"}
        )
        
    except Exception as e:
        db.rollback()
        logger.error(f"Fel vid borttagning av fil: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Fel vid borttagning av fil"
        )


@router.get("/{file_id}/info", response_model=FileAttachmentResponse)
async def get_file_info(
    file_id: str,
    db: Session = Depends(get_db)
):
    """
    Hämta information om en specifik fil
    """
    
    file_attachment = db.query(FileAttachment).filter(FileAttachment.id == file_id).first()
    if not file_attachment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Fil med ID {file_id} hittades inte"
        )
    
    return FileAttachmentResponse.model_validate(file_attachment)


@router.get("/{file_id}")
async def download_file(
    file_id: str,
    db: Session = Depends(get_db)
):
    """
    Ladda ner en fil
    
    - **file_id**: ID för filen som ska laddas ner
    """
    
    # Hitta filen i databasen
    file_attachment = db.query(FileAttachment).filter(FileAttachment.id == file_id).first()
    if not file_attachment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Fil med ID {file_id} hittades inte"
        )
    
    try:
        # Hämta fil från storage service
        if use_azure:
            # För Azure Blob Storage
            file_content, content_type, _ = await storage_service.get_file(file_attachment.stored_filename)
        else:
            # För lokal lagring
            result = await storage_service.get_file(file_attachment.stored_filename, file_attachment.submission_id)
            if result is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Fil kunde inte hittas i lagringen"
                )
            file_content, content_type, _ = result
        
        if file_content is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Fil kunde inte hittas i lagringen"
            )
        
        # Returnera filen som streaming response
        return StreamingResponse(
            io.BytesIO(file_content),
            media_type=content_type,
            headers={"Content-Disposition": f"attachment; filename={file_attachment.original_filename}"}
        )
        
    except Exception as e:
        logger.error(f"Fel vid nedladdning av fil {file_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Fel vid nedladdning av fil"
        )


@router.post("/upload/temp", response_model=List[FileUploadResponse])
async def upload_temporary_files(
    files: List[UploadFile] = File(..., description="Filer att ladda upp temporärt (max 5 filer)"),
    db: Session = Depends(get_db)
):
    """
    Ladda upp temporära filer innan formulärinlämning
    
    - **files**: Lista med filer att ladda upp (max 5 filer, 10MB vardera)
    
    Säkerhetsfunktioner:
    - Filtypsvalidering
    - Storleksbegränsning
    - Virusscanning via innehållsanalys
    - Säker filnamnshantering
    
    Temporära filer sparas utan koppling till en submission_id och kan senare kopplas till en submission.
    """
    
    # Begränsa antal filer
    if len(files) > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximalt 5 filer tillåtna per uppladdning"
        )
    
    # Kontrollera att inga filer är tomma
    if not files or all(file.filename == "" for file in files):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inga filer valda för uppladdning"
        )
    
    # Använd "temp" som submission_id för temporära filer
    temp_submission_id = "temp"
    
    upload_results = []
    successful_uploads = []
    
    try:
        for file in files:
            if not file.filename:
                upload_results.append(FileUploadResponse(
                    success=False,
                    message="Filnamn saknas",
                    original_filename=None
                ))
                continue
            
            # Ladda upp fil med vald storage service
            try:
                file_id, file_size, content_type = await storage_service.upload_file(file, temp_submission_id)
                
                # Spara filinformation i databasen som temporär fil
                file_attachment = FileAttachment(
                    submission_id=None,  # Ingen koppling till submission ännu
                    original_filename=file.filename,
                    stored_filename=file_id,
                    file_size=file_size,
                    content_type=content_type,
                    blob_url=f"/files/{file_id}" if not use_azure else f"https://{storage_service.account_name}.blob.core.windows.net/{storage_service.container_name}/{file_id}",
                    upload_status="temporary"
                )
                
                db.add(file_attachment)
                db.commit()
                db.refresh(file_attachment)
                
                successful_uploads.append(file_attachment)
                
                upload_results.append(FileUploadResponse(
                    success=True,
                    message=f"Fil {file.filename} uppladdad temporärt",
                    file_id=file_attachment.id,
                    original_filename=file.filename,
                    file_size=file_attachment.file_size
                ))
                
                logger.info(f"Temporär fil {file.filename} uppladdad")
                
            except HTTPException as http_error:
                upload_results.append(FileUploadResponse(
                    success=False,
                    message=str(http_error.detail),
                    original_filename=file.filename
                ))
                continue
            except Exception as upload_error:
                logger.error(f"Uppladdningsfel för {file.filename}: {str(upload_error)}")
                upload_results.append(FileUploadResponse(
                    success=False,
                    message=f"Uppladdningsfel för fil {file.filename}",
                    original_filename=file.filename
                ))
                continue
                
    except Exception as e:
        logger.error(f"Oväntat fel vid temporär filuppladdning: {str(e)}")
        
        # Rensa upp eventuella framgångsrika uppladdningar vid fel
        for file_attachment in successful_uploads:
            try:
                await storage_service.delete_file(file_attachment.stored_filename, temp_submission_id)
                db.delete(file_attachment)
           