"""
Environment configuration for HSQ Forms API.

This module handles configuration for different environments
(development, staging, production) using environment variables
and .env files.
"""
import os
import json
import logging
from functools import lru_cache
from typing import Dict, List, Optional, Union

from pydantic import AnyHttpUrl, ConfigDict, validator
from pydantic_settings import BaseSettings

logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    """
    Application settings with environment-based configuration.
    
    This class uses Pydantic to validate and parse environment variables
    for application configuration.
    """
    
    model_config = ConfigDict(
        env_file=".env",
        env_file_encoding='utf-8',
        case_sensitive=False,
        extra='ignore'  # Allow extra fields to be ignored
    )
    
    # Basic application settings
    app_name: str = "HSQ Forms API"
    environment: str = os.environ.get("APP_ENVIRONMENT", "development")  # Get from Docker build arg
    debug: bool = environment != "production"
    testing: bool = False
    log_level: str = "debug" if environment == "development" else "info"
    
    # API settings
    api_version: str = "1.0.0"
    api_title: str = "HSQ Forms API"
    api_description: str = "A flexible form submission API for handling form data"
    api_prefix: str = "/api"
    api_docs_url: str = "/docs" if environment != "production" else None
    api_redoc_url: str = "/redoc" if environment != "production" else None
    
    # CORS settings
    cors_origins: Union[List[str], str] = "*" if environment == "development" else []
    cors_allow_credentials: bool = True
    cors_allow_methods: str = "GET,POST,PUT,DELETE,OPTIONS"
    cors_allow_headers: str = "Accept,Authorization,Content-Type,X-API-Key"
    
    @validator("cors_origins", pre=True)
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> Union[List[str], str]:
        """Parse CORS origins from string to list if needed."""
        if isinstance(v, str):
            if v == "*":
                return v
            if not v.startswith("["):
                return [i.strip() for i in v.split(",")]
        elif isinstance(v, list):
            return v
        raise ValueError("CORS_ORIGINS should be a comma-separated string or a list")
    
    # Database settings
    database_url: Optional[str] = None
    postgres_db: str = "hsq_forms"
    postgres_user: str = "postgres"
    postgres_password: str = "password"
    postgres_host: str = "postgres"
    postgres_port: int = 5432
    db_pool_size: int = 5
    db_max_overflow: int = 10
    db_pool_timeout: int = 30
    
    @property
    def effective_database_url(self) -> str:
        """Get the effective database URL - use DATABASE_URL if set, otherwise generate PostgreSQL URL."""
        if self.database_url:
            return self.database_url
        return f"postgresql://{self.postgres_user}:{self.postgres_password}@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
    
    # Storage settings
    storage_type: str = "local"  # local or azure
    local_storage_path: str = "./uploads"
    temp_upload_dir: str = "./uploads/temp"
    
    # Azure Storage settings
    azure_storage_account_name: Optional[str] = None
    azure_storage_account_key: Optional[str] = None
    azure_storage_connection_string: Optional[str] = None
    azure_storage_container_name: str = "form-attachments"
    azure_blob_expiry_days: int = 30
    
    # Security settings
    secret_key: str = "development_secret_key"
    access_token_expire_minutes: int = 60
    api_key_header_name: str = "X-API-Key"
    allowed_api_keys: Union[str, List[str]] = ""  # Comma-separated list of allowed API keys
    
    @validator("allowed_api_keys", pre=True)
    def parse_allowed_api_keys(cls, v: Union[str, List[str]]) -> Union[str, List[str]]:
        """Parse allowed API keys from string to list."""
        if isinstance(v, str):
            if not v:
                return []
            return [key.strip() for key in v.split(",")]
        return v
    
    # Form submission settings
    max_attachment_size_mb: int = 10
    max_form_size_kb: int = 2048  # 2MB for form data
    max_files_per_submission: int = 5
    allowed_file_types: str = "application/pdf,image/jpeg,image/png,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/vnd.ms-excel,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,text/plain"
    
    @property
    def allowed_file_types_list(self) -> List[str]:
        """Convert allowed file types string to list."""
        return self.allowed_file_types.split(',')
    
    # Webhook settings
    webhooks_enabled: bool = False
    webhook_urls: str = ""  # Comma-separated list of webhook URLs for form submissions
    webhook_form_specific_urls: str = "{}"  # JSON string mapping form IDs to webhook URLs
    webhook_secret: str = ""  # Secret key for webhook authentication
    
    @validator("webhooks_enabled", pre=True)
    def parse_webhooks_enabled(cls, v: Union[str, bool]) -> bool:
        """Parse webhooks enabled from environment variable."""
        if isinstance(v, bool):
            return v
        return str(v).lower() == "true"
    
    @property
    def webhook_urls_list(self) -> List[str]:
        """Convert webhook URLs string to list."""
        if not self.webhook_urls:
            return []
        return [url.strip() for url in self.webhook_urls.split(",")]
    
    @property
    def webhook_form_specific_config(self) -> Dict[str, str]:
        """Parse form-specific webhook configuration."""
        try:
            return json.loads(self.webhook_form_specific_urls)
        except Exception as e:
            logger.warning(f"Failed to parse webhook_form_specific_urls: {e}")
            return {}
    
    # Husqvarna ESB Integration settings
    husqvarna_esb_api_key: str = ""
    husqvarna_esb_base_url: str = "https://api-qa.integration.husqvarnagroup.com/hqw170/v1"
    husqvarna_esb_apac_customer_codes: str = ""  # Comma-separated list of APAC customer codes
    
    @property
    def husqvarna_esb_apac_codes_list(self) -> List[str]:
        """Convert APAC customer codes string to list."""
        if not self.husqvarna_esb_apac_customer_codes:
            return []
        return [code.strip() for code in self.husqvarna_esb_apac_customer_codes.split(",")]

@lru_cache()
def get_settings() -> Settings:
    """
    Get cached settings instance.
    
    This function uses lru_cache to cache the settings instance,
    improving performance by avoiding repeated parsing of environment
    variables. It also allows for dependency injection in FastAPI
    and makes testing easier by allowing settings to be mocked.
    
    Returns:
        Settings: Application settings instance
    """
    return Settings()


# Create a settings instance for direct import
settings = get_settings()


def get_environment() -> str:
    """
    Get the current environment.
    
    Returns:
        str: The current environment (development, staging, production)
    """
    return settings.environment
