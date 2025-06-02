"""
Azure Blob Storage service för säker filhantering
Implementerar Azure-best practices för filuppladdning och säkerhet
"""
import os
import logging
import asyncio
from typing import Optional, List, Tuple
from fastapi import UploadFile, HTTPException
from azure.storage.blob.aio import BlobServiceClient
from azure.core.exceptions import AzureError
from azure.identity.aio import DefaultAzureCredential
import uuid
import magic
from pathlib import Path

logger = logging.getLogger(__name__)

class AzureBlobStorageService:
    """
    Azure Blob Storage service med säkerhetsfokus och best practices
    Använder Managed Identity för autentisering
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
        self.account_name = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")
        self.container_name = os.getenv("AZURE_STORAGE_CONTAINER_NAME", "form-attachments")
        self.account_url = f"https://{self.account_name}.blob.core.windows.net"
        
        if not self.account_name:
            raise ValueError("AZURE_STORAGE_ACCOUNT_NAME environment variable is required")
        
        # Använd Managed Identity för autentisering (Azure best practice)
        self.credential = DefaultAzureCredential()
        self.blob_service_client = None
        
    async def _get_blob_service_client(self) -> BlobServiceClient:
        """Lazy initialization av BlobServiceClient"""
        if not self.blob_service_client:
            self.blob_service_client = BlobServiceClient(
                account_url=self.account_url,
                credential=self.credential
            )
        return self.blob_service_client
    
    async def validate_file(self, file: UploadFile) -> Tuple[bool, str]:
        """
        Validera fil för säkerhet och storlek
        Returnerar (is_valid, error_message)
        """
        try:
            # Kontrollera filstorlek
            file_content = await file.read()
            await file.seek(0)  # Reset file pointer
            
            if len(file_content) > self.MAX_FILE_SIZE:
                return False, f"Filen är för stor. Max storlek är {self.MAX_FILE_SIZE / (1024*1024):.1f}MB"
            
            if len(file_content) == 0:
                return False, "Filen är tom"
            
            # Validera content-type med python-magic för säkerhet
            detected_mime = magic.from_buffer(file_content, mime=True)
            
            # Kontrollera både deklarerad och detekterad MIME-typ
            if file.content_type not in self.ALLOWED_CONTENT_TYPES:
                return False, f"Filtyp {file.content_type} är inte tillåten"
            
            if detected_mime not in self.ALLOWED_CONTENT_TYPES:
                return False, f"Detekterad filtyp {detected_mime} är inte tillåten"
            
            # Extra säkerhetskontroll för filändelse
            if file.filename:
                file_extension = Path(file.filename).suffix.lower()
                allowed_extensions = {
                    '.jpg', '.jpeg', '.png', '.gif', '.webp',
                    '.pdf', '.doc', '.docx', '.xls', '.xlsx',
                    '.txt', '.csv'
                }
                if file_extension not in allowed_extensions:
                    return False, f"Filändelse {file_extension} är inte tillåten"
            
            return True, ""
            
        except Exception as e:
            logger.error(f"Fel vid filvalidering: {str(e)}")
            return False, "Fel vid filvalidering"
    
    async def upload_file(
        self, 
        file: UploadFile, 
        submission_id: str,
        folder_prefix: str = "submissions"
    ) -> Tuple[Optional[str], Optional[str], str]:
        """
        Ladda upp fil till Azure Blob Storage
        Returnerar (blob_url, stored_filename, error_message)
        """
        try:
            # Validera fil först
            is_valid, error_msg = await self.validate_file(file)
            if not is_valid:
                return None, None, error_msg
            
            # Generera säkert filnamn
            file_extension = Path(file.filename).suffix.lower() if file.filename else ""
            stored_filename = f"{folder_prefix}/{submission_id}/{uuid.uuid4()}{file_extension}"
            
            # Läs filinnehåll
            file_content = await file.read()
            await file.seek(0)  # Reset file pointer
            
            # Få blob service client
            blob_service_client = await self._get_blob_service_client()
            
            # Skapa container om den inte finns
            try:
                container_client = blob_service_client.get_container_client(self.container_name)
                await container_client.create_container()
                logger.info(f"Container {self.container_name} skapad")
            except Exception:
                # Container finns redan, vilket är OK
                pass
            
            # Ladda upp fil till blob storage
            blob_client = blob_service_client.get_blob_client(
                container=self.container_name,
                blob=stored_filename
            )
            
            # Sätt metadata för säkerhet och spårning
            metadata = {
                "submission_id": submission_id,
                "original_filename": file.filename or "unknown",
                "upload_timestamp": str(asyncio.get_event_loop().time()),
                "content_type": file.content_type or "application/octet-stream"
            }
            
            await blob_client.upload_blob(
                file_content,
                content_type=file.content_type,
                metadata=metadata,
                overwrite=True
            )
            
            # Generera blob URL
            blob_url = f"{self.account_url}/{self.container_name}/{stored_filename}"
            
            logger.info(f"Fil {file.filename} uppladdad som {stored_filename}")
            return blob_url, stored_filename, ""
            
        except AzureError as e:
            error_msg = f"Azure storage error: {str(e)}"
            logger.error(error_msg)
            return None, None, error_msg
        except Exception as e:
            error_msg = f"Oväntat fel vid filuppladdning: {str(e)}"
            logger.error(error_msg)
            return None, None, error_msg
    
    async def delete_file(self, stored_filename: str) -> Tuple[bool, str]:
        """
        Ta bort fil från Azure Blob Storage
        Returnerar (success, error_message)
        """
        try:
            blob_service_client = await self._get_blob_service_client()
            blob_client = blob_service_client.get_blob_client(
                container=self.container_name,
                blob=stored_filename
            )
            
            await blob_client.delete_blob()
            logger.info(f"Fil {stored_filename} borttagen från blob storage")
            return True, ""
            
        except AzureError as e:
            error_msg = f"Azure storage error vid borttagning: {str(e)}"
            logger.error(error_msg)
            return False, error_msg
        except Exception as e:
            error_msg = f"Oväntat fel vid filborttagning: {str(e)}"
            logger.error(error_msg)
            return False, error_msg
    
    async def get_file_info(self, stored_filename: str) -> Tuple[Optional[dict], str]:
        """
        Hämta filinformation från Azure Blob Storage
        Returnerar (file_info_dict, error_message)
        """
        try:
            blob_service_client = await self._get_blob_service_client()
            blob_client = blob_service_client.get_blob_client(
                container=self.container_name,
                blob=stored_filename
            )
            
            properties = await blob_client.get_blob_properties()
            
            file_info = {
                "size": properties.size,
                "content_type": properties.content_settings.content_type,
                "last_modified": properties.last_modified,
                "metadata": properties.metadata,
                "url": f"{self.account_url}/{self.container_name}/{stored_filename}"
            }
            
            return file_info, ""
            
        except AzureError as e:
            error_msg = f"Azure storage error vid hämtning av filinfo: {str(e)}"
            logger.error(error_msg)
            return None, error_msg
        except Exception as e:
            error_msg = f"Oväntat fel vid hämtning av filinfo: {str(e)}"
            logger.error(error_msg)
            return None, error_msg
    
    async def close(self):
        """Stäng Azure-klienter"""
        if self.blob_service_client:
            await self.blob_service_client.close()
        if self.credential:
            await self.credential.close()


# Global instance för användning i API
blob_storage_service = AzureBlobStorageService()
