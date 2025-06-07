"""
Enhanced FormBuilderService med prestanda-optimeringar
"""
import json
import asyncio
from typing import Dict, Any, List, Optional, Tuple
from functools import lru_cache
from datetime import datetime, timedelta
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import func, and_, or_

from .models import FormTemplate, FlexibleFormSubmission, FlexibleFormAttachment
from .schemas import FormTemplateCreate, FlexibleFormSubmissionCreate
import jsonschema
from jsonschema import validate, ValidationError


class EnhancedFormBuilderService:
    """
    Förbättrad service för formulärhantering med fokus på prestanda
    
    Förbättringar:
    - Schema caching med LRU
    - Batch operationer
    - Optimerade queries
    - Validation caching
    - Analytics integration
    """
    
    # Class-level cache för schemas (i produktion: använd Redis)
    _schema_cache = {}
    _validation_cache = {}
    
    @staticmethod
    @lru_cache(maxsize=500)
    def generate_json_schema_cached(fields_hash: str, fields_json: str) -> Dict[str, Any]:
        """
        Cachad version av schema generation
        fields_hash används som cache key för LRU
        """
        fields = json.loads(fields_json)
        return EnhancedFormBuilderService._generate_json_schema_internal(fields)
    
    @staticmethod
    def _generate_json_schema_internal(fields: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Intern schema generation - optimerad version"""
        schema = {
            "type": "object",
            "properties": {},
            "required": [],
            "additionalProperties": False  # Förbättrad säkerhet
        }
        
        for field in fields:
            field_schema = {
                "type": field["type"],
                "title": field["label"],
                "description": field.get("description", "")
            }
            
            # Optimerad typ-hantering
            field_type = field["type"]
            
            if field_type == "string":
                EnhancedFormBuilderService._add_string_constraints(field_schema, field)
            elif field_type in ["number", "integer"]:
                EnhancedFormBuilderService._add_numeric_constraints(field_schema, field)
            elif field_type == "array":
                EnhancedFormBuilderService._add_array_constraints(field_schema, field)
            elif field_type == "file":
                EnhancedFormBuilderService._add_file_constraints(field_schema, field)
            
            # Enum values för dropdowns
            if field.get("enum"):
                field_schema["enum"] = field["enum"]
            
            schema["properties"][field["name"]] = field_schema
            
            if field.get("required", False):
                schema["required"].append(field["name"])
        
        return schema
    
    @staticmethod
    def _add_string_constraints(field_schema: Dict, field: Dict):
        """Lägg till string constraints"""
        constraints = ["min_length", "max_length", "pattern", "format"]
        for constraint in constraints:
            if field.get(constraint):
                schema_key = constraint.replace("_", "")  # min_length -> minlength
                if schema_key == "minlength":
                    schema_key = "minLength"
                elif schema_key == "maxlength":
                    schema_key = "maxLength"
                field_schema[schema_key] = field[constraint]
    
    @staticmethod
    def _add_numeric_constraints(field_schema: Dict, field: Dict):
        """Lägg till numeriska constraints"""
        if field.get("minimum") is not None:
            field_schema["minimum"] = field["minimum"]
        if field.get("maximum") is not None:
            field_schema["maximum"] = field["maximum"]
    
    @staticmethod
    def _add_array_constraints(field_schema: Dict, field: Dict):
        """Lägg till array constraints"""
        field_schema["items"] = {"type": "string"}  # Default
        if field.get("min_items"):
            field_schema["minItems"] = field["min_items"]
        if field.get("max_items"):
            field_schema["maxItems"] = field["max_items"]
        if field.get("multiple", False):
            field_schema["uniqueItems"] = False
    
    @staticmethod
    def _add_file_constraints(field_schema: Dict, field: Dict):
        """Lägg till fil constraints"""
        field_schema["type"] = "string"  # Files som base64 eller URLs
        if field.get("accepted_types"):
            field_schema["pattern"] = f"({'|'.join(field['accepted_types'])})"
        if field.get("max_file_size"):
            field_schema["maxLength"] = field["max_file_size"]
    
    @staticmethod
    def create_form_template_enhanced(
        db: Session, 
        form_data: FormTemplateCreate,
        enable_caching: bool = True
    ) -> FormTemplate:
        """
        Förbättrad template creation med caching
        """
        # Konvertera fields till dict format
        fields_dict = [field.model_dump() for field in form_data.fields]
        fields_json = json.dumps(fields_dict, sort_keys=True)
        fields_hash = str(hash(fields_json))
        
        # Generera JSON schema med caching
        if enable_caching:
            schema = EnhancedFormBuilderService.generate_json_schema_cached(fields_hash, fields_json)
        else:
            schema = EnhancedFormBuilderService._generate_json_schema_internal(fields_dict)
        
        # Förbättrade validation rules
        validation_rules = {
            "strict_schema": True,
            "allow_additional_properties": False,
            "validate_file_types": True,
            "max_file_size": 10 * 1024 * 1024,  # 10MB default
            "max_files_per_field": 5,
            "created_with_version": "2.0"
        }
        
        # Skapa template
        form_template = FormTemplate(
            name=form_data.name,
            description=form_data.description,
            project_id=form_data.project_id,
            schema=schema,
            validation_rules=validation_rules,
            created_by=form_data.created_by
        )
        
        db.add(form_template)
        db.commit()
        db.refresh(form_template)
        
        # Cache schema för framtida användning
        if enable_caching:
            EnhancedFormBuilderService._schema_cache[form_template.id] = schema
        
        return form_template
    
    @staticmethod
    def get_project_templates_optimized(
        db: Session,
        project_id: str,
        active_only: bool = True,
        include_stats: bool = False,
        limit: Optional[int] = None
    ) -> List[FormTemplate]:
        """
        Optimerad template-hämtning med eager loading
        """
        query = db.query(FormTemplate).filter(FormTemplate.project_id == project_id)
        
        if active_only:
            query = query.filter(FormTemplate.is_active == True)
        
        if include_stats:
            # Eager load submission counts
            query = query.options(selectinload(FormTemplate.submissions))
        
        query = query.order_by(FormTemplate.created_at.desc())
        
        if limit:
            query = query.limit(limit)
        
        templates = query.all()
        
        # Lägg till submission statistics om efterfrågat
        if include_stats:
            template_ids = [t.id for t in templates]
            submission_counts = db.query(
                FlexibleFormSubmission.template_id,
                func.count(FlexibleFormSubmission.id).label('count')
            ).filter(
                FlexibleFormSubmission.template_id.in_(template_ids)
            ).group_by(FlexibleFormSubmission.template_id).all()
            
            count_dict = {sc.template_id: sc.count for sc in submission_counts}
            
            for template in templates:
                template.submission_count = count_dict.get(template.id, 0)
        
        return templates
    
    @staticmethod
    async def validate_submission_data_async(
        template: FormTemplate,
        data: Dict[str, Any],
        use_cache: bool = True
    ) -> Tuple[bool, Optional[List[str]]]:
        """
        Asynkron validation med caching
        """
        cache_key = f"{template.id}:{hash(json.dumps(data, sort_keys=True))}"
        
        if use_cache and cache_key in EnhancedFormBuilderService._validation_cache:
            cached_result = EnhancedFormBuilderService._validation_cache[cache_key]
            if cached_result['expires'] > datetime.utcnow():
                return cached_result['result']
        
        try:
            # Kör validation i thread pool för att inte blockera
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None,
                validate,
                data,
                template.schema
            )
            
            validation_result = (True, None)
            
        except ValidationError as e:
            errors = []
            
            def extract_errors(error, path=""):
                current_path = f"{path}.{error.path[0]}" if error.path else path
                current_path = current_path.lstrip(".")
                
                if error.context:
                    for sub_error in error.context:
                        extract_errors(sub_error, current_path)
                else:
                    error_msg = f"{current_path}: {error.message}" if current_path else error.message
                    errors.append(error_msg)
            
            extract_errors(e)
            validation_result = (False, errors)
            
        except Exception as e:
            validation_result = (False, [f"Schema validation error: {str(e)}"])
        
        # Cache resultatet i 5 minuter
        if use_cache:
            EnhancedFormBuilderService._validation_cache[cache_key] = {
                'result': validation_result,
                'expires': datetime.utcnow() + timedelta(minutes=5)
            }
        
        return validation_result
    
    @staticmethod
    async def create_batch_submissions(
        db: Session,
        template_id: str,
        submissions_data: List[Dict[str, Any]],
        batch_size: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Batch creation av submissions för hög prestanda
        """
        if len(submissions_data) > batch_size:
            raise ValueError(f"Batch size cannot exceed {batch_size}")
        
        # Hämta template en gång
        template = db.query(FormTemplate).filter(
            FormTemplate.id == template_id,
            FormTemplate.is_active == True
        ).first()
        
        if not template:
            raise ValueError("Form template not found or inactive")
        
        results = []
        successful_submissions = []
        
        try:
            # Validera alla submissions först
            validation_tasks = []
            for i, submission_data in enumerate(submissions_data):
                task = EnhancedFormBuilderService.validate_submission_data_async(
                    template, 
                    submission_data.get("data", {}),
                    use_cache=True
                )
                validation_tasks.append((i, task))
            
            # Kör alla validations parallellt
            validation_results = []
            for i, task in validation_tasks:
                is_valid, errors = await task
                validation_results.append((i, is_valid, errors))
            
            # Skapa submissions för valid data
            for i, is_valid, errors in validation_results:
                if not is_valid:
                    results.append({
                        "index": i,
                        "status": "error",
                        "errors": errors
                    })
                    continue
                
                submission_data = submissions_data[i]
                
                # Skapa submission
                submission = FlexibleFormSubmission(
                    template_id=template_id,
                    data=submission_data.get("data", {}),
                    submitted_by=submission_data.get("submitted_by"),
                    submitted_from_project=submission_data.get("submitted_from_project"),
                    submitted_from_ip=submission_data.get("ip_address"),
                    user_agent=submission_data.get("user_agent")
                )
                
                db.add(submission)
                successful_submissions.append((i, submission))
            
            # Commit alla på en gång
            db.commit()
            
            # Refresh alla submissions
            for i, submission in successful_submissions:
                db.refresh(submission)
                results.append({
                    "index": i,
                    "status": "success",
                    "submission_id": submission.id,
                    "submitted_at": submission.created_at.isoformat()
                })
            
            return results
            
        except Exception as e:
            db.rollback()
            raise ValueError(f"Batch submission failed: {str(e)}")
    
    @staticmethod
    def get_analytics_data(
        db: Session,
        project_id: Optional[str] = None,
        template_id: Optional[str] = None,
        days: int = 30
    ) -> Dict[str, Any]:
        """
        Hämta analytics data för dashboard
        """
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)
        
        # Base query
        submission_query = db.query(FlexibleFormSubmission).join(FormTemplate)
        
        # Filter by project or template
        if template_id:
            submission_query = submission_query.filter(FormTemplate.id == template_id)
        elif project_id:
            submission_query = submission_query.filter(FormTemplate.project_id == project_id)
        
        # Date filter
        submission_query = submission_query.filter(
            FlexibleFormSubmission.created_at >= start_date
        )
        
        # Calculate metrics
        total_submissions = submission_query.count()
        
        processed_submissions = submission_query.filter(
            FlexibleFormSubmission.is_processed == True
        ).count()
        
        # Daily submissions
        daily_stats = db.query(
            func.date(FlexibleFormSubmission.created_at).label('date'),
            func.count(FlexibleFormSubmission.id).label('count')
        ).join(FormTemplate).filter(
            FlexibleFormSubmission.created_at >= start_date
        )
        
        if template_id:
            daily_stats = daily_stats.filter(FormTemplate.id == template_id)
        elif project_id:
            daily_stats = daily_stats.filter(FormTemplate.project_id == project_id)
        
        daily_stats = daily_stats.group_by(
            func.date(FlexibleFormSubmission.created_at)
        ).order_by('date').all()
        
        return {
            "period_days": days,
            "total_submissions": total_submissions,
            "processed_submissions": processed_submissions,
            "completion_rate": (processed_submissions / total_submissions * 100) if total_submissions > 0 else 0,
            "avg_submissions_per_day": total_submissions / days if days > 0 else 0,
            "daily_submissions": [
                {"date": stat.date.isoformat(), "count": stat.count}
                for stat in daily_stats
            ]
        }
    
    @staticmethod
    def clear_caches():
        """Rensa alla cachers - användbart för testing"""
        EnhancedFormBuilderService._schema_cache.clear()
        EnhancedFormBuilderService._validation_cache.clear()
        EnhancedFormBuilderService.generate_json_schema_cached.cache_clear()
