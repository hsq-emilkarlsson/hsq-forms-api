# Quick ESB Test Commands
# Copy and paste these commands in your terminal for quick testing

# 1. Test Customer Validation via Backend Proxy
echo "🔍 Testing Customer Validation via Backend Proxy..."
curl -s "http://localhost:8000/api/husqvarna/validate-customer?customer_number=1411768&customer_code=DOJ" | jq '.'

# 2. Test Customer Validation via ESB endpoint
echo -e "\n🔍 Testing Customer Validation via ESB endpoint..."
curl -s -X POST "http://localhost:8000/api/esb/validate-customer" \
  -H "Content-Type: application/json" \
  -d '{"customer_number": "1411768", "customer_code": "DOJ"}' | jq '.'

# 3. Test NEW caseOriginCode (115000008) - Direct Husqvarna API
echo -e "\n🆕 Testing NEW caseOriginCode (115000008)..."
curl -s -X POST "https://api-qa.integration.husqvarnagroup.com/hqw170/v1/cases" \
  -H "Ocp-Apim-Subscription-Key: 3d9c4d8a3c5c47f1a2a0ec096496a786" \
  -H "Content-Type: application/json" \
  -d '{
    "accountId": "8cc804f3-0de1-e911-a812-000d3a252d60",
    "customerNumber": "1411768",
    "customerCode": "DOJ",
    "caseOriginCode": "115000008",
    "description": "TEST: New caseOriginCode 115000008 for proper CRM routing - Terminal Test"
  }' | jq '.'

# 4. Test OLD caseOriginCode (WEB) for comparison
echo -e "\n🔴 Testing OLD caseOriginCode (WEB) for comparison..."
curl -s -X POST "https://api-qa.integration.husqvarnagroup.com/hqw170/v1/cases" \
  -H "Ocp-Apim-Subscription-Key: 3d9c4d8a3c5c47f1a2a0ec096496a786" \
  -H "Content-Type: application/json" \
  -d '{
    "accountId": "8cc804f3-0de1-e911-a812-000d3a252d60",
    "customerNumber": "1411768",
    "customerCode": "DOJ",
    "caseOriginCode": "WEB",
    "description": "TEST: Old caseOriginCode WEB for comparison - Terminal Test"
  }' | jq '.'

# 5. Test Backend ESB B2B Support endpoint
echo -e "\n🏗️ Testing Backend ESB B2B Support endpoint..."
curl -s -X POST "http://localhost:8000/api/esb/b2b-support" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_number": "1411768",
    "customer_code": "DOJ",
    "description": "TEST: Backend ESB B2B support with caseOriginCode 115000008 - Terminal Test",
    "company_name": "Terminal Test Company",
    "contact_person": "Emil Karlsson",
    "email": "emil@test.se",
    "phone": "+46701234567",
    "support_type": "technical",
    "subject": "Terminal Test - caseOriginCode 115000008",
    "urgency": "medium"
  }' | jq '.'

# 6. Test Form Template Submission
echo -e "\n📋 Testing Form Template Submission..."
curl -s -X POST "http://localhost:8000/api/templates/958915ec-fed1-4e7e-badd-4598502fe6a1/submit" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "companyName": "Terminal Test Company",
      "contactPerson": "Emil Karlsson",
      "customerNumber": "1411768",
      "email": "emil@test.se",
      "phone": "+46701234567",
      "subject": "Terminal Test - caseOriginCode 115000008",
      "supportType": "technical",
      "problemDescription": "Testing new caseOriginCode from terminal",
      "urgency": "medium",
      "language": "sv"
    },
    "metadata": {
      "source": "terminal-test",
      "customerValidated": true,
      "accountId": "8cc804f3-0de1-e911-a812-000d3a252d60"
    }
  }' | jq '.'
