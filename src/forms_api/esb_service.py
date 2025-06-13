"""
Husqvarna ESB integration service.

This module handles customer validation and case creation through the Husqvarna ESB API.
"""

import logging
import httpx
from typing import Optional, Dict, Any
from .config import get_settings

logger = logging.getLogger(__name__)

class HusqvarnaESBService:
    """Service for integrating with Husqvarna ESB API."""
    
    def __init__(self):
        self.settings = get_settings()
        self.base_url = self.settings.husqvarna_esb_base_url
        self.api_key = self.settings.husqvarna_esb_api_key
        self.apac_codes = self.settings.husqvarna_esb_apac_codes_list
        
        if not self.api_key:
            logger.warning("Husqvarna ESB API key not configured")
    
    def _get_headers(self) -> Dict[str, str]:
        """Get HTTP headers for ESB API requests."""
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
    
    def _is_apac_customer(self, customer_code: str) -> bool:
        """Check if customer code should be routed to APAC."""
        return customer_code in self.apac_codes
    
    async def validate_customer(self, customer_number: str, customer_code: str = "DOJ") -> Optional[str]:
        """
        Validate customer number and return account ID if valid.
        
        Args:
            customer_number: Customer number to validate
            customer_code: Customer code (default: DOJ)
            
        Returns:
            str: Account ID if valid, None if invalid
            
        Raises:
            Exception: If API call fails
        """
        if not self.api_key:
            logger.error("ESB API key not configured")
            raise Exception("ESB integration not configured")
        
        url = f"{self.base_url}/accounts"
        params = {
            "customerNumber": customer_number,
            "customerCode": customer_code
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    url,
                    params=params,
                    headers=self._get_headers(),
                    timeout=30.0
                )
                
                logger.info(f"Customer validation response: {response.status_code}")
                
                if response.status_code == 200:
                    data = response.json()
                    account_id = data.get("accountId")
                    
                    if account_id:
                        logger.info(f"Customer {customer_number} validated successfully, account_id: {account_id}")
                        return account_id
                    else:
                        logger.info(f"Customer {customer_number} not found")
                        return None
                else:
                    logger.error(f"Customer validation failed: {response.status_code} - {response.text}")
                    response.raise_for_status()
                    
        except httpx.TimeoutException:
            logger.error("Customer validation timeout")
            raise Exception("Timeout while validating customer")
        except httpx.RequestError as e:
            logger.error(f"Customer validation request error: {e}")
            raise Exception("Network error during customer validation")
        except Exception as e:
            logger.error(f"Customer validation error: {e}")
            raise
    
    async def create_case(self, account_id: str, customer_number: str, customer_code: str, description: str) -> Dict[str, Any]:
        """
        Create a support case in ESB.
        
        Args:
            account_id: Account ID from customer validation
            customer_number: Customer number
            customer_code: Customer code
            description: Case description
            
        Returns:
            dict: ESB response data
            
        Raises:
            Exception: If case creation fails
        """
        if not self.api_key:
            logger.error("ESB API key not configured")
            raise Exception("ESB integration not configured")
        
        url = f"{self.base_url}/cases"
        payload = {
            "accountId": account_id,
            "customerNumber": customer_number,
            "customerCode": customer_code,
            "caseOriginCode": "115000008",
            "description": description
        }
        
        # Determine routing region
        region = "APAC" if self._is_apac_customer(customer_code) else "EMEA"
        logger.info(f"Creating case for customer {customer_number} in {region} region")
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    url,
                    json=payload,
                    headers=self._get_headers(),
                    timeout=30.0
                )
                
                logger.info(f"Case creation response: {response.status_code}")
                
                if response.status_code in [200, 201]:
                    data = response.json()
                    logger.info(f"Case created successfully: {data}")
                    return data
                else:
                    logger.error(f"Case creation failed: {response.status_code} - {response.text}")
                    response.raise_for_status()
                    
        except httpx.TimeoutException:
            logger.error("Case creation timeout")
            raise Exception("Timeout while creating case")
        except httpx.RequestError as e:
            logger.error(f"Case creation request error: {e}")
            raise Exception("Network error during case creation")
        except Exception as e:
            logger.error(f"Case creation error: {e}")
            raise


# Global service instance
esb_service = HusqvarnaESBService()
