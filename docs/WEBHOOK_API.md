# Webhook API Documentation

## Overview

HSQ Forms API includes webhook functionality that sends notifications to configured endpoints when specific events occur, such as form submissions. Webhooks allow you to build integrations that respond to events in real-time.

## Webhook Events

The following events trigger webhook notifications:

| Event Type | Description |
|------------|-------------|
| `submission_created` | Triggered when a new form submission is created |
| `batch_submission_created` | Triggered for each submission in a batch submission |
| `submission_updated` | Triggered when a form submission is updated |

## Webhook Payload

The webhook payload is a JSON object with the following structure:

```json
{
  "event_type": "submission_created",
  "timestamp": "2025-06-06T12:34:56.789Z",
  "form_data": {
    "id": "abc123def456",
    "template_id": "template-123",
    "template_name": "Contact Form",
    "data": {
      // Form fields and values
    },
    "submitted_by": "user@example.com",
    "submitted_from_project": "project-123",
    "submitted_at": "2025-06-06T12:34:56.789Z"
  }
}
```

For batch submissions, the payload includes additional fields:

```json
{
  "event_type": "batch_submission_created",
  "timestamp": "2025-06-06T12:34:56.789Z",
  "form_data": {
    // Basic form data
    "is_batch": true,
    "batch_size": 10
  }
}
```

## Webhook Configuration

Webhooks are configured using environment variables:

| Variable | Description |
|----------|-------------|
| `WEBHOOKS_ENABLED` | Set to `true` to enable webhooks |
| `WEBHOOK_URLS` | Comma-separated list of webhook URLs |
| `WEBHOOK_FORM_SPECIFIC_URLS` | JSON string mapping form IDs to webhook URLs |
| `WEBHOOK_SECRET` | Secret key for signing webhook payloads |

### Example Configuration

```
WEBHOOKS_ENABLED=true
WEBHOOK_URLS=https://example.com/webhook1,https://example.com/webhook2
WEBHOOK_FORM_SPECIFIC_URLS={"contact-form":"https://example.com/contact-webhook","feedback-form":"https://example.com/feedback-webhook"}
WEBHOOK_SECRET=your-webhook-secret
```

## Webhook Security

Each webhook request includes a `X-Webhook-Signature` header containing an HMAC-SHA256 signature of the request body using the webhook secret. You can use this signature to verify the authenticity of the request.

### Signature Verification Example (Python)

```python
import hmac
import hashlib

def verify_webhook_signature(payload, signature, secret):
    """
    Verify webhook signature
    
    Args:
        payload: The webhook payload as a string
        signature: The X-Webhook-Signature header value
        secret: The webhook secret
        
    Returns:
        bool: True if signature is valid, False otherwise
    """
    computed_signature = hmac.new(
        secret.encode('utf-8'),
        payload.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(computed_signature, signature)
```

## Retry Policy

If a webhook endpoint returns a non-2xx status code, the API will not retry the webhook. It's recommended that your webhook endpoint responds with a 2xx status code as quickly as possible and performs any time-consuming operations asynchronously.

## Webhook Limits

- Timeout: 10 seconds per webhook request
- Payload size: Limited by API request size (typically 10MB)
- Rate limiting: None currently implemented
- Webhook URLs per form: No hard limit

## Best Practices

1. Respond to webhook requests quickly (within milliseconds if possible)
2. Process webhook data asynchronously
3. Verify webhook signatures for security
4. Handle duplicate webhooks (implement idempotency)
5. Set up monitoring for webhook failures

## Integration Examples

For detailed examples of integrating with Power Automate and other systems, see the [Power Automate Integration Guide](POWER_AUTOMATE_INTEGRATION.md).
