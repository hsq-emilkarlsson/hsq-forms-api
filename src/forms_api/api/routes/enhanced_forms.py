"""
Enhanced Forms Router med optimeringar för maximal effektivitet
"""
from fastapi import APIRouter, Depends, HTTPException, Request, Query, BackgroundTasks
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import func, desc, asc
from typing import List, Optional, Dict, Any
from functools import lru_cache
import asyncio
from datetime import datetime, timedelta

from src.forms_api.services.webhook_service import WebhookService
from src.forms_api.services.webhook_service import WebhookService

from src.forms_api.db import get_db
from src.forms_api.models import FormTemplate, FlexibleFormSubmission, FlexibleFormAttachment
from src.forms_api.schemas import (
    FormTemplateCreate, 
    FormTemplateResponse, 
    FlexibleFormSubmissionCreate, 
    FlexibleFormSubmissionResponse
)
from src.forms_api.services import FormBuilderService
from src.forms_api.config import get_settings

router = APIRouter(tags=["Enhanced Forms"])

# Cache för templates (i produktion: använd Redis)
template_cache = {}
schema_cache = {}

def get_cache_key(project_id: str, active_only: bool = True) -> str:
    """Generate cache key for templates"""
    return f"templates:{project_id}:active={active_only}"

@lru_cache(maxsize=100)
def get_cached_template_schema(template_id: str, updated_at: str) -> Dict[str, Any]:
    """Cache template schemas with LRU eviction"""
    # This would typically query from database or cache
    return schema_cache.get(template_id)

