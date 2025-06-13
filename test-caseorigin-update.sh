#!/bin/bash

echo "🧪 Testing B2B Support Form with Updated caseOriginCode (115000008)"
echo "=================================================================="

# Test data
CUSTOMER_NUMBER="1411768"
CUSTOMER_CODE="DOJ"
DESCRIPTION="Test submission med nya caseOriginCode från terminal"

echo ""
echo "📋 Test data:"
echo "  - Customer Number: $CUSTOMER_NUMBER"
echo "  - Customer Code: $CUSTOMER_CODE"
echo "  - Expected caseOriginCode: 115000008"
echo ""

# Test 1: Direct JavaScript API call (simulating frontend)
echo "🔄 Test 1: Simulerar frontend API-anrop..."

# Create test payload
TEST_PAYLOAD='{
  "customerNumber": "'$CUSTOMER_NUMBER'",
  "customerCode": "'$CUSTOMER_CODE'",
  "description": "'$DESCRIPTION'",
  "companyName": "Test Company AB",
  "contactPerson": "Test Person",
  "email": "test@example.com",
  "phone": "+46701234567",
  "supportType": "technical",
  "subject": "caseOriginCode update test",
  "urgency": "medium"
}'

# Show payload with caseOriginCode
echo "📤 Sending payload (frontend skulle skicka detta):"
echo "$TEST_PAYLOAD" | jq .

echo ""
echo "🔍 Checking that caseOriginCode 115000008 is used in mock service..."

# Test with Python direct call
python3 -c "
import asyncio
import json
import sys
sys.path.append('src')

async def simulate_frontend_submission():
    from forms_api.mock_esb_service import mock_esb_service
    
    print('Simulating complete frontend submission flow:')
    print('=' * 50)
    
    # Step 1: Validate customer (like frontend does)
    account_id = await mock_esb_service.validate_customer('$CUSTOMER_NUMBER', '$CUSTOMER_CODE')
    if account_id:
        print(f'✅ Customer validation: SUCCESS (Account ID: {account_id})')
        
        # Step 2: Create case (like backend does)
        case_result = await mock_esb_service.create_case(
            account_id=account_id,
            customer_number='$CUSTOMER_NUMBER',
            customer_code='$CUSTOMER_CODE',
            description='$DESCRIPTION'
        )
        
        print(f'📝 Case creation result:')
        print(json.dumps(case_result, indent=2))
        
        # Step 3: Verify caseOriginCode
        expected_code = '115000008'
        actual_code = case_result.get('caseOriginCode')
        
        if actual_code == expected_code:
            print(f'\\n✅ SUCCESS: caseOriginCode korrekt = {actual_code}')
            print('🎯 B2B formuläret kommer att skapa cases med rätt routing!')
        else:
            print(f'\\n❌ FAIL: caseOriginCode = {actual_code}, förväntade {expected_code}')
    else:
        print('❌ Customer validation failed')

asyncio.run(simulate_frontend_submission())
"

echo ""
echo "🌐 Frontend URL: http://localhost:3003"
echo "📋 Du kan nu testa formuläret manuellt i webbläsaren"
echo ""
echo "🏁 Test completed! Check results above for caseOriginCode verification."
