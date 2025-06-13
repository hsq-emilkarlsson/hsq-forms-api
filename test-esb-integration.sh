#!/bin/bash

# ESB Integration Test Script
# Tests different scenarios for the B2B Support Form ESB integration

# Configuration
BACKEND_URL="http://localhost:8000"
HUSQVARNA_API_BASE="https://api-qa.integration.husqvarnagroup.com/hqw170/v1"
HUSQVARNA_API_KEY="3d9c4d8a3c5c47f1a2a0ec096496a786"
TEMPLATE_ID="958915ec-fed1-4e7e-badd-4598502fe6a1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 ESB Integration Test Suite${NC}"
echo -e "${BLUE}=================================${NC}"
echo ""

# Test 1: Customer Validation via Backend Proxy
echo -e "${YELLOW}📋 Test 1: Customer Validation (Backend Proxy)${NC}"
echo -e "${YELLOW}-----------------------------------------------${NC}"

CUSTOMER_NUMBER="1411768"
CUSTOMER_CODE="DOJ"

echo "Testing customer validation for: $CUSTOMER_NUMBER with code: $CUSTOMER_CODE"
echo "API URL: $BACKEND_URL/api/husqvarna/validate-customer"

VALIDATION_RESPONSE=$(curl -s -X GET \
  "$BACKEND_URL/api/husqvarna/validate-customer?customer_number=$CUSTOMER_NUMBER&customer_code=$CUSTOMER_CODE" \
  -H "Content-Type: application/json")

echo -e "Response: ${GREEN}$VALIDATION_RESPONSE${NC}"
echo ""

# Extract account_id for use in subsequent tests
ACCOUNT_ID=$(echo $VALIDATION_RESPONSE | grep -o '"account_id":"[^"]*"' | cut -d'"' -f4)
echo -e "Extracted Account ID: ${GREEN}$ACCOUNT_ID${NC}"
echo ""

# Test 2: Form Submission via Template API
echo -e "${YELLOW}📋 Test 2: Form Submission (Template API)${NC}"
echo -e "${YELLOW}----------------------------------------${NC}"

FORM_DATA='{
  "data": {
    "companyName": "Test Company AB",
    "contactPerson": "Emil Karlsson",
    "customerNumber": "'$CUSTOMER_NUMBER'",
    "email": "emil.karlsson@testcompany.se",
    "phone": "+46701234567",
    "subject": "Test Case - caseOriginCode 115000008",
    "supportType": "technical",
    "pncNumber": "967123456",
    "serialNumber": "ABC123456",
    "problemDescription": "Testing the new caseOriginCode implementation for proper CRM routing. This is a test submission to verify that cases are routed correctly with code 115000008.",
    "urgency": "medium",
    "language": "sv"
  },
  "metadata": {
    "source": "esb-integration-test",
    "customerValidated": true,
    "accountId": "'$ACCOUNT_ID'"
  }
}'

echo "Submitting form via Template API..."
echo "Template ID: $TEMPLATE_ID"
echo "Payload:"
echo "$FORM_DATA" | jq '.' 2>/dev/null || echo "$FORM_DATA"
echo ""

FORM_RESPONSE=$(curl -s -X POST \
  "$BACKEND_URL/api/templates/$TEMPLATE_ID/submit" \
  -H "Content-Type: application/json" \
  -d "$FORM_DATA")

echo -e "Form Submission Response: ${GREEN}$FORM_RESPONSE${NC}"
echo ""

# Test 3: Direct Husqvarna Cases API Call
echo -e "${YELLOW}📋 Test 3: Direct Husqvarna Cases API Call${NC}"
echo -e "${YELLOW}------------------------------------------${NC}"

CASES_PAYLOAD='{
  "accountId": "'$ACCOUNT_ID'",
  "customerNumber": "'$CUSTOMER_NUMBER'",
  "customerCode": "'$CUSTOMER_CODE'",
  "caseOriginCode": "115000008",
  "description": "Test Case - Direct API Call\n\nSubject: Testing caseOriginCode 115000008\nType: technical\nUrgency: medium\n\nDescription:\nThis is a direct API test to verify that caseOriginCode 115000008 is properly processed by the Husqvarna Cases API and routes correctly in the CRM system.\n\nPNC: 967123456\nSerial: ABC123456\n\nContact: Emil Karlsson (emil.karlsson@testcompany.se) - +46701234567\nCompany: Test Company AB"
}'

echo "Calling Husqvarna Cases API directly..."
echo "API URL: $HUSQVARNA_API_BASE/cases"
echo "Payload:"
echo "$CASES_PAYLOAD" | jq '.' 2>/dev/null || echo "$CASES_PAYLOAD"
echo ""