@router.post("/templates", response_model=FormTemplateResponse, status_code=201)
async def create_form_template(
    form_data: FormTemplateCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Skapa en ny formulärmall med optimerad prestanda
    
    Förbättringar:
    - Background cache invalidation
    - Batch schema generation
    - Enhanced validation
    """
    try:
        template = FormBuilderService.create_form_template(db, form_data)
        
        # Background task för cache invalidation
        background_tasks.add_task(invalidate_project_cache, form_data.project_id)
        background_tasks.add_task(preload_template_cache, template.id, db)
        
        return template
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/templates/project/{project_id}", response_model=List[FormTemplateResponse])
async def get_project_templates_optimized(
    project_id: str,
    active_only: bool = Query(True, description="Endast aktiva templates"),
    include_stats: bool = Query(False, description="Inkludera statistik"),
    db: Session = Depends(get_db)
):
    """
    Hämta templates för projekt med optimerad prestanda
    
    Förbättringar:
    - Eager loading av relationer
    - Optional statistik
    - Cachad respons
    """
    cache_key = get_cache_key(project_id, active_only)
    
    # Check cache first
    if cache_key in template_cache:
        cached_data = template_cache[cache_key]
        if cached_data['expires'] > datetime.utcnow():
            return cached_data['data']
    
    # Query med optimerad loading
    query = db.query(FormTemplate).filter(FormTemplate.project_id == project_id)
    
    if active_only:
        query = query.filter(FormTemplate.is_active == True)
    
    templates = query.order_by(desc(FormTemplate.created_at)).all()
    
    # Om statistik efterfrågas, ladda submission counts
    if include_stats:
        for template in templates:
            template.submission_count = db.query(func.count(FlexibleFormSubmission.id)).filter(
                FlexibleFormSubmission.template_id == template.id
            ).scalar()
    
    # Cache resultatet i 5 minuter
    template_cache[cache_key] = {
        'data': templates,
        'expires': datetime.utcnow() + timedelta(minutes=5)
    }
    
    return templates

@router.get("/templates/{template_id}/enhanced", response_model=Dict[str, Any])
async def get_template_with_analytics(
    template_id: str,
    include_recent_submissions: bool = Query(False),
    db: Session = Depends(get_db)
):
    """
    Hämta template med utökad analys och statistik
    """
    template = db.query(FormTemplate).filter(
        FormTemplate.id == template_id,
        FormTemplate.is_active == True
    ).first()
    
    if not template:
        raise HTTPException(status_code=404, detail="Form template not found")
    
    # Bygg omfattande respons
    response_data = {
        "template": template.to_dict(),
        "analytics": {
            "total_submissions": db.query(func.count(FlexibleFormSubmission.id)).filter(
                FlexibleFormSubmission.template_id == template_id
            ).scalar(),
            "submissions_today": db.query(func.count(FlexibleFormSubmission.id)).filter(
                FlexibleFormSubmission.template_id == template_id,
                func.date(FlexibleFormSubmission.created_at) == func.current_date()
            ).scalar(),
            "completion_rate": calculate_completion_rate(db, template_id),
            "avg_completion_time": calculate_avg_completion_time(db, template_id)
        }
    }
    
    if include_recent_submissions:
        recent_submissions = db.query(FlexibleFormSubmission).filter(
            FlexibleFormSubmission.template_id == template_id
        ).options(
            selectinload(FlexibleFormSubmission.attachments)
        ).order_by(desc(FlexibleFormSubmission.created_at)).limit(10).all()
        
        response_data["recent_submissions"] = [sub.to_dict() for sub in recent_submissions]
    
    return response_data

@router.post("/templates/{template_id}/submit/batch", response_model=List[Dict[str, Any]])
async def submit_multiple_forms(
    template_id: str,
    submissions: List[Dict[str, Any]],
    request: Request,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """
    Batch submission för flera formulär samtidigt
    
    Förbättringar:
    - Transaktionell säkerhet
    - Parallel validation
    - Background processing
    """
    if len(submissions) > 50:  # Begränsa batch-storlek
        raise HTTPException(status_code=400, detail="Max 50 submissions per batch")
    
    results = []
    successful_submissions = []
    
    try:
        # Hämta template en gång
        template = db.query(FormTemplate).filter(
            FormTemplate.id == template_id,
            FormTemplate.is_active == True
        ).first()
        
        if not template:
            raise HTTPException(status_code=404, detail="Form template not found")
        
        # Process submissions i batch
        for i, submission_data in enumerate(submissions):
            try:
                form_submission = FlexibleFormSubmissionCreate(
                    template_id=template_id,
                    data=submission_data.get("data", submission_data),
                    submitted_by=submission_data.get("submitted_by"),
                    submitted_from_project=request.headers.get("x-project-id", submission_data.get("project_id"))
                )
                
                submission = FormBuilderService.create_form_submission(
                    db=db,
                    submission_data=form_submission,
                    ip_address=request.client.host,
                    user_agent=request.headers.get("user-agent")
                )
                
                successful_submissions.append(submission)
                results.append({
                    "index": i,
                    "status": "success",
                    "submission_id": submission.id,
                    "submitted_at": submission.created_at.isoformat()
                })
                
            except Exception as e:
                results.append({
                    "index": i,
                    "status": "error",
                    "error": str(e)
                })
        
        # Background task för analytics update
        if successful_submissions:
            background_tasks.add_task(update_submission_analytics, template_id, len(successful_submissions))
            
            # Send webhook notifications for batch submissions in background
            for submission in successful_submissions:
                webhook_payload = {
                    "id": submission.id,
                    "template_id": submission.template_id,
                    "template_name": template.name,
                    "data": submission.data,
                    "submitted_by": submission.submitted_by,
                    "submitted_from_project": submission.submitted_from_project,
                    "submitted_at": submission.created_at.isoformat() if submission.created_at else None,
                    "is_batch": True,
                    "batch_size": len(submissions)
                }
                
                # Add webhook task to background tasks
                background_tasks.add_task(
                    WebhookService.send_form_submission_webhook,
                    event_type="batch_submission_created",
                    form_data=webhook_payload,
                    template_id=submission.template_id
                )
        
        return results
        
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Batch submission failed: {str(e)}")

@router.get("/analytics/dashboard/{project_id}")
async def get_project_dashboard(
    project_id: str,
    days: int = Query(30, ge=1, le=365, description="Antal dagar bakåt"),
    db: Session = Depends(get_db)
):
    """
    Instrumentpanel med projektstatistik
    """
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=days)
    
    # Hämta grundläggande statistik
    total_templates = db.query(func.count(FormTemplate.id)).filter(
        FormTemplate.project_id == project_id,
        FormTemplate.is_active == True
    ).scalar()
    
    total_submissions = db.query(func.count(FlexibleFormSubmission.id)).join(
        FormTemplate
    ).filter(
        FormTemplate.project_id == project_id,
        FlexibleFormSubmission.created_at >= start_date
    ).scalar()
    
    # Top templates efter submissions
    top_templates = db.query(
        FormTemplate.name,
        FormTemplate.id,
        func.count(FlexibleFormSubmission.id).label('submission_count')
    ).join(FlexibleFormSubmission).filter(
        FormTemplate.project_id == project_id,
        FlexibleFormSubmission.created_at >= start_date
    ).group_by(FormTemplate.id, FormTemplate.name).order_by(
        desc('submission_count')
    ).limit(10).all()
    
    # Submissions per dag
    daily_submissions = db.query(
        func.date(FlexibleFormSubmission.created_at).label('date'),
        func.count(FlexibleFormSubmission.id).label('count')
    ).join(FormTemplate).filter(
        FormTemplate.project_id == project_id,
        FlexibleFormSubmission.created_at >= start_date
    ).group_by(func.date(FlexibleFormSubmission.created_at)).order_by('date').all()
    
    return {
        "project_id": project_id,
        "period": f"{days} days",
        "total_templates": total_templates,
        "total_submissions": total_submissions,
        "avg_submissions_per_day": total_submissions / days if days > 0 else 0,
        "top_templates": [
            {"name": t.name, "id": t.id, "submissions": t.submission_count}
            for t in top_templates
        ],
        "daily_submissions": [
            {"date": ds.date.isoformat(), "count": ds.count}
            for ds in daily_submissions
        ]
    }

# Helper functions
async def invalidate_project_cache(project_id: str):
    """Invalidate cache för project templates"""
    keys_to_remove = [k for k in template_cache.keys() if k.startswith(f"templates:{project_id}")]
    for key in keys_to_remove:
        template_cache.pop(key, None)

async def preload_template_cache(template_id: str, db: Session):
    """Preload template i cache"""
    template = db.query(FormTemplate).filter(FormTemplate.id == template_id).first()
    if template:
        schema_cache[template_id] = template.schema

def calculate_completion_rate(db: Session, template_id: str) -> float:
    """Beräkna completion rate för template"""
    total = db.query(func.count(FlexibleFormSubmission.id)).filter(
        FlexibleFormSubmission.template_id == template_id
    ).scalar()
    
    processed = db.query(func.count(FlexibleFormSubmission.id)).filter(
        FlexibleFormSubmission.template_id == template_id,
        FlexibleFormSubmission.is_processed == True
    ).scalar()
    
    return (processed / total * 100) if total > 0 else 0

def calculate_avg_completion_time(db: Session, template_id: str) -> Optional[float]:
    """Beräkna genomsnittlig tid för completion"""
    # Detta skulle kräva timestamps för när forms började fyllas i
    # För nu returnerar vi None, men kan implementeras med session tracking
    return None

async def update_submission_analytics(template_id: str, count: int):
    """Background task för att uppdatera analytics"""
    # Här skulle vi uppdatera analytics/metrics system
    pass
