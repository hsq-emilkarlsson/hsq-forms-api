# Azure Static Web App Deployment Guide for HSQ Form Template

This guide provides step-by-step instructions for deploying the HSQ Forms template to Azure Static Web Apps. Azure Static Web Apps is a service that automatically builds and deploys full-stack web apps to Azure from a GitHub repository.

## Prerequisites

1. An Azure account with an active subscription
2. Your form template code in a GitHub repository
3. Visual Studio Code with the Azure Static Web Apps extension (recommended)

## Deployment Options

You can deploy this application to Azure Static Web Apps using one of these methods:

1. **Azure Portal** - Manual deployment using the Azure Portal
2. **GitHub Actions** - Automated CI/CD deployment using the provided workflow
3. **Azure Static Web Apps CLI** - Local development and deployment

## Method 1: Deploy using Azure Portal

1. Log in to the [Azure Portal](https://portal.azure.com/)

2. Search for "Static Web Apps" and select the service

3. Click on "Create static web app"

4. Fill in the basic details:
   - **Subscription:** Select your subscription
   - **Resource Group:** Create new or select existing
   - **Name:** Enter a name for your application (e.g., `hsq-form-app`)
   - **Region:** Select the region closest to your users
   - **SKU:** Select Free or Standard based on your needs

5. Configure deployment source:
   - **Deployment source:** Select GitHub
   - **Sign in with GitHub** and authorize Azure Static Web Apps
   - Select your **Organization**, **Repository**, and **Branch**

6. Configure build settings:
   - **Build Presets:** Select "React"
   - **App location:** `/` (root of repository)
   - **Api location:** Leave empty
   - **Output location:** `dist`

7. Click "Review + create" then "Create"

Azure will automatically set up a GitHub Action in your repository, which will build and deploy your application.

## Method 2: Deploy using GitHub Actions (CI/CD)

A GitHub Actions workflow file is already included in the template at `.github/workflows/azure-static-web-apps-ci-cd.yml`.

1. Set up your GitHub repository secrets:
   - Go to your repository → Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `VITE_API_URL`: Your API URL (e.g., `https://your-api.azurewebsites.net/api`)
     - `VITE_API_KEY`: Your API key (if required)
     - `VITE_FORM_ID`: The form ID to use (e.g., `contact-form`)
     - `VITE_FORM_NAME`: Display name for your form
     - `VITE_FORM_DESCRIPTION`: Description text for your form

2. Create the Static Web App in Azure:
   - Follow steps 1-7 from Method 1
   - Azure will automatically create and trigger the GitHub Action

3. Any future pushes to your main branch will trigger automatic builds and deployments.

## Method 3: Using Azure Static Web Apps CLI

For local development and testing with Azure Static Web Apps:

1. Install the Azure Static Web Apps CLI:
   ```bash
   npm install -g @azure/static-web-apps-cli
   ```

2. Build your application:
   ```bash
   npm run build
   ```

3. Run the application locally using the CLI:
   ```bash
   swa start dist --api-location ""
   ```

4. Deploy to Azure:
   ```bash
   swa deploy dist --env production --deployment-token <your-deployment-token>
   ```
   
   Note: You can get the deployment token from your Static Web App in the Azure Portal under "Overview" → "Manage deployment token"

## Configuring Environment Variables

Azure Static Web Apps allows you to configure environment variables in several ways:

### Option 1: Using the Azure Portal

1. Go to your Static Web App in the Azure Portal
2. Navigate to "Configuration" under "Settings"
3. Add your application settings:
   - `VITE_API_URL`
   - `VITE_API_KEY`
   - `VITE_FORM_ID`
   - `VITE_FORM_NAME`
   - `VITE_FORM_DESCRIPTION`

### Option 2: Using GitHub Actions Secrets

Add the variables to your GitHub repository secrets, as shown in Method 2.

## Custom Domain Configuration

To use a custom domain with your Static Web App:

1. In Azure Portal, go to your Static Web App resource
2. Navigate to "Custom domains" under "Settings"
3. Click "Add" and follow the instructions for your domain registrar
4. Options include:
   - Using an Azure DNS zone
   - Using an external DNS provider

## Staging Environments

Azure Static Web Apps automatically creates staging environments for pull requests:

1. When a pull request is opened against your main branch, a staging environment is created
2. The environment URL is commented on the PR automatically
3. When the PR is closed, the staging environment is deleted

## Monitoring and Logs

To monitor your Static Web App:

1. In Azure Portal, go to your Static Web App resource
2. Navigate to "Monitoring" section
3. Check "Logs" or "Metrics" for detailed information
4. For more advanced monitoring, consider connecting to Azure Application Insights

## Troubleshooting

### Build Failures

1. Check the GitHub Actions logs for build errors
2. Verify that your `vite.config.ts` is correctly configured
3. Ensure all dependencies are properly installed

### API Connection Issues

1. Verify your environment variables are correctly set
2. Check CORS settings in your API
3. Use browser developer tools to inspect network requests

### Custom Domain Issues

1. Verify DNS records are correctly set up
2. Check SSL certificate provisioning status
3. Wait for DNS propagation (can take up to 48 hours)

## Additional Resources

- [Azure Static Web Apps documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [GitHub Actions for Azure Static Web Apps](https://docs.microsoft.com/en-us/azure/static-web-apps/github-actions-workflow)
- [Configure Azure Static Web Apps](https://docs.microsoft.com/en-us/azure/static-web-apps/configuration)
- [Azure Static Web Apps CLI](https://github.com/Azure/static-web-apps-cli)
