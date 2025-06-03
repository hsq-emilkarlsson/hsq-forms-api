# Deploying Form Feedback App to Azure

This guide explains how to deploy the Form Feedback app to Azure using GitHub Actions.

## Automatic Deployments

The application is automatically deployed when:

1. Changes are pushed to the `main` branch that affect files in the `apps/form-feedback` directory
2. Pull requests are created or updated that change files in the `apps/form-feedback` directory

## Manual Deployment

To trigger a manual deployment:

1. Go to the GitHub repository
2. Navigate to "Actions" tab
3. Select the "Deploy Form Feedback App to Azure" workflow
4. Click on "Run workflow"
5. Select the "main" branch and the "production" environment
6. Click "Run workflow"

## Verifying Deployment

After deployment is complete:
1. Visit the app at https://icy-flower-030d4ac03.6.azurestaticapps.net
2. Check that you can navigate to both language paths (/se and /en)
3. If you encounter a white screen, press Ctrl+Alt+D to activate the debug panel

## Troubleshooting Common Issues

If you encounter issues with the deployment:

1. **White screen**: Check browser console for errors related to JavaScript loading
2. **404 errors on assets**: Verify that `staticwebapp.config.json` and `routes.json` properly configure MIME types
3. **Routing issues**: Verify that both `/se` and `/en` routes are configured in `staticwebapp.config.json`

## Development and Testing

Before pushing changes:

1. Test locally with `npm run dev`
2. Build locally with `npm run build`
3. Run the verification script: `./scripts/verify-build.sh`

This ensures that your changes will deploy successfully via GitHub Actions.
