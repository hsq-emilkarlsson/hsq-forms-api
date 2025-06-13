"""
Mock ESB service for testing customer validation functionality.
This service simulates the Husqvarna ESB API for demonstration purposes.
"""

import logging
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

class MockHusqvarnaESBService:
    """Mock service for testing ESB integration without external API calls."""
    
    def __init__(self):
        # Mock customer database for testing
        self.mock_customers = {
            "1411768": {"account_id": "8cc804f3-0de1-e911-a812-000d3a252d60", "customer_code": "DOJ"},
            "123456": {"account_id": "9dd905f4-1ea2-f922-b923-111e4a363e71", "customer_code": "DOJ"},
            "999999": {"account_id": "7bb703e2-0dc0-e800-a701-000c2a141c50", "customer_code": "DOJ"},
        }
        
    async def validate_customer(self, customer_number: str, customer_code: str = "DOJ") -> Optional[str]:
        """
        Mock customer validation.
        
        Args:
            customer_number: Customer number to validate
            customer_code: Customer code (default: DOJ)
            
        Returns:
            str: Account ID if valid, None if invalid
        """
        logger.info(f"Mock: Validating customer {customer_number} with code {customer_code}")
        
        # Simulate processing delay
        await self._simulate_delay()
        
        # Check mock database
        customer_data = self.mock_customers.get(customer_number)
        if customer_data and customer_data["customer_code"] == customer_code:
            account_id = customer_data["account_id"]
            logger.info(f"Mock: Customer {customer_number} validated successfully, account_id: {account_id}")
            return account_id
        else:
            logger.info(f"Mock: Customer {customer_number} not found in mock database")
            return None
    
    async def create_case(self, account_id: str, customer_number: str, customer_code: str, description: str) -> Dict[str, Any]:
        """
        Mock case creation.
        
        Args:
            account_id: Account ID from customer validation
            customer_number: Customer number
            customer_code: Customer code
            description: Case description
            
        Returns:
            dict: Mock ESB response data
        """
        logger.info(f"Mock: Creating case for customer {customer_number} with account {account_id}")
        
        # Simulate processing delay
        await self._simulate_delay()
        
        # Generate mock case ID
        import uuid
        case_id = f"CASE-{uuid.uuid4().hex[:8].upper()}"
        
        # Determine routing region
        region = "APAC" if customer_code in ["CODE1", "CODE2"] else "EMEA"
        
        mock_response = {
            "caseId": case_id,
            "status": "created",
            "region": region,
            "accountId": account_id,
            "customerNumber": customer_number,
            "customerCode": customer_code,
            "caseOriginCode": "115000008",
            "description": description,
            "createdAt": "2025-06-10T15:30:00Z"
        }
        
        logger.info(f"Mock: Case created successfully: {mock_response}")
        return mock_response
    
    async def _simulate_delay(self):
        """Simulate API response delay."""
        import asyncio
        await asyncio.sleep(0.5)  # 500ms delay


# Global mock service instance for testing
mock_esb_service = MockHusqvarnaESBService()
