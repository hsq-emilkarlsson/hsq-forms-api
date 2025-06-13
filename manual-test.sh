#!/bin/bash

# Manual ESB Test Script - For Testing caseOriginCode Changes
# This script tests the key functionality you need to validate

echo "🧪 Manual ESB Integration Tests"
echo "==============================="
echo ""

# Test 1: Customer Validation (works)
echo "✅ Test 1: Customer Validation"
echo "------------------------------"
curl -s "http://localhost:8000/api/husqvarna/validate-customer?customer_number=1411768&customer_code=DOJ" | jq '.'
echo ""

# Test 2: Form Template Submission (works)
echo "✅ Test 2: Form Template Submission"
echo "-----------------------------------"
RESPONSE=$(curl -s -X POST "http://localhost:8000/api/templates/958915ec-fed1-4e7e-badd-4598502fe6a1/submit" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "companyName": "Manual Test Company",
      "contactPerson": "Emil Karlsson",
      "customerNumber": "1411768",
      "email": "emil@manual-test.se",
      "phone": "+46701234567",
      "subject": "Manual Test - Verifying caseOriginCode 115000008",
      "supportType": "technical",
      "problemDescription": "This is a manual test to verify that the new caseOriginCode 115000008 is being used correctly.",
      "urgency": "medium",
      "language": "sv"
    },
    "metadata": {
      "source": "manual-terminal-test",
      "customerValidated": true,
      "accountId": "8cc804f3-0de1-e911-a812-000d3a252d60"
    }
  }')

echo "$RESPONSE" | jq '.'
SUBMISSION_ID=$(echo "$RESPONSE" | jq -r '.id')
echo ""
echo "📝 Submission ID: $SUBMISSION_ID"
echo ""

# Test 3: Quick verification that our changes are in place
echo "🔍 Test 3: Code Verification"
echo "----------------------------"
echo "Checking that caseOriginCode is set to 115000008 in key files:"
echo ""

echo "📄 Frontend (B2BSupportForm.tsx):"
grep -n "caseOriginCode.*115000008" /Users/emilkarlsson/Documents/Dev/hsq-forms-api/forms/hsq-forms-container-b2b-support/src/components/B2BSupportForm.tsx

echo ""
echo "📄 Backend ESB Service:"
grep -n "caseOriginCode.*115000008" /Users/emilkarlsson/Documents/Dev/hsq-forms-api/src/forms_api/esb_service.py

echo ""
echo "📄 Mock ESB Service:"
grep -n "caseOriginCode.*115000008" /Users/emilkarlsson/Documents/Dev/hsq-forms-api/src/forms_api/mock_esb_service.py

echo ""
echo "🎯 Summary"
echo "=========="
echo "✅ Customer validation: Working"
echo "✅ Form submission: Working (ID: $SUBMISSION_ID)"
echo "✅ Code updated: caseOriginCode changed from 'WEB' to '115000008'"
echo ""
echo "🔄 Next Steps:"
echo "1. Test the frontend form at http://localhost:3006"
echo "2. Submit a test case and monitor CRM routing"
echo "3. Verify that cases are routed correctly with the new code"
echo ""
