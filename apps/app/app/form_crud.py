from .cosmos_client import cosmos_client
from . import models, schemas
from fastapi import HTTPException, status
from typing import List, Optional, Dict, Any

def initialize_db():
    """Initialisera Cosmos DB-anslutning"""
    return cosmos_client.initialize()

def create_submission(submission_data: schemas.FormSubmissionCreate, 
                      ip_address: Optional[str] = None, 
                      user_agent: Optional[str] = None) -> Dict[str, Any]:
    """
    Skapa en ny formulärinlämning i Cosmos DB
    """
    try:
        # Skapa dokumentstruktur från formulärdata
        submission_doc = models.FormSubmission.create(
            name=submission_data.name,
            email=submission_data.email,
            message=submission_data.message,
            form_type=submission_data.form_type,
            metadata=submission_data.metadata,
            ip_address=ip_address,
            user_agent=user_agent
        )
        
        # Skicka till Cosmos DB
        created_item = cosmos_client.create_item(submission_doc)
        return created_item
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Databasfel: {str(e)}"
        )

def get_submission(submission_id: str, form_type: str) -> Dict[str, Any]:
    """
    Hämta ett specifikt formulär från Cosmos DB
    """
    item = cosmos_client.get_item(submission_id, form_type)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Formulärinlämningen hittades inte"
        )
    return item

def get_submissions(form_type: Optional[str] = None, limit: int = 50) -> List[Dict[str, Any]]:
    """
    Hämta alla formulär, eventuellt filtrerade per typ
    """
    if form_type:
        query = "SELECT * FROM c WHERE c.form_type = @form_type ORDER BY c.created_at DESC OFFSET 0 LIMIT @limit"
        params = [
            {"name": "@form_type", "value": form_type},
            {"name": "@limit", "value": limit}
        ]
        return cosmos_client.query_items(query, params)
    else:
        query = "SELECT * FROM c ORDER BY c.created_at DESC OFFSET 0 LIMIT @limit"
        params = [{"name": "@limit", "value": limit}]
        return cosmos_client.query_items(query, params)

def mark_as_processed(submission_id: str, form_type: str) -> Dict[str, Any]:
    """
    Markera ett formulär som behandlat
    """
    # Hämta aktuell post
    item = get_submission(submission_id, form_type)
    
    # Uppdatera status
    item["is_processed"] = True
    
    # Spara till Cosmos DB
    updated_item = cosmos_client.container.replace_item(
        item=submission_id,
        body=item,
        partition_key=form_type
    )
    
    return updated_item
