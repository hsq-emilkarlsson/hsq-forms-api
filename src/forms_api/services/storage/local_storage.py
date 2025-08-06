"""
Local file storage service för utveckling
Används när Azure Blob Storage inte är konfigurerat
"""
import os
import logging
import shutil
import uuid
import magic
from typing import Optional, List, Tuple
from fastapi import UploadFile, HTTPException
from pathlib import Path

logger = logging.getLogger(__name__)

class LocalFileStorageService:
    """
    Lokal fillagring för utveckling
    Sparar filer i uploads/ mappen
    """
    
    # Tillåtna filtyper för säkerhet
    ALLOWED_CONTENT_TYPES = {
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'application/pdf', 
        'application/msword', 
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'text/plain', 'text/csv'
    }
    
    # Maximal filstorlek (10MB)
    MAX_FILE_SIZE = 10 * 1024 * 1024
    
    def __init__(self):
        self.upload_dir = Path("uploads")
        self.upload_dir.mkdir(exist_ok=True)
        logger.info(f"Local file storage initialized at: {self.upload_dir.absolute()}")
    
    def _validate_file_type(self, file_content: bytes, filename: str) -> str:
        """Validera filtyp med magic number detection"""
        try:
            # Detektera faktisk filtyp
            mime_type = magic.from_buffer(file_content, mime=True)
            
            if mime_type not in self.ALLOWED_CONTENT_TYPES:
                raise HTTPException(
                    status_code=400,
                    detail=f"Filtyp {mime_type} är inte tillåten för {filename}"
                )
            
            logger.info(f"File validated: {filename} -> {mime_type}")
            return mime_type
            
        except Exception as e:
            logger.error(f"File validation error for {filename}: {str(e)}")
            raise HTTPException(
                status_code=400,
                detail=f"Kunde inte validera filtyp för {filename}"
            )
    
    def _generate_secure_filename(self, original_filename: str) -> str:
        """Generera säkert filnamn"""
        # Behåll filextension men använd UUID för filnamn
        file_ext = Path(original_filename).suffix.lower()
        secure_name = f"{uuid.uuid4()}{file_ext}"
        return secure_name
    
    def _generate_folder_structure(self, form_type: str, submission_id: str) -> str:
        """
        Generera mappstruktur för lokal lagring som matchar Azure
        
        Struktur: forms/{form_type}/{year}/{month}/{submission_id}/
        """
        from datetime import datetime
        
        now = datetime.utcnow()
        year = now.strftime("%Y")
        month = now.strftime("%m")
        
        # Säkra form_type namn
        safe_form_type = "".join(c for c in form_type if c.isalnum() or c in "-_").strip()
        if not safe_form_type:
            safe_form_type = "general"
        
        folder_path = f"forms/{safe_form_type}/{year}/{month}/{submission_id}"
        return folder_path
    
    async def upload_file(self, file: UploadFile, submission_id: str, form_type: str, field_name: str = None) -> Tuple[str, int, str, str]:
        """
        Ladda upp fil till lokal lagring med organiserad mappstruktur
        
        Args:
            file: FastAPI UploadFile object
            submission_id: ID för submission som filen tillhör
            form_type: Typ av formulär (b2b-feedback, b2b-support, etc.)
            field_name: Namn på fältet som filen tillhör (optional)
        
        Returns:
            Tuple[str, int, str, str]: (storage_path, file_size, content_type, local_url)
        """
        try:
            # Läs filinnehåll
            file_content = await file.read()
            file_size = len(file_content)
            
            # Validera filstorlek
            if file_size > self.MAX_FILE_SIZE:
                raise HTTPException(
                    status_code=400,
                    detail=f"Fil {file.filename} är för stor ({file_size} bytes). Max: {self.MAX_FILE_SIZE} bytes"
                )
            
            # Validera filtyp
            content_type = self._validate_file_type(file_content, file.filename or "unknown")
            
            # Skapa mappstruktur
            folder_structure = self._generate_folder_structure(form_type, submission_id)
            full_upload_dir = self.upload_dir / folder_structure
            full_upload_dir.mkdir(parents=True, exist_ok=True)
            
            # Generera säkert filnamn med field_name prefix
            file_ext = Path(file.filename or "unknown").suffix.lower()
            unique_id = str(uuid.uuid4())[:8]
            
            if field_name:
                safe_field_name = "".join(c for c in field_name if c.isalnum() or c in "-_").strip()
                filename = f"{safe_field_name}_{unique_id}_{file.filename or 'unknown'}"
            else:
                filename = f"file_{unique_id}_{file.filename or 'unknown'}"
            
            # Säkra filnamnet
            safe_filename = "".join(c for c in filename if c.isalnum() or c in ".-_").strip()
            
            # Fullständig filsökväg
            file_path = full_upload_dir / safe_filename
            storage_path = f"{folder_structure}/{safe_filename}"
            
            # Spara fil
            with open(file_path, "wb") as f:
                f.write(file_content)
            
            # Skapa lokal URL
            local_url = f"file://{file_path.absolute()}"
            
            logger.info(f"File uploaded successfully: {file.filename} -> {storage_path}")
            logger.info(f"Organized in folder structure: {folder_structure}")
            
            return storage_path, file_size, content_type, local_url
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Upload error for {file.filename}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Kunde inte ladda upp fil {file.filename}"
            )
    
    async def delete_file(self, file_id: str, submission_id: str) -> bool:
        """Ta bort fil från lokal lagring"""
        try:
            submission_dir = self.upload_dir / submission_id
            
            # Hitta fil med file_id prefix
            for file_path in submission_dir.glob(f"{file_id}_*"):
                file_path.unlink()
                logger.info(f"File deleted: {file_path}")
                return True
            
            return False
            
        except Exception as e:
            logger.error(f"Delete error for file {file_id}: {str(e)}")
            return False
    
    async def get_file(self, file_id: str, submission_id: str) -> Optional[Tuple[bytes, str, str]]:
        """Hämta fil från lokal lagring"""
        try:
            submission_dir = self.upload_dir / submission_id
            
            # Hitta fil med file_id prefix
            for file_path in submission_dir.glob(f"{file_id}_*"):
                with open(file_path, "rb") as f:
                    content = f.read()
                
                # Detektera content type
                content_type = magic.from_buffer(content, mime=True)
                filename = file_path.name.split("_", 1)[1]  # Ta bort file_id prefix
                
                return content, content_type, filename
            
            return None
            
        except Exception as e:
            logger.error(f"Get file error for {file_id}: {str(e)}")
            return None
    
    async def list_files(self, submission_id: str) -> List[dict]:
        """Lista alla filer för en submission"""
        try:
            submission_dir = self.upload_dir / submission_id
            
            if not submission_dir.exists():
                return []
            
            files = []
            for file_path in submission_dir.iterdir():
                if file_path.is_file():
                    parts = file_path.name.split("_", 1)
                    if len(parts) == 2:
                        file_id, original_name = parts
                        file_size = file_path.stat().st_size
                        
                        files.append({
                            "file_id": file_id,
                            "original_filename": original_name,
                            "file_size": file_size,
                            "upload_path": str(file_path)
                        })
            
            return files
            
        except Exception as e:
            logger.error(f"List files error for submission {submission_id}: {str(e)}")
            return []

# Global instance för development
local_storage_service = LocalFileStorageService()
