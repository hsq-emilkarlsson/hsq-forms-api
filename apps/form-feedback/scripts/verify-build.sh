#!/bin/bash

# Verify that the Vite build is correctly configured
echo "Verifying production build..."

# Navigate to the project directory
cd "$(dirname "$0")/.."

# Clean the dist directory
rm -rf dist

# Run the build
npm run build

# Check if the build was successful
if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  exit 1
fi

echo "✅ Build completed successfully!"

# Check for the main JavaScript file in the dist directory
if ls dist/assets/main-*.js >/dev/null 2>&1; then
  echo "✅ Found bundled JavaScript file"
else
  if ls dist/assets/index-*.js >/dev/null 2>&1; then
    echo "✅ Found bundled JavaScript file (named index-*.js)"
  else
    echo "❌ Could not find bundled JavaScript file in dist/assets/"
    ls -la dist/assets/
    exit 1
  fi
fi

# Check that index.html references the correct JavaScript
if grep -q "src=\"/assets/main-" dist/index.html || grep -q "src=\"/assets/index-" dist/index.html; then
  echo "✅ index.html correctly references JavaScript assets"
else
  echo "❌ index.html does not reference bundled JavaScript assets correctly"
  echo "Current script tag in index.html:"
  grep -n "script" dist/index.html
  exit 1
fi

echo "✅ Build verification complete!"
echo "Ready for deployment to Azure Static Web Apps"
