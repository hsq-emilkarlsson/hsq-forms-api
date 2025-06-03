#!/bin/bash

# This script updates the timestamp in a file and commits it to trigger a new deployment via GitHub Actions
# Run this script when you want to force a new deployment without changing any code

# Navigate to the project directory
cd "$(dirname "$0")/.."

# Create or update the timestamp file
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
echo "Last updated: $TIMESTAMP" > .deployment-trigger

# Commit and push the changes
git add .deployment-trigger
git commit -m "trigger deployment: $TIMESTAMP"
git push origin main

echo "Deployment triggered. Check GitHub Actions for progress."
