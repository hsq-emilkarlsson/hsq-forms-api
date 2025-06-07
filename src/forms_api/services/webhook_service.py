"""
Webhook Service for HSQ Forms API

This module handles sending webhook notifications to configured endpoints 
when form submissions are created or updated.
"""

import json
import logging
import httpx
import asyncio
import hmac
import hashlib
from datetime import datetime
from typing import Dict, Any, List, Optional, Union

from src.forms_api.config import get_settings

logger = logging.getLogger(__name__)

class WebhookService:
    """Service for handling webhook notifications."""
    
    @staticmethod
    async def send_form_submission_webhook(
        event_type: str,
        form_data: Dict[str, Any],
        form_id: Optional[str] = None,
        template_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Send a webhook notification for a form submission event.
        
        Args:
            event_type: Type of event (e.g., "submission_created", "submission_updated")
            form_data: The form submission data
            form_id: ID of the form (for standard forms) or None for flexible forms
            template_id: ID of the template (for flexible forms) or None for standard forms
            
        Returns:
            List of response details from webhook endpoints
        """
        settings = get_settings()
        
        if not settings.webhooks_enabled:
            logger.debug("Webhooks disabled, skipping webhook notification")
            return []
        
        # Create the webhook payload
        payload = {
            "event_type": event_type,
            "timestamp": datetime.utcnow().isoformat(),
            "form_data": form_data
        }
        
        # Add form ID or template ID if provided
        if form_id:
            payload["form_id"] = form_id
            
        if template_id:
            payload["template_id"] = template_id
        
        # Get webhook URLs
        webhook_urls = settings.webhook_urls_list
        
        # Add form-specific webhook URL if configured
        form_specific_urls = []
        if form_id and form_id in settings.webhook_form_specific_config:
            form_specific_urls.append(settings.webhook_form_specific_config[form_id])
        elif template_id and template_id in settings.webhook_form_specific_config:
            form_specific_urls.append(settings.webhook_form_specific_config[template_id])
        
        # Combine all webhook URLs
        all_urls = webhook_urls + form_specific_urls
        
        if not all_urls:
            logger.debug("No webhook URLs configured, skipping webhook notification")
            return []
        
        # Send webhooks in parallel
        return await WebhookService._send_webhooks(all_urls, payload)
    
    @staticmethod
    async def _send_webhooks(
        urls: List[str], 
        payload: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """
        Send webhook notifications to multiple URLs in parallel.
        
        Args:
            urls: List of webhook URLs
            payload: The webhook payload
            
        Returns:
            List of response details
        """
        settings = get_settings()
        results = []
        
        # Create tasks for sending webhooks
        tasks = []
        for url in urls:
            if not url:  # Skip empty URLs
                continue
                
            task = WebhookService._send_single_webhook(url, payload, settings.webhook_secret)
            tasks.append(task)
        
        # Execute tasks in parallel
        if tasks:
            webhook_results = await asyncio.gather(*tasks, return_exceptions=True)
            results.extend(webhook_results)
        
        return [r for r in results if r]  # Filter None results
    
    @staticmethod
    async def _send_single_webhook(
        url: str, 
        payload: Dict[str, Any],
        secret: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Send a webhook to a single URL.
        
        Args:
            url: The webhook URL
            payload: The webhook payload
            secret: Optional secret for signing the request
            
        Returns:
            Response details or None if failed
        """
        try:
            headers = {"Content-Type": "application/json"}
            payload_json = json.dumps(payload)
            
            # Sign the payload if a secret is provided
            if secret:
                signature = WebhookService._generate_signature(payload_json, secret)
                headers["X-Webhook-Signature"] = signature
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, content=payload_json, headers=headers)
                
                return {
                    "url": url,
                    "status_code": response.status_code,
                    "success": 200 <= response.status_code < 300,
                    "response": response.text if response.text else None
                }
                
        except Exception as e:
            logger.error(f"Error sending webhook to {url}: {str(e)}")
            return {
                "url": url,
                "success": False,
                "error": str(e)
            }
    
    @staticmethod
    def _generate_signature(payload: str, secret: str) -> str:
        """
        Generate a HMAC signature for the webhook payload.
        
        Args:
            payload: The JSON payload as a string
            secret: The secret key for signing
            
        Returns:
            The HMAC signature as a hex string
        """
        return hmac.new(
            secret.encode('utf-8'),
            payload.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
