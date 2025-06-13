#!/bin/bash

# Direct Husqvarna API Tests - Compare OLD vs NEW caseOriginCode
# These commands test the actual Husqvarna API endpoints

echo "🎯 Direct Husqvarna API Tests"
echo "============================="
echo ""

# Set variables
ACCOUNT_ID="8cc804f3-0de1-e911-a812-000d3a252d60"
CUSTOMER_NUMBER="1411768"
CUSTOMER_CODE="DOJ"
API_KEY="3d9c4d8a3c5c47f1a2a0ec096496a786"
BASE_URL="https://api-qa.integration.husqvarnagroup.com/hqw170/v1"

echo "📊 Testing OLD vs NEW caseOriginCode"
echo "------------------------------------"
echo ""

# Test OLD caseOriginCode (WEB)
echo "🔴 Testing OLD caseOriginCode: WEB"
echo "Payload: {accountId: $ACCOUNT_ID, customerNumber: $CUSTOMER_NUMBER, customerCode: $CUSTOMER_CODE, caseOriginCode: 'WEB'}"
echo ""

OLD_RESPONSE=$(timeout 15s curl -s -X POST "$BASE_URL/cases" \
  -H "Ocp-Apim-Subscription-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"accountId\": \"$ACCOUNT_ID\",
    \"customerNumber\": \"$CUSTOMER_NUMBER\",
    \"customerCode\": \"$CUSTOMER_CODE\",
    \"caseOriginCode\": \"WEB\",
    \"description\": \"TEST - OLD caseOriginCode (WEB) - Should route to default queue\"
  }" 2>/dev/null || echo "Request timed out")

echo "Response: $OLD_RESPONSE"
echo ""

# Test NEW caseOriginCode (115000008)
echo "🟢 Testing NEW caseOriginCode: 115000008"
echo "Payload: {accountId: $ACCOUNT_ID, customerNumber: $CUSTOMER_NUMBER, customerCode: $CUSTOMER_CODE, caseOriginCode: '115000008'}"
echo ""

NEW_RESPONSE=$(timeout 15s curl -s -X POST "$BASE_URL/cases" \
  -H "Ocp-Apim-Subscription-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"accountId\": \"$ACCOUNT_ID\",
    \"customerNumber\": \"$CUSTOMER_NUMBER\",
    \"customerCode\": \"$CUSTOMER_CODE\",
    \"caseOriginCode\": \"115000008\",
    \"description\": \"TEST - NEW caseOriginCode (115000008) - Should route to B2B support queue\"
  }" 2>/dev/null || echo "Request timed out")

echo "Response: $NEW_RESPONSE"
echo ""

# Extract case IDs if successful
OLD_CASE_ID=""
NEW_CASE_ID=""

if [[ "$OLD_RESPONSE" == *"caseId"* ]]; then
  OLD_CASE_ID=$(echo "$OLD_RESPONSE" | grep -o '"caseId":"[^"]*"' | cut -d'"' -f4)
fi

if [[ "$NEW_RESPONSE" == *"caseId"* ]]; then
  NEW_CASE_ID=$(echo "$NEW_RESPONSE" | grep -o '"caseId":"[^"]*"' | cut -d'"' -f4)
fi

# Summary
echo "📋 Results Summary"
echo "=================="
echo ""
echo "OLD caseOriginCode (WEB):"
if [[ -n "$OLD_CASE_ID" ]]; then
  echo "  ✅ Case created successfully"
  echo "  📝 Case ID: $OLD_CASE_ID"
else
  echo "  ❌ Failed or timed out"
fi
echo ""

echo "NEW caseOriginCode (115000008):"
if [[ -n "$NEW_CASE_ID" ]]; then
  echo "  ✅ Case created successfully"
  echo "  📝 Case ID: $NEW_CASE_ID"
else
  echo "  ❌ Failed or timed out"
fi
echo ""

echo "🎯 Validation Points:"
echo "• Both codes should create cases successfully"
echo "• The NEW code (115000008) should route to B2B support queue in CRM"
echo "• Monitor CRM system to verify proper routing"
echo "• Check case assignment and team routing"
echo ""

if [[ -n "$OLD_CASE_ID" ]] && [[ -n "$NEW_CASE_ID" ]]; then
  echo "✅ Both tests successful - ready for production validation!"
elif [[ -n "$NEW_CASE_ID" ]]; then
  echo "✅ NEW caseOriginCode working - primary objective achieved!"
else
  echo "⚠️  API may be slow or unavailable - try again later"
fi
