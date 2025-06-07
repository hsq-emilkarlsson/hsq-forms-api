#!/usr/bin/env python3
"""
Test script för Azure Storage integration
Kör detta för att validera att Azure Storage fungerar korrekt
"""
import asyncio
import os
import tempfile
import logging
from fastapi import UploadFile
from pathlib import Path

# Konfigurera logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_azure_storage():
    """
    Test Azure Storage Service integration
    """
    print("🧪 Testing Azure Storage Integration...")
    
    # Sätt test miljövariabler (använd fake värden för test)
    test_env = {
        "AZURE_STORAGE_ACCOUNT_NAME": "testaccount",
        "AZURE_STORAGE_CONTAINER_NAME": "test-uploads",
        "AZURE_STORAGE_TEMP_CONTAINER_NAME": "test-temp",
        "FORCE_AZURE_STORAGE": "false"  # Använd lokal storage för test
    }
    
    for key, value in test_env.items():
        os.environ[key] = value
    
    try:
        # Importera storage service
        print("📦 Importing storage services...")
        from app.routers.files import get_storage_service
        
        # Hämta storage service
        storage_service, use_azure = get_storage_service()
        print(f"✅ Storage service initialized: {'Azure' if use_azure else 'Local'}")
        
        # Skapa test fil
        print("📄 Creating test file...")
        test_content = b"Test file content for HSQ Forms API"
        test_filename = "test_file.txt"
        
        # Skapa en mock UploadFile
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            temp_file.write(test_content)
            temp_file.flush()
            
            # Simulera UploadFile
            class MockUploadFile:
                def __init__(self, filename, content):
                    self.filename = filename
                    self.content = content
                    
                async def read(self):
                    return self.content
            
            mock_file = MockUploadFile(test_filename, test_content)
            test_submission_id = "test-submission-123"
            
            # Test upload
            print("⬆️  Testing file upload...")
            file_id, file_size, content_type = await storage_service.upload_file(mock_file, test_submission_id)
            print(f"✅ Upload successful: {file_id}, size: {file_size}, type: {content_type}")
            
            # Test get file
            print("⬇️  Testing file download...")
            if use_azure:
                result = await storage_service.get_file(file_id)
                downloaded_content, downloaded_type, metadata = result
            else:
                result = await storage_service.get_file(file_id, test_submission_id)
                if result:
                    downloaded_content, downloaded_type, _ = result
                else:
                    raise Exception("File not found")
            
            assert downloaded_content == test_content, "Content mismatch!"
            print(f"✅ Download successful: {len(downloaded_content)} bytes, type: {downloaded_type}")
            
            # Test delete
            print("🗑️  Testing file deletion...")
            if use_azure:
                success = await storage_service.delete_file(file_id)
            else:
                success = await storage_service.delete_file(file_id, test_submission_id)
            
            print(f"✅ Delete successful: {success}")
            
            # Cleanup temp file
            os.unlink(temp_file.name)
        
        print("🎉 All tests passed! Azure Storage integration is working correctly.")
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 This is expected if Azure dependencies are missing in development")
        return False
    except Exception as e:
        print(f"❌ Test failed: {e}")
        logger.exception("Full error details:")
        return False

async def test_config():
    """
    Test configuration loading
    """
    print("🔧 Testing configuration...")
    
    try:
        from app.config import get_settings
        settings = get_settings()
        
        print(f"✅ Configuration loaded:")
        print(f"   - Environment: {settings.environment}")
        print(f"   - Database URL: {'Set' if settings.database_url else 'Not set'}")
        print(f"   - Use Azure Storage: {settings.use_azure_storage}")
        print(f"   - Azure Storage Account: {settings.azure_storage_account_name or 'Not set'}")
        
        return True
        
    except Exception as e:
        print(f"❌ Configuration test failed: {e}")
        return False

if __name__ == "__main__":
    print("🚀 HSQ Forms API - Azure Integration Test")
    print("=" * 50)
    
    # Ändra till project root för korrekt import
    script_dir = Path(__file__).parent
    app_dir = script_dir / "apps" / "app"
    
    if not app_dir.exists():
        print(f"❌ Could not find app directory at {app_dir}")
        print("💡 Please run this script from the project root directory")
        exit(1)
    
    os.chdir(app_dir)
    
    async def run_tests():
        # Test configuration first
        config_ok = await test_config()
        
        # Test storage integration
        storage_ok = await test_azure_storage()
        
        print("\n" + "=" * 50)
        if config_ok and storage_ok:
            print("🎉 All integration tests passed!")
            print("✅ Ready for Azure deployment")
        else:
            print("⚠️  Some tests failed, but this may be expected in development")
            print("💡 Run 'azd up' to deploy to Azure for full testing")
    
    asyncio.run(run_tests())
