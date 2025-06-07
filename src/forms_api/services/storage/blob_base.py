"""
Azure Blob Storage service för HSQ Forms API
Hanterar säker filuppladdning till Azure Blob Storage med managed identity
"""
import os
import uuid
import logging
import asyncio
from typing import Tuple, Optional
from fastapi import UploadFile, HTTPException
from azure.storage.blob.aio import BlobServiceClient
from azure.identity.aio import DefaultAzureCredential
from azure.core.exceptions import AzureError, ResourceNotFoundError
import magic

logger = logging.getLogger(__name__)

class AzureBlobStorageService:
    """
    Azure Blob Storage service med managed identity authentication
    och säkerhetsfunktioner för filuppladdning
    """
    
    # Säkra filtyper som tillåts
    ALLOWED_CONTENT_TYPES = {
        'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'text/plain', 'text/csv',
        'application/zip', 'application/x-zip-compressed'
    }
    
    # Maximal filstorlek (10MB)
    MAX_FILE_SIZE = 10 * 1024 * 1024
    
    def __init__(self):
        """
        Initialisera Azure Blob Storage med managed identity
        """
        self.account_name = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")
        self.container_name = os.getenv("AZURE_STORAGE_CONTAINER_NAME", "hsq-forms-files")
        self.temp_container_name = os.getenv("AZURE_STORAGE_TEMP_CONTAINER_NAME", "hsq-forms-temp")
        
        if not self.account_name:
            raise ValueError("AZURE_STORAGE_ACCOUNT_NAME environment variable is required")
        
        # Använd managed identity för autentisering
        self.credential = DefaultAzureCredential()
        self.blob_service_client = BlobServiceClient(
            account_url=f"https://{self.account_name}.blob.core.windows.net",
            credential=self.credential
        )
        
        logger.info(f"Azure Blob Storage service initialized for account: {self.account_name}")
    
    async def _ensure_containers_exist(self):
        """
        Säkerställ att containers finns, skapa dem om de inte existerar
        """
        try:
            # Skapa huvudcontainer för permanenta filer
            container_client = self.blob_service_client.get_container_client(self.container_name)
            try:
                await container_client.get_container_properties()
            except ResourceNotFoundError:
                await container_client.create_container()
                logger.info(f"Created container: {self.container_name}")
            
            # Skapa temp container för temporära filer
            temp_container_client = self.blob_service_client.get_container_client(self.temp_container_name)
            try:
                await temp_container_client.get_container_properties()
            except ResourceNotFoundError:
                await temp_container_client.create_container()
                logger.info(f"Created temp container: {self.temp_container_name}")
                
        except AzureError as e:
            logger.error(f"Failed to ensure containers exist: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail="Failed to initialize storage containers"
            )
    
    def _validate_file_type(self, file_content: bytes, filename: str) -> str:
        """
        Validera filtyp baserat på innehåll (inte bara filnamn)
        
        Returns:
            str: Content type
        """
        try:
            # Använd python-magic för att detektera filtyp baserat på innehåll
            mime_type = magic.from_buffer(file_content, mime=True)
            
            if mime_type not in self.ALLOWED_CONTENT_TYPES:
                raise HTTPException(
                    status_code=400,
                    detail=f"Filtyp {mime_type} är inte tillåten för fil {filename}"
                )
            
            return mime_type
            
        except Exception as e:
            logger.warning(f"Could not detect MIME type for {filename}: {str(e)}")
            # Fallback till filnamnsbaserad validering
            file_ext = filename.lower().split('.')[-1] if '.' in filename else ''
            
            ext_to_mime = {
                'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
                'png': 'image/png', 'gif': 'image/gif', 'webp': 'image/webp',
                'pdf': 'application/pdf',
                'doc': 'application/msword',
                'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'xls': 'application/vnd.ms-excel',
                'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'txt': 'text/plain', 'csv': 'text/csv',
                'zip': 'application/zip'
            }
            
            mime_type = ext_to_mime.get(file_ext, 'application/octet-stream')
            
            if mime_type not in self.ALLOWED_CONTENT_TYPES:
                raise HTTPException(
                    status_code=400,
                    detail=f"Filtyp {file_ext} är inte tillåten"
                )
            
            return mime_type
    
    def _generate_secure_blob_name(self, filename: str, submission_id: Optional[str] = None) -> str:
        """
        Generera säkert blob-namn
        """
        # Ta bort osäkra tecken från filnamn
        safe_filename = "".join(c for c in filename if c.isalnum() or c in '.-_').rstrip()
        if not safe_filename:
            safe_filename = "uploaded_file"
        
        # Lägg till UUID för unicitet
        unique_id = str(uuid.uuid4())
        
        if submission_id:
            return f"submissions/{submission_id}/{unique_id}_{safe_filename}"
        else:
            return f"temp/{unique_id}_{safe_filename}"
    
    async def upload_file(self, file: UploadFile, submission_id: str, folder_prefix: Optional[str] = None) -> Tuple[str, int, str]:
        """
        Ladda upp fil till Azure Blob Storage
        
        Args:
            file: Fil att ladda upp
            submission_id: ID för submission
            folder_prefix: Valfritt prefix för organisering
            
        Returns:
            Tuple[str, int, str]: (blob_name, file_size, content_type)
        """
        await self._ensure_containers_exist()
        
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
            
            # Generera säkert blob-namn
            blob_name = self._generate_secure_blob_name(file.filename or "unknown", submission_id)
            
            if folder_prefix:
                blob_name = f"{folder_prefix}/{blob_name}"
            
            # Ladda upp till Azure Blob Storage
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )
            
            await blob_client.upload_blob(
                file_content,
                content_type=content_type,
                overwrite=True,
                metadata={
                    'original_filename': file.filename or "unknown",
                    'submission_id': submission_id,
                    'uploaded_by': 'hsq_forms_api'
                }
            )
            
            logger.info(f"File uploaded successfully to Azure Blob Storage: {file.filename} -> {blob_name}")
            
            return blob_name, file_size, content_type
            
        except HTTPException:
            raise
        except AzureError as e:
            logger.error(f"Azure Storage error for {file.filename}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Azure Storage fel vid uppladdning av {file.filename}"
            )
        except Exception as e:
            logger.error(f"Upload error for {file.filename}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Kunde inte ladda upp fil {file.filename}"
            )
        finally:
            # Återställ filpekaren
            await file.seek(0)
    
    async def upload_file_temp(self, file: UploadFile) -> Tuple[str, int, str]:
        """
        Ladda upp temporär fil till Azure Blob Storage
        
        Args:
            file: Fil att ladda upp temporärt
            
        Returns:
            Tuple[str, int, str]: (blob_name, file_size, content_type)
        """
        await self._ensure_containers_exist()
        
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
            
            # Generera säkert blob-namn för temp
            blob_name = self._generate_secure_blob_name(file.filename or "unknown")
            
            # Ladda upp till temp container
            blob_client = self.blob_service_client.get_blob_client(
                container=self.temp_container_name,
                blob=blob_name
            )
            
            await blob_client.upload_blob(
                file_content,
                content_type=content_type,
                overwrite=True,
                metadata={
                    'original_filename': file.filename or "unknown",
                    'uploaded_by': 'hsq_forms_api',
                    'temp_upload': 'true'
                }
            )
            
            logger.info(f"Temp file uploaded successfully: {file.filename} -> {blob_name}")
            
            return blob_name, file_size, content_type
            
        except HTTPException:
            raise
        except AzureError as e:
            logger.error(f"Azure Storage error for temp upload {file.filename}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Azure Storage fel vid temporär uppladdning av {file.filename}"
            )
        except Exception as e:
            logger.error(f"Temp upload error for {file.filename}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Kunde inte ladda upp temporär fil {file.filename}"
            )
        finally:
            # Återställ filpekaren
            await file.seek(0)
    
    async def get_file(self, blob_name: str) -> Tuple[bytes, str, str]:
        """
        Hämta fil från Azure Blob Storage
        
        Args:
            blob_name: Namn på blob att hämta
            
        Returns:
            Tuple[bytes, str, str]: (file_content, content_type, original_filename)
        """
        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )
            
            # Hämta blob data och metadata
            blob_data = await blob_client.download_blob()
            file_content = await blob_data.readall()
            
            # Hämta metadata
            properties = await blob_client.get_blob_properties()
            content_type = properties.content_settings.content_type or 'application/octet-stream'
            original_filename = properties.metadata.get('original_filename', blob_name.split('/')[-1])
            
            return file_content, content_type, original_filename
            
        except ResourceNotFoundError:
            logger.warning(f"Blob not found: {blob_name}")
            raise HTTPException(
                status_code=404,
                detail=f"Fil {blob_name} hittades inte"
            )
        except AzureError as e:
            logger.error(f"Azure Storage error when retrieving {blob_name}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail=f"Azure Storage fel vid hämtning av fil"
            )
        except Exception as e:
            logger.error(f"Error retrieving file {blob_name}: {str(e)}")
            raise HTTPException(
                status_code=500,
                detail="Fel vid hämtning av fil"
            )
    
    async def delete_file(self, blob_name: str) -> Tuple[bool, str]:
        """
        Ta bort fil från Azure Blob Storage
        
        Args:
            blob_name: Namn på blob att ta bort
            
        Returns:
            Tuple[bool, str]: (success, error_message)
        """
        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )
            
            await blob_client.delete_blob()
            logger.info(f"Blob deleted successfully: {blob_name}")
            
            return True, ""
            
        except ResourceNotFoundError:
            logger.warning(f"Blob not found for deletion: {blob_name}")
            return False, f"Blob {blob_name} not found"
        except AzureError as e:
            logger.error(f"Azure Storage error when deleting {blob_name}: {str(e)}")
            return False, f"Azure Storage error: {str(e)}"
        except Exception as e:
            logger.error(f"Error deleting blob {blob_name}: {str(e)}")
            return False, f"Error: {str(e)}"
    
    async def delete_file_temp(self, blob_name: str) -> Tuple[bool, str]:
        """
        Ta bort temporär fil från Azure Blob Storage
        
        Args:
            blob_name: Namn på temp blob att ta bort
            
        Returns:
            Tuple[bool, str]: (success, error_message)
        """
        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=self.temp_container_name,
                blob=blob_name
            )
            
            await blob_client.delete_blob()
            logger.info(f"Temp blob deleted successfully: {blob_name}")
            
            return True, ""
            
        except ResourceNotFoundError:
            logger.warning(f"Temp blob not found for deletion: {blob_name}")
            return False, f"Temp blob {blob_name} not found"
        except AzureError as e:
            logger.error(f"Azure Storage error when deleting temp {blob_name}: {str(e)}")
            return False, f"Azure Storage error: {str(e)}"
        except Exception as e:
            logger.error(f"Error deleting temp blob {blob_name}: {str(e)}")
            return False, f"Error: {str(e)}"
    
    async def move_temp_to_permanent(self, temp_blob_name: str, submission_id: str) -> Tuple[str, bool, str]:
        """
        Flytta temporär fil till permanent lagring
        
        Args:
            temp_blob_name: Namn på temp blob
            submission_id: ID för submission
            
        Returns:
            Tuple[str, bool, str]: (new_blob_name, success, error_message)
        """
        try:
            # Hämta temp blob
            temp_blob_client = self.blob_service_client.get_blob_client(
                container=self.temp_container_name,
                blob=temp_blob_name
            )
            
            # Hämta metadata för att få originalfilnamn
            temp_properties = await temp_blob_client.get_blob_properties()
            original_filename = temp_properties.metadata.get('original_filename', temp_blob_name.split('/')[-1])
            
            # Generera nytt blob-namn för permanent lagring
            new_blob_name = self._generate_secure_blob_name(original_filename, submission_id)
            
            # Kopiera till permanent container
            permanent_blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=new_blob_name
            )
            
            # Kopiera blob
            copy_source = temp_blob_client.url
            await permanent_blob_client.start_copy_from_url(copy_source)
            
            # Vänta på att kopieringen ska slutföras
            copy_status = await permanent_blob_client.get_blob_properties()
            while copy_status.copy.status == 'pending':
                await asyncio.sleep(1)
                copy_status = await permanent_blob_client.get_blob_properties()
            
            if copy_status.copy.status == 'success':
                # Ta bort temp blob
                await temp_blob_client.delete_blob()
                logger.info(f"Successfully moved temp blob to permanent: {temp_blob_name} -> {new_blob_name}")
                return new_blob_name, True, ""
            else:
                logger.error(f"Failed to copy temp blob: {copy_status.copy.status}")
                return "", False, f"Copy failed with status: {copy_status.copy.status}"
                
        except AzureError as e:
            logger.error(f"Azure Storage error when moving temp blob {temp_blob_name}: {str(e)}")
            return "", False, f"Azure Storage error: {str(e)}"
        except Exception as e:
            logger.error(f"Error moving temp blob {temp_blob_name}: {str(e)}")
            return "", False, f"Error: {str(e)}"
    
    async def cleanup_old_temp_files(self, hours_old: int = 24):
        """
        Rensa gamla temporära filer
        
        Args:
            hours_old: Ålder i timmar för filer som ska rensas
        """
        try:
            from datetime import datetime, timedelta, timezone
            
            cutoff_time = datetime.now(timezone.utc) - timedelta(hours=hours_old)
            
            container_client = self.blob_service_client.get_container_client(self.temp_container_name)
            
            async for blob in container_client.list_blobs():
                if blob.last_modified < cutoff_time:
                    try:
                        await container_client.delete_blob(blob.name)
                        logger.info(f"Cleaned up old temp file: {blob.name}")
                    except Exception as e:
                        logger.warning(f"Failed to cleanup temp file {blob.name}: {str(e)}")
                        
        except Exception as e:
            logger.error(f"Error during temp file cleanup: {str(e)}")
    
    async def close(self):
        """
        Stäng Azure Blob Storage klienten
        """
        try:
            await self.blob_service_client.close()
            await self.credential.close()
        except Exception as e:
            logger.warning(f"Error closing Azure Blob Storage client: {str(e)}")

# Skapa global instans
blob_storage_service = AzureBlobStorageService()
