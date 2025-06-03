#!/bin/bash
# Script to verify Azure deployment by checking critical routes

# Set variables
SWA_URL="https://icy-flower-030d4ac03.6.azurestaticapps.net"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="deployment-verification.log"

echo "=== Azure SWA Deployment Verification - $TIMESTAMP ===" | tee -a $LOG_FILE
echo "Testing site: $SWA_URL" | tee -a $LOG_FILE

# Function to check a URL and report status
check_url() {
  local url=$1
  local description=$2
  local status
  local content
  
  echo -n "Checking $description ($url)... " | tee -a $LOG_FILE
  
  # Get the HTTP status code and content
  response=$(curl -s -w "%{http_code}" -o /tmp/curl_output.txt "$url")
  status=${response: -3}
  content=$(cat /tmp/curl_output.txt)
  
  # Check if status is 200 (OK)
  if [ "$status" -eq 200 ]; then
    echo "OK ($status)" | tee -a $LOG_FILE
    
    # Check if the response contains the root div
    if echo "$content" | grep -q '<div id="root"'; then
      echo "  - Found root div: YES" | tee -a $LOG_FILE
    else
      echo "  - Found root div: NO (ISSUE)" | tee -a $LOG_FILE
    fi
    
    # Check if any JavaScript files are loaded
    if echo "$content" | grep -q 'src="/assets/.*\.js"'; then
      echo "  - JavaScript files: LOADED" | tee -a $LOG_FILE
      echo "    $(echo "$content" | grep -o 'src="/assets/.*\.js"' | head -n 3 | tr '\n' ' ')" | tee -a $LOG_FILE
    else
      echo "  - JavaScript files: NOT FOUND (ISSUE)" | tee -a $LOG_FILE
    fi
  else
    echo "FAILED (status: $status)" | tee -a $LOG_FILE
  fi
  
  echo "" | tee -a $LOG_FILE
}

# Check main routes
check_url "$SWA_URL" "Root URL"
check_url "$SWA_URL/se" "Swedish route"
check_url "$SWA_URL/en" "English route"

# Check static assets
check_url "$SWA_URL/assets/index-BkqzeKwJ.js" "Main JS file"
check_url "$SWA_URL/assets/react-D7iOBXo6.js" "React JS file"
check_url "$SWA_URL/assets/index-H1xeC5UQ.css" "Main CSS file"

# Check if the fallbacks work
check_url "$SWA_URL/se/anything" "SE fallback route"
check_url "$SWA_URL/en/anything" "EN fallback route"

echo "Verification completed. See $LOG_FILE for details." | tee -a $LOG_FILE