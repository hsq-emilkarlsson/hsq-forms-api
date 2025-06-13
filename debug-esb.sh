#!/bin/bash

# ESB Debug Test Script
# För att felsöka ESB endpoint-problem

echo "=== ESB DEBUG TESTING ==="
echo "Datum: $(date)"
echo

# Test 1: Basic health check
echo "1. Testing server health..."
curl -X GET "http://localhost:8000/health" --max-time 5
echo -e "\n"

# Test 2: Husqvarna API (working baseline)
echo "2. Testing Husqvarna API (baseline)..."
curl -X GET "http://localhost:8000/api/husqvarna/validate-customer?customer_number=1411768&customer_code=DOJ" --max-time 10
echo -e "\n"

# Test 3: ESB validation (simpler endpoint)
echo "3. Testing ESB validation endpoint..."
curl -X POST "http://localhost:8000/api/esb/validate-customer" \
  -H "Content-Type: application/json" \
  -d '{"customer_number": "1411768", "customer_code": "DOJ"}' \
  --max-time 15 || echo "ESB validation timeout"
echo -e "\n"

# Test 4: ESB B2B Support (problematic endpoint)
echo "4. Testing ESB B2B Support (with minimal data)..."
curl -X POST "http://localhost:8000/api/esb/b2b-support" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_number": "1411768",
    "customer_code": "DOJ",
    "subject": "Debug Test",
    "description": "Minimal test case",
    "contact_name": "Test",
    "contact_email": "test@test.com",
    "contact_phone": "123",
    "issue_type": "general"
  }' \
  --max-time 20 || echo "ESB B2B Support timeout"
echo -e "\n"

echo "=== ESB DEBUG COMPLETE ==="
echo "Check logs at: logs/forms_api.log"