CASES_RESPONSE=$(curl -s -X POST \
  "$HUSQVARNA_API_BASE/cases" \
  -H "Ocp-Apim-Subscription-Key: $HUSQVARNA_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$CASES_PAYLOAD")

echo -e "Husqvarna Cases API Response: ${GREEN}$CASES_RESPONSE${NC}"
echo ""

# Test 4: Backend ESB Service Call
echo -e "${YELLOW}📋 Test 4: Backend ESB Service Call${NC}"
echo -e "${YELLOW}----------------------------------${NC}"

ESB_PAYLOAD='{
  "account_id": "'$ACCOUNT_ID'",
  "customer_number": "'$CUSTOMER_NUMBER'",
  "customer_code": "'$CUSTOMER_CODE'",
  "description": "Test Case - Backend ESB Service\n\nSubject: Testing backend ESB integration with caseOriginCode 115000008\nType: technical\nUrgency: medium\n\nDescription:\nThis test verifies that the backend ESB service correctly sends caseOriginCode 115000008 for proper CRM routing.\n\nPNC: 967123456\nSerial: ABC123456\n\nContact: Emil Karlsson (emil.karlsson@testcompany.se) - +46701234567\nCompany: Test Company AB"
}'

echo "Calling backend ESB service..."
echo "API URL: $BACKEND_URL/api/esb/create-case"
echo "Payload:"
echo "$ESB_PAYLOAD" | jq '.' 2>/dev/null || echo "$ESB_PAYLOAD"
echo ""

ESB_RESPONSE=$(curl -s -X POST \
  "$BACKEND_URL/api/esb/create-case" \
  -H "Content-Type: application/json" \
  -d "$ESB_PAYLOAD")

echo -e "Backend ESB Response: ${GREEN}$ESB_RESPONSE${NC}"
echo ""

# Test 5: Compare OLD vs NEW caseOriginCode
echo -e "${YELLOW}📋 Test 5: Comparison Test (OLD vs NEW caseOriginCode)${NC}"
echo -e "${YELLOW}----------------------------------------------------${NC}"

echo "Testing OLD caseOriginCode: WEB"
OLD_PAYLOAD='{
  "accountId": "'$ACCOUNT_ID'",
  "customerNumber": "'$CUSTOMER_NUMBER'",
  "customerCode": "'$CUSTOMER_CODE'",
  "caseOriginCode": "WEB",
  "description": "Test Case - OLD caseOriginCode WEB for comparison"
}'

OLD_RESPONSE=$(curl -s -X POST \
  "$HUSQVARNA_API_BASE/cases" \
  -H "Ocp-Apim-Subscription-Key: $HUSQVARNA_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$OLD_PAYLOAD")

echo -e "OLD (WEB) Response: ${RED}$OLD_RESPONSE${NC}"
echo ""

echo "Testing NEW caseOriginCode: 115000008"
NEW_PAYLOAD='{
  "accountId": "'$ACCOUNT_ID'",
  "customerNumber": "'$CUSTOMER_NUMBER'",
  "customerCode": "'$CUSTOMER_CODE'",
  "caseOriginCode": "115000008",
  "description": "Test Case - NEW caseOriginCode 115000008 for comparison"
}'

NEW_RESPONSE=$(curl -s -X POST \
  "$HUSQVARNA_API_BASE/cases" \
  -H "Ocp-Apim-Subscription-Key: $HUSQVARNA_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$NEW_PAYLOAD")

echo -e "NEW (115000008) Response: ${GREEN}$NEW_RESPONSE${NC}"
echo ""

# Summary
echo -e "${BLUE}📊 Test Summary${NC}"
echo -e "${BLUE}===============${NC}"
echo "1. Customer Validation: $(echo $VALIDATION_RESPONSE | grep -q 'valid.*true' && echo -e '${GREEN}✅ PASS${NC}' || echo -e '${RED}❌ FAIL${NC}')"
echo "2. Form Submission: $(echo $FORM_RESPONSE | grep -q 'success' && echo -e '${GREEN}✅ PASS${NC}' || echo -e '${RED}❌ FAIL${NC}')"
echo "3. Husqvarna Cases API: $(echo $CASES_RESPONSE | grep -q 'caseId\|id' && echo -e '${GREEN}✅ PASS${NC}' || echo -e '${RED}❌ FAIL${NC}')"
echo "4. Backend ESB Service: $(echo $ESB_RESPONSE | grep -q 'caseId\|success' && echo -e '${GREEN}✅ PASS${NC}' || echo -e '${RED}❌ FAIL${NC}')"
echo ""
echo -e "${BLUE}🎯 Key Validation Points:${NC}"
echo "- Check if NEW caseOriginCode (115000008) produces different routing than OLD (WEB)"
echo "- Verify case IDs are generated successfully"
echo "- Monitor CRM system for proper case routing"
echo ""
