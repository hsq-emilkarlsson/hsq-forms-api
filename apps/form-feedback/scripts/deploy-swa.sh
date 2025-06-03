#!/bin/bash

# Deploy Azure Static Web App using the SWA CLI
# Following Azure Static Web Apps best practices

set -e

echo "🚀 Starting Azure Static Web App deployment..."

# Navigate to the project directory
cd "$(dirname "$0")/.."

# Check if SWA CLI is installed
if ! command -v swa &> /dev/null; then
  echo "📦 Installing Azure Static Web Apps CLI..."
  npm install -g @azure/static-web-apps-cli
fi

# First run the verification script
echo "🧪 Running build verification..."
./scripts/verify-build.sh

if [ $? -ne 0 ]; then
  echo "❌ Build verification failed. Please fix the issues before deploying."
  exit 1
fi

# Get the Azure Static Web App name from environment or prompt
SWA_NAME=${SWA_NAME:-$(az staticwebapp list --query "[].name" -o tsv | fzf --prompt "Select Azure Static Web App: " || echo "")}

if [ -z "$SWA_NAME" ]; then
  echo "❌ No Azure Static Web App selected. Deployment aborted."
  exit 1
fi

echo "📤 Deploying to Azure Static Web App: $SWA_NAME"

# Deploy using SWA CLI (recommended best practice)
swa deploy ./dist \
  --app-name "$SWA_NAME" \
  --env production \
  --deployment-token $(az staticwebapp secrets list --name $SWA_NAME --query "properties.apiKey" -o tsv) \
  --verbose

# Verify deployment
echo "✅ Deployment complete!"
echo "Visit your site at: https://$(az staticwebapp show --name $SWA_NAME --query "defaultHostname" -o tsv)"
