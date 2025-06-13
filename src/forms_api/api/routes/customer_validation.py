"""
Customer validation router for Husqvarna Group API proxy
"""
from fastapi import APIRouter, HTTPException, Request, Query
from typing import Dict, Any, Optional
import httpx
import logging
import os

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Customer Validation"])

@router.get("/validate-customer")
async def validate_customer(
    customer_number: str = Query(..., description="Customer number to validate"),
    customer_code: str = Query("DOJ", description="Customer code (default: DOJ for EMEA)"),
    request: Request = None
) -> Dict[str, Any]:
    """
    Validate customer number against Husqvarna Group API
    
    This endpoint acts as a proxy to avoid CORS issues when calling external APIs
    from the frontend. It validates the customer number against Husqvarna Group's
    accounts API and returns validation status and account information.
    """
    
    # Input validation
    if not customer_number or len(customer_number) < 3:
        raise HTTPException(
            status_code=400,
            detail="Customer number must be at least 3 characters long"
        )
    
    # Get Husqvarna API configuration from environment
    husqvarna_api_base_url = os.getenv(
        'HUSQVARNA_API_BASE_URL', 
        'https://api-qa.integration.husqvarnagroup.com/hqw170/v1'
    )
    husqvarna_api_key = os.getenv(
        'HUSQVARNA_API_KEY', 
        '3d9c4d8a3c5c47f1a2a0ec096496a786'
    )
    
    if not husqvarna_api_key:
        logger.error("Husqvarna API key not configured")
        raise HTTPException(
            status_code=500,
            detail="API configuration error"
        )
    
    # Log the validation attempt
    logger.info(f"Validating customer {customer_number} with code {customer_code}")
    
    try:
        # Call Husqvarna Group API
        url = f"{husqvarna_api_base_url}/accounts"
        params = {
            "customerNumber": customer_number,
            "customerCode": customer_code
        }
        headers = {
            "Ocp-Apim-Subscription-Key": husqvarna_api_key,
            "Content-Type": "application/json"
        }
        
        logger.debug(f"Making request to {url} with params {params}")
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url, params=params, headers=headers)
            
        logger.debug(f"Husqvarna API response status: {response.status_code}")
        
        if response.status_code == 200:
            try:
                result = response.json()
                logger.debug(f"Husqvarna API response: {result}")
                
                if result.get("accountId"):
                    return {
                        "valid": True,
                        "source": "husqvarna_api",
                        "customer_number": customer_number,
                        "account_id": result["accountId"],
                        "customer_code": customer_code,
                        "message": f"✅ Kundnummer {customer_number} verifierat! (Account ID: {result['accountId'][:8]}...)"
                    }
                else:
                    return {
                        "valid": False,
                        "source": "husqvarna_api",
                        "customer_number": customer_number,
                        "customer_code": customer_code,
                        "message": f"❌ Kundnummer {customer_number} hittades inte i Husqvarna Group systemet"
                    }
                    
            except Exception as json_error:
                logger.error(f"Failed to parse Husqvarna API response: {json_error}")
                logger.error(f"Response content: {response.text}")
                raise HTTPException(
                    status_code=502,
                    detail="Invalid response from Husqvarna API"
                )
                
        elif response.status_code == 404:
            return {
                "valid": False,
                "source": "husqvarna_api",
                "customer_number": customer_number,
                "customer_code": customer_code,
                "message": f"❌ Kundnummer {customer_number} hittades inte i Husqvarna Group systemet"
            }
            
        else:
            logger.warning(f"Husqvarna API returned status {response.status_code}: {response.text}")
            # Fall back to basic format validation
            return await fallback_validation(customer_number, customer_code)
            
    except httpx.TimeoutException:
        logger.error("Timeout when calling Husqvarna API")
        return await fallback_validation(customer_number, customer_code)
        
    except httpx.RequestError as e:
        logger.error(f"Request error when calling Husqvarna API: {e}")
        return await fallback_validation(customer_number, customer_code)
        
    except Exception as e:
        logger.error(f"Unexpected error validating customer: {e}")
        return await fallback_validation(customer_number, customer_code)


async def fallback_validation(customer_number: str, customer_code: str) -> Dict[str, Any]:
    """
    Fallback validation using basic format checking
    """
    # Basic format validation
    is_valid_format = (
        len(customer_number) >= 3 and 
        len(customer_number) <= 20 and 
        customer_number.replace(" ", "").replace("-", "").isalnum()
    )
    
    if is_valid_format:
        return {
            "valid": True,
            "source": "format_validation",
            "customer_number": customer_number,
            "customer_code": customer_code,
            "message": f"🟡 Kundnummer {customer_number} har giltigt format (offline validering - ej verifierat)"
        }
    else:
        return {
            "valid": False,
            "source": "format_validation", 
            "customer_number": customer_number,
            "customer_code": customer_code,
            "message": f"❌ Ogiltigt kundnummer format: '{customer_number}'"
        }


@router.post("/validate-customer")
async def validate_customer_post(
    data: Dict[str, Any],
    request: Request = None
) -> Dict[str, Any]:
    """
    Alternative POST endpoint for customer validation
    Accepts JSON payload with customerNumber and optional customerCode
    """
    customer_number = data.get("customerNumber") or data.get("customer_number")
    customer_code = data.get("customerCode", "DOJ") or data.get("customer_code", "DOJ")
    
    if not customer_number:
        raise HTTPException(
            status_code=400,
            detail="customerNumber is required"
        )
    
    return await validate_customer(customer_number, customer_code, request)
