# Fixing Azure Static Web App White Screen Issue

This document explains the changes made to fix the "white screen" issue in the Husqvarna Feedback Form application deployed to Azure Static Web Apps.

## Root Cause

The primary issue was related to how the application was being bundled and served:

1. The HTML was referencing `/index.js` which was a custom entry point that tried to import `./src/main.tsx`
2. In production, browser was trying to load raw .tsx files, which isn't possible
3. Multiple configuration files (`routes.json` and `staticwebapp.config.json`) had conflicting route definitions
4. Explicit entry point was missing in Vite configuration

## Deployment Process

The application is deployed using GitHub Actions workflow (.github/workflows/deploy-form-feedback.yml) which:
1. Builds the application in CI environment
2. Runs verification checks on the build output
3. Deploys to Azure Static Web Apps using the official action

## Fixes Applied

### 1. Fixed Vite Configuration

Updated `vite.config.ts` to:
- Use a proper entry point (`index.html`)
- Consolidate and streamline build configuration 
- Ensure proper asset chunking and paths

### 2. Fixed HTML Structure

Modified `index.html` to:
- Use the standard entry point pattern (`/src/main.tsx`) that Vite expects
- Add debugging capabilities
- Fix script loading

### 3. Fixed Azure SWA Configuration

Updated `staticwebapp.config.json` and `routes.json` to:
- Properly handle asset routes for JavaScript and CSS files
- Ensure correct MIME types are set
- Properly route language-specific paths to the SPA

### 4. Added Debugging Tools

Added several debugging tools:
- Browser-side debugging script (`debug-client.js`) 
- Build verification script to catch issues before deployment
- Improved deployment script using SWA CLI best practices

## Future Maintenance

When updating the application, keep the following in mind:

1. **Entry Point**: Always keep the entry point as `/src/main.tsx` in `index.html`
2. **Local Verification**: Run `./scripts/verify-build.sh` locally before pushing changes
3. **GitHub Actions**: Changes are automatically deployed via the GitHub Actions workflow
4. **Debugging**: Press Ctrl+Alt+D in production to access the debug panel

## Deployment Verification

The GitHub Actions workflow has been enhanced with additional checks to prevent white screen issues:
1. Verifies JavaScript files exist in the build output
2. Confirms index.html references JS files correctly
3. Checks for proper MIME type configurations

## If Issues Persist

If white screen issues persist:
1. Open browser developer tools and check for errors
2. Use the built-in debug panel (Ctrl+Alt+D) 
3. Check network requests for 404s or MIME type issues
4. Verify route definitions in both config files
5. Review the GitHub Actions build logs for any warnings
