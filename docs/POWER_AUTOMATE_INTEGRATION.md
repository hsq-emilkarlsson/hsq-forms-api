# Power Automate Integration Guide for HSQ Forms API

This guide explains how to integrate HSQ Forms API with Microsoft Power Automate to create automated workflows triggered by form submissions.

## Integration Overview

HSQ Forms API supports webhook notifications that can be consumed by Power Automate to create automated workflows. When a form is submitted, the API sends a webhook notification to configured endpoints, which can include a Power Automate HTTP trigger.

## Setting Up Webhook Integration

### Step 1: Configure Webhook Settings in HSQ Forms API

Add the following environment variables to your deployment:

```
WEBHOOKS_ENABLED=true
WEBHOOK_URLS=https://prod-00.westeurope.logic.azure.com/workflows/your-power-automate-webhook-url
WEBHOOK_SECRET=your-webhook-secret
```

For form-specific webhooks, you can configure a JSON mapping:

```
WEBHOOK_FORM_SPECIFIC_URLS={"template-id-1":"https://prod-00.westeurope.logic.azure.com/workflows/webhook-url-1","template-id-2":"https://prod-00.westeurope.logic.azure.com/workflows/webhook-url-2"}
```

### Step 2: Create a Power Automate Flow with HTTP Trigger

1. In Power Automate, create a new flow with an HTTP trigger
2. Configure the trigger to receive webhook notifications
3. Parse the JSON payload from the webhook

#### Example Power Automate HTTP Trigger Configuration:

- **Method**: POST
- **Relative path**: Leave empty
- **Request Body JSON Schema**: Use the sample payload below to generate the schema

```json
{
  "event_type": "submission_created",
  "timestamp": "2025-06-06T12:34:56.789Z",
  "form_data": {
    "id": "abc123def456",
    "template_id": "template-123",
    "template_name": "Contact Form",
    "data": {
      "name": "John Doe",
      "email": "john.doe@example.com",
      "message": "Hello, I have a question about your service."
    },
    "submitted_by": "user@example.com",
    "submitted_from_project": "project-123",
    "submitted_at": "2025-06-06T12:34:56.789Z"
  }
}
```

### Step 3: Process Form Data in Power Automate

After configuring the trigger, you can process the form data in Power Automate by:

1. Using the "Parse JSON" action to extract form data
2. Adding conditional processing based on the form template or data fields
3. Connecting to other services like SharePoint, Dynamics 365, or external APIs
4. Sending notifications via email, Teams, or other channels
5. Creating records in databases or other systems
6. Generating documents or reports

## Using Webhook Signatures for Security

Each webhook request includes a signature header `X-Webhook-Signature` that you can use to verify the authenticity of the request. The signature is an HMAC-SHA256 hash of the request body using the webhook secret.

In Power Automate, you can verify the signature using a custom connector or a custom function.

## Example Workflows

### Example 1: Send Email Notification

1. When a form is submitted (HTTP Trigger)
2. Parse the JSON payload
3. Create an HTML email body with form data
4. Send an email to the appropriate recipient

### Example 2: Create Record in SharePoint List

1. When a form is submitted (HTTP Trigger)
2. Parse the JSON payload
3. Create a new item in a SharePoint list with the form data
4. Send notification if successful

### Example 3: Conditional Processing Based on Form Type

1. When a form is submitted (HTTP Trigger)
2. Parse the JSON payload
3. Check the form template ID or template name
4. Route to different processing flows based on the form type

## Troubleshooting

- Verify webhook URL is correctly configured in the HSQ Forms API
- Check Power Automate flow run history for any errors
- Ensure the payload structure matches what Power Automate expects
- Verify network connectivity between HSQ Forms API and Power Automate

## Additional Resources

- [Microsoft Power Automate Documentation](https://learn.microsoft.com/en-us/power-automate/)
- [Working with HTTP Triggers in Power Automate](https://learn.microsoft.com/en-us/power-automate/triggers-introduction)
- [JSON Schema Reference](https://json-schema.org/understanding-json-schema/)
