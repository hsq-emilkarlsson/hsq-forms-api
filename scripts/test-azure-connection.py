#!/usr/bin/env python3
"""
Verktyg för att testa anslutning till Azure-resurser.
Detta skript kan användas för att verifiera att anslutningen till Azure Storage och 
PostgreSQL fungerar korrekt.

Användning:
python scripts/test-azure-connection.py
"""
import os
import sys
import time
from pathlib import Path

# Lägg till projektroten i Python path
project_root = Path(__file__).parent.parent.absolute()
sys.path.insert(0, str(project_root))

def test_azure_storage():
    """Test anslutning till Azure Storage"""
    print("\n🔍 Testar anslutning till Azure Storage...")
    
    # Kontrollera miljövariabler
    account_name = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")
    if not account_name:
        print("❌ AZURE_STORAGE_ACCOUNT_NAME saknas i miljövariabler")
        print("   Detta är förväntat om du kör testet lokalt utan Azure-konfiguration.")
        print("   I Azure DevOps pipeline sätts denna variabel automatiskt.")
        print("   För lokal testning, se README.md för instruktioner.")
        return False

    client_id = os.getenv("AZURE_CLIENT_ID")
    if not client_id:
        print("❌ AZURE_CLIENT_ID saknas i miljövariabler")
        print("   Detta är förväntat om du kör testet lokalt utan Azure-konfiguration.")
        print("   I Azure DevOps pipeline sätts denna variabel automatiskt.")
        print("   För lokal testning, se README.md för instruktioner.")
        return False

    try:
        # Importera Azure bibliotek
        from azure.identity import DefaultAzureCredential
        from azure.storage.blob import BlobServiceClient
        
        # Skapa anslutning med DefaultAzureCredential
        account_url = f"https://{account_name}.blob.core.windows.net"
        print(f"📦 Ansluter till {account_url} med Managed Identity...")
        credential = DefaultAzureCredential()
        blob_service_client = BlobServiceClient(account_url=account_url, credential=credential)
        
        # Lista containers
        print("📋 Listar containers...")
        containers = list(blob_service_client.list_containers())
        
        if not containers:
            print("⚠️ Inga containers hittades. Detta är ovanligt men inte nödvändigtvis ett fel.")
        else:
            print(f"✅ Hittade {len(containers)} containers:")
            for container in containers:
                print(f"   - {container.name}")
        
        # Testa att skapa och radera en tillfällig container
        test_container_name = f"test-container-{int(time.time())}"
        print(f"🧪 Testar att skapa och radera en container: {test_container_name}")
        
        # Skapa container
        container_client = blob_service_client.create_container(test_container_name)
        print("✅ Container skapad")
        
        # Skapa en test-blob
        blob_name = "test-blob.txt"
        blob_client = container_client.get_blob_client(blob_name)
        blob_client.upload_blob("Detta är ett test från HSQ Forms API.", overwrite=True)
        print("✅ Test-blob uppladdad")
        
        # Lista blobs
        blobs = list(container_client.list_blobs())
        print(f"✅ Hittade {len(blobs)} blobs i test-container")
        
        # Radera container
        blob_service_client.delete_container(test_container_name)
        print("✅ Container raderad")
        
        print("✅ Azure Storage-anslutning fungerar korrekt!")
        return True
        
    except Exception as e:
        print(f"❌ Fel vid anslutning till Azure Storage: {str(e)}")
        return False

def test_database():
    """Test anslutning till PostgreSQL"""
    print("\n🔍 Testar anslutning till PostgreSQL...")
    
    # Kontrollera miljövariabler
    db_url = os.getenv("SQLALCHEMY_DATABASE_URI")
    if not db_url:
        print("❌ SQLALCHEMY_DATABASE_URI saknas i miljövariabler")
        print("   Detta är förväntat om du kör testet lokalt utan Azure-konfiguration.")
        print("   I Azure DevOps pipeline sätts denna variabel automatiskt.")
        print("   För lokal testning, se README.md för instruktioner.")
        return False
    
    try:
        # Importera SQLAlchemy
        from sqlalchemy import create_engine, text
        
        # Skapa engine
        print(f"🔌 Ansluter till databas...")
        engine = create_engine(db_url)
        
        # Testa anslutning
        with engine.connect() as connection:
            # Kör en enkel query
            result = connection.execute(text("SELECT 1 as test"))
            row = result.fetchone()
            if row and row.test == 1:
                print("✅ Databasanslutning fungerar")
            else:
                print("❌ Databasanslutning fungerar inte korrekt")
                return False
            
            # Kolla om alembic_version-tabell existerar
            result = connection.execute(text(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'alembic_version')"
            ))
            has_alembic = result.scalar()
            
            if has_alembic:
                # Hämta aktuell version
                result = connection.execute(text("SELECT version_num FROM alembic_version"))
                version = result.scalar()
                print(f"✅ Databasschemat är migrerat (version: {version})")
            else:
                print("⚠️ alembic_version-tabell hittades inte - databasen kanske inte är migrerad")
        
        print("✅ Databastestet slutfördes framgångsrikt")
        return True
        
    except Exception as e:
        print(f"❌ Fel vid anslutning till databas: {str(e)}")
        return False

def main():
    """Huvudfunktion"""
    print("🔎 Testar anslutning till Azure-resurser...")
    
    # Kolla om vi kör i en CI/CD pipeline
    is_pipeline = os.getenv("BUILD_BUILDNUMBER") is not None
    
    # Kontrollera om vi är i en lokal miljö utan Azure-konfiguration
    if not os.getenv("AZURE_STORAGE_ACCOUNT_NAME") and not os.getenv("SQLALCHEMY_DATABASE_URI"):
        print("\n⚠️ Detta verkar vara en lokal utvecklingsmiljö utan Azure-konfiguration.")
        print("   För att köra detta test behöver du följande miljövariabler:")
        print("   - AZURE_STORAGE_ACCOUNT_NAME: Namnet på ditt Azure Storage-konto")
        print("   - AZURE_CLIENT_ID: Client ID för Managed Identity")
        print("   - SQLALCHEMY_DATABASE_URI: Anslutningssträng till PostgreSQL")
        print("\n💡 Rekommendation:")
        print("   1. Kör testerna via Azure DevOps pipeline där dessa variabler finns")
        print("   2. Eller ställ in variablerna lokalt med 'export' om du har tillgång till Azure-miljön")
        return 0 if not is_pipeline else 1
    
    # Testa Azure Storage
    storage_success = test_azure_storage()
    
    # Testa PostgreSQL
    db_success = test_database()
    
    # Sammanfattning
    print("\n📋 Sammanfattning:")
    print(f"{'✅' if storage_success else '❌'} Azure Storage: {'Fungerar' if storage_success else 'Problem'}")
    print(f"{'✅' if db_success else '❌'} PostgreSQL: {'Fungerar' if db_success else 'Problem'}")
    
    if storage_success and db_success:
        print("\n🎉 Alla anslutningar fungerar korrekt! Din app bör fungera i Azure.")
        return 0
    else:
        if is_pipeline:
            print("\n❌ Vissa anslutningar fungerar inte i pipeline-miljön. Detta bör inte hända!")
            return 1
        else:
            print("\n⚠️ Vissa anslutningar fungerar inte. Om du kör lokalt, se README.md för instruktioner.")
            # Returnera 0 för lokal körning även om testerna misslyckas
            return 0
        return 1

if __name__ == "__main__":
    sys.exit(main())
