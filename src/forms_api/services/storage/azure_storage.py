"""
Azure Blob Storage Service för HSQ Forms API
Implementerar Azure best practices för säker och effektiv filhantering
"""
import os
import uuid
import asyncio
import logging
from typing import Tuple, Optional, List
from fastapi import UploadFile, HTTPException
from azure.storage.blob.aio import BlobServiceClient
from azure.core.exceptions import AzureError, ResourceNotFoundError
from azure.identity.aio import DefaultAzureCredential
import magic
from pathlib import Path

logger = logging.getLogger(__name__)

class AzureStorageService:
    """
    Azure Blob Storage service med säkerhetsfeatures och performance optimeringar
    Följer Azure best practices för authentication och error handling
    """
    
    # Säkerhetsrestriktioner
    ALLOWED_CONTENT_TYPES = {
        'image/jpeg', 'image/png', 'image/gif', 'image/webp',
        'application/pdf', 'text/plain', 'text/csv',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/msword', 'application/vnd.ms-excel'
    }
    
    MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
    MAX_FILES_PER_REQUEST = 5
    
    def __init__(self):
        """
        Initialisera Azure Storage med Managed Identity (rekommenderat för Azure)
        Använder DefaultAzureCredential för automatisk authentication
        """
        # Hämta konfiguration från miljövariabler
        self.account_name = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")
        self.container_name = os.getenv("AZURE_STORAGE_CONTAINER_NAME", "form-uploads")
        self.temp_container_name = os.getenv("AZURE_STORAGE_TEMP_CONTAINER_NAME", "temp-uploads")
        
        if not self.account_name:
            raise ValueError("AZURE_STORAGE_ACCOUNT_NAME environment variable required")
        
        # Använd Managed Identity för authentication (Azure best practice)
        account_url = f"https://{self.account_name}.blob.core.windows.net"
        
        # DefaultAzureCredential försöker automatiskt:
        # 1. Managed Identity (för Azure-hosted apps)
        # 2. Azure CLI credentials (för lokal utveckling)
        # 3. Environment variables
        # 4. Interactive browser (för användarappar)
        self.credential = DefaultAzureCredential()
        self.blob_service_client = BlobServiceClient(
            account_url=account_url,
            credential=self.credential
        )
        
        logger.info(f"Azure Storage initialized: {account_url}")
    
    async def _ensure_containers_exist(self):
        """
        Säkerställ att containers finns, skapa dem om de inte existerar
        """
        try:
            # Skapa huvudcontainer
            container_client = self.blob_service_client.get_container_client(self.container_name)
            if not await container_client.exists():
                await container_client.create_container()
                logger.info(f"Container {self.container_name} skapad")
            
            # Skapa temp container
            temp_container_client = self.blob_service_client.get_container_client(self.temp_container_name)
            if not await temp_container_client.exists():
                await temp_container_client.create_container()
                logger.info(f"Temp container {self.temp_container_name} skapad")
                
        except AzureError as e:
            logger.error(f"Fel vid skapande av containers: {str(e)}")
            raise HTTPException(status_code=500, detail="Kunde inte initiera storage containers")
    
    def _validate_file_type(self, file_content: bytes, filename: str) -> str:
        """
        Validera filtyp med magic number detection för säkerhet
        """
        try:
            # Detektera faktisk filtyp från innehåll
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
    
    def _generate_secure_blob_name(self, filename: str, form_type: str, submission_id: str, field_name: str = None) -> str:
        """
        Generera säkert blob-namn med organiserad mappstruktur per formulärtyp
        
        Mappstruktur:
        forms/{form_type}/{year}/{month}/{submission_id}/{field_name}_{uuid}_{filename}
        
        Exempel:
        forms/b2b-feedback/2025/08/sub123/attachments_uuid123_document.pdf
        forms/b2b-support/2025/08/sub456/technical_docs_uuid456_manual.pdf
        """
        from datetime import datetime
        
        # Säkra filnamnet
        safe_filename = "".join(c for c in filename if c.isalnum() or c in ".-_").strip()
        if not safe_filename:
            safe_filename = "unknown_file"
        
        # Skapa unikt ID
        unique_id = str(uuid.uuid4())[:8]  # Kortare UUID för läsbarhet
        
        # Bygg mappstruktur
        now = datetime.utcnow()
        year = now.strftime("%Y")
        month = now.strftime("%m")
        
        # Säkra form_type namn
        safe_form_type = "".join(c for c in form_type if c.isalnum() or c in "-_").strip()
        if not safe_form_type:
            safe_form_type = "general"
        
        # Bygg filnamn med field_name prefix om det finns
        if field_name:
            safe_field_name = "".join(c for c in field_name if c.isalnum() or c in "-_").strip()
            file_prefix = f"{safe_field_name}_{unique_id}"
        else:
            file_prefix = f"file_{unique_id}"
        
        # Fullständig sökväg
        blob_path = f"forms/{safe_form_type}/{year}/{month}/{submission_id}/{file_prefix}_{safe_filename}"
        
        return blob_path

    async def upload_file(self, file: UploadFile, submission_id: str, form_type: str, field_name: str = None) -> Tuple[str, int, str, str]:
        """
        Ladda upp fil till Azure Blob Storage med organiserad mappstruktur
        
        Args:
            file: FastAPI UploadFile object
            submission_id: ID för submission som filen tillhör
            form_type: Typ av formulär (b2b-feedback, b2b-support, etc.)
            field_name: Namn på fältet som filen tillhör (optional)
            
        Returns:
            Tuple[str, int, str, str]: (blob_path, file_size, content_type, blob_url)
        """
        try:
            await self._ensure_containers_exist()
            
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
            
            # Generera säkert blob-namn med mappstruktur
            blob_path = self._generate_secure_blob_name(
                file.filename or "unknown", 
                form_type,
                submission_id,
                field_name
            )
            
            # Upload till Azure med retry logic
            container_client = self.blob_service_client.get_container_client(self.container_name)
            blob_client = container_client.get_blob_client(blob_path)
            
            # Metadata för spårning och organisation
            metadata = {
                "original_filename": file.filename or "unknown",
                "submission_id": submission_id,
                "form_type": form_type,
                "field_name": field_name or "general",
                "content_type": content_type,
                "upload_source": "api",
                "upload_timestamp": str(int(asyncio.get_event_loop().time()))
            }
            
            # Upload med retry (Azure SDK hanterar detta automatiskt)
            await blob_client.upload_blob(
                data=file_content,
                blob_type="BlockBlob",
                content_type=content_type,
                metadata=metadata,
                overwrite=True  # I fall av duplicat blob_name
            )
            
            # Skapa full blob URL
            blob_url = f"https://{self.account_name}.blob.core.windows.net/{self.container_name}/{blob_path}"
            
            logger.info(f"File uploaded successfully to Azure: {file.filename} -> {blob_path}")
            logger.info(f"Organized in folder structure: forms/{form_type}/")
            
            return blob_path, file_size, content_type, blob_url
            
        except HTTPException:
            raise
        except AzureError as e:
            logger.error(f"Azure upload error for {file.filename}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Azure storage error: {str(e)}"
            )
        except Exception as e:
            logger.error(f"Upload error for {file.filename}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Kunde inte ladda upp fil {file.filename}"
            )
    
    async def upload_file_temp(self, file: UploadFile) -> Tuple[str, int, str]:
        """
        Ladda upp temporär fil innan submission skapas
        """
        try:
            await self._ensure_containers_exist()
            
            # Läs filinnehåll
            file_content = await file.read()
            file_size = len(file_content)
            
            # Validera filstorlek och typ
            if file_size > self.MAX_FILE_SIZE:
                raise HTTPException(
                    status_code=400,
                    detail=f"Fil {file.filename} är för stor ({file_size} bytes)"
                )
            
            content_type = self._validate_file_type(file_content, file.filename or "unknown")
            
            # Generera blob-namn för temp container
            blob_name = self._generate_secure_blob_name(file.filename or "unknown", "temp")
            
            # Upload till temp container
            temp_container_client = self.blob_service_client.get_container_client(self.temp_container_name)
            blob_client = temp_container_client.get_blob_client(blob_name)
            
            metadata = {
                "original_filename": file.filename or "unknown",
                "content_type": content_type,
                "upload_source": "temp_api",
                "created_for": "temporary_upload"
            }
            
            await blob_client.upload_blob(
                data=file_content,
                blob_type="BlockBlob",
                content_type=content_type,
                metadata=metadata,
                overwrite=True
            )
            
            logger.info(f"Temporary file uploaded to Azure: {file.filename} -> {blob_name}")
            
            return blob_name, file_size, content_type
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Temp upload error for {file.filename}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Kunde inte ladda upp temporär fil {file.filename}"
            )
    
    async def get_file(self, blob_name: str, use_temp_container: bool = False) -> Tuple[bytes, str, dict]:
        """
        Hämta fil från Azure Blob Storage
        
        Args:
            blob_name: Namnet på blob:en
            use_temp_container: Om filen finns i temp container
            
        Returns:
            Tuple[bytes, str, dict]: (file_content, content_type, metadata)
        """
        try:
            container_name = self.temp_container_name if use_temp_container else self.container_name
            container_client = self.blob_service_client.get_container_client(container_name)
            blob_client = container_client.get_blob_client(blob_name)
            
            # Hämta blob data och metadata
            blob_data = await blob_client.download_blob()
            file_content = await blob_data.readall()
            
            # Hämta metadata
            properties = await blob_client.get_blob_properties()
            content_type = properties.content_type or "application/octet-stream"
            metadata = properties.metadata or {}
            
            logger.info(f"File downloaded from Azure: {blob_name}")
            
            return file_content, content_type, metadata
            
        except ResourceNotFoundError:
            logger.warning(f"File not found in Azure: {blob_name}")
            raise HTTPException(status_code=404, detail="Fil hittades inte")
        except Exception as e:
            logger.error(f"Download error for {blob_name}: {str(e)}")
            raise HTTPException(status_code=500, detail="Kunde inte hämta fil från Azure")
    
    async def delete_file(self, blob_name: str, submission_id: str = None) -> bool:
        """
        Ta bort fil från Azure Blob Storage
        
        Args:
            blob_name: Namnet på blob:en som ska tas bort
            submission_id: Submission ID (behålls för kompatibilitet med lokal storage)
        """
        try:
            container_client = self.blob_service_client.get_container_client(self.container_name)
            blob_client = container_client.get_blob_client(blob_name)
            
            await blob_client.delete_blob()
            logger.info(f"File deleted from Azure: {blob_name}")
            
            return True
            
        except ResourceNotFoundError:
            logger.warning(f"File not found for deletion: {blob_name}")
            return False
        except Exception as e:
            logger.error(f"Delete error for {blob_name}: {str(e)}")
            raise HTTPException(status_code=500, detail="Kunde inte ta bort fil från Azure")
    
    async def delete_file_temp(self, blob_name: str) -> bool:
        """
        Ta bort temporär fil från Azure Blob Storage
        """
        try:
            temp_container_client = self.blob_service_client.get_container_client(self.temp_container_name)
            blob_client = temp_container_client.get_blob_client(blob_name)
            
            await blob_client.delete_blob()
            logger.info(f"Temporary file deleted from Azure: {blob_name}")
            
            return True
            
        except ResourceNotFoundError:
            logger.warning(f"Temporary file not found for deletion: {blob_name}")
            return False
        except Exception as e:
            logger.error(f"Temp delete error for {blob_name}: {str(e)}")
            return False
    
    async def move_temp_to_permanent(self, temp_blob_name: str, submission_id: str) -> str:
        """
        Flytta temporär fil till permanent storage och koppla till submission
        """
        try:
            # Hämta temporär fil
            file_content, content_type, metadata = await self.get_file(temp_blob_name, use_temp_container=True)
            
            # Generera nytt blob-namn för permanent lagring
            original_filename = metadata.get("original_filename", "unknown")
            permanent_blob_name = self._generate_secure_blob_name(
                original_filename,
                f"submissions/{submission_id}"
            )
            
            # Upload till permanent container
            container_client = self.blob_service_client.get_container_client(self.container_name)
            blob_client = container_client.get_blob_client(permanent_blob_name)
            
            # Uppdatera metadata
            metadata.update({
                "submission_id": submission_id,
                "moved_from_temp": temp_blob_name,
                "upload_source": "moved_from_temp"
            })
            
            await blob_client.upload_blob(
                data=file_content,
                blob_type="BlockBlob",
                content_type=content_type,
                metadata=metadata,
                overwrite=True
            )
            
            # Ta bort temporär fil
            await self.delete_file_temp(temp_blob_name)
            
            logger.info(f"File moved from temp to permanent: {temp_blob_name} -> {permanent_blob_name}")
            
            return permanent_blob_name
            
        except Exception as e:
            logger.error(f"Error moving temp file {temp_blob_name}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail="Kunde inte flytta temporär fil till permanent lagring"
            )
    
    async def cleanup_old_temp_files(self, hours_old: int = 24):
        """
        Rensa gamla temporära filer (ska köras via scheduled job)
        """
        try:
            from datetime import datetime, timedelta, timezone
            
            cutoff_time = datetime.now(timezone.utc) - timedelta(hours=hours_old)
            temp_container_client = self.blob_service_client.get_container_client(self.temp_container_name)
            
            deleted_count = 0
            async for blob in temp_container_client.list_blobs():
                if blob.last_modified < cutoff_time:
                    blob_client = temp_container_client.get_blob_client(blob.name)
                    try:
                        await blob_client.delete_blob()
                        deleted_count += 1
                    except Exception as e:
                        logger.warning(f"Could not delete old temp file {blob.name}: {str(e)}")
            
            logger.info(f"Cleanup completed: {deleted_count} old temp files deleted")
            return deleted_count
            
        except Exception as e:
            logger.error(f"Cleanup error: {str(e)}")
            return 0
    
    async def __aenter__(self):
        """Async context manager entry"""
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit - stäng connections"""
        if hasattr(self, 'blob_service_client'):
            await self.blob_service_client.close()
        if hasattr(self, 'credential'):
            await self.credential.close()
