# HSQ Forms Platform - File Upload Deployment Next Steps

## Current Status

As of 2025-06-02, we have deployed the updated HSQ Forms Platform to Azure with file upload functionality. The following components have been successfully deployed:

- ✅ Azure Storage Account `hsqformsstorage` created
- ✅ Storage containers `uploads` and `temp-uploads` created
- ✅ API container app updated with storage connection settings
- ✅ Contact form container app updated with file upload UI
- ✅ Support form container app updated with file upload UI
- ✅ Managed identity assigned to API container app

## Troubleshooting Steps

The file upload functionality appears to be partially deployed but not fully accessible. Here are the steps to complete the deployment:

### 1. Check API Routing Configuration

The file router appears to be included in the code but endpoints are not accessible. Verify that:

```bash
# Check if the files.py router is included in the FastAPI app
grep -r "app.include_router" /Users/emilkarlsson/Documents/Dev/hsq-form-platform/apps/app/app/main.py
```

### 2. Rebuild and Push Docker Image with Debug Information

Add debug logs to understand routing issues:

```bash
# Add debug code to the files.py router
cd /Users/emilkarlsson/Documents/Dev/hsq-form-platform/apps/app
docker build --platform linux/amd64 -t hsqformsprodacr1748847162.azurecr.io/hsq-forms-api:debug .
docker push hsqformsprodacr1748847162.azurecr.io/hsq-forms-api:debug

# Deploy debug version
az containerapp update \
  --name hsq-forms-api \
  --resource-group rg-hsq-forms-prod-westeu \
  --image hsqformsprodacr1748847162.azurecr.io/hsq-forms-api:debug
```

### 3. Check API Application Logs

Check logs for errors related to the file endpoint registration:

```bash
# Get logs from the container app
az containerapp logs show \
  --name hsq-forms-api \
  --resource-group rg-hsq-forms-prod-westeu \
  --follow
```

### 4. Test Direct Endpoint Access

Test if other endpoints are accessible and only file endpoints are failing:

```bash
# Test submit endpoint
curl -X POST -H "Content-Type: application/json" \
  -d '{"type":"contact","data":{"name":"Test","email":"test@test.com"}}' \
  https://hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io/submit
```

### 5. Verify Container App Environment Variables

Ensure all needed environment variables are correctly set:

```bash
# List environment variables
az containerapp show \
  --name hsq-forms-api \
  --resource-group rg-hsq-forms-prod-westeu \
  --query "properties.template.containers[0].env"
```

### 6. Test Frontend File Upload UI

Once the API endpoints are working, test the frontend file upload functionality:

1. Visit the contact form: https://ca-hsq-contact-form.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io
2. Fill out the form and test file upload functionality
3. Check both temporary uploads (before submission) and permanent uploads (after submission)

## Completion Checklist

- [ ] API file endpoints accessible
- [ ] Contact form file upload functional
- [ ] Support form file upload functional
- [ ] Files can be uploaded to Azure Blob Storage
- [ ] Files can be viewed/downloaded through the API
- [ ] All environment variables correctly configured
- [ ] Documentation updated with file upload instructions

## Notes

- If the issue persists, consider recreating the API container app from scratch
- The storage account is correctly set up and should work once the API endpoints are accessible
- Frontend components for file upload are in place and just need the working API endpoints
