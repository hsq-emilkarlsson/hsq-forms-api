# HSQ Forms API Integration Guide

This guide explains how to integrate the HSQ Forms API with your frontend application, focusing on the React form template provided in this repository.

## Table of Contents
- [API Overview](#api-overview)
- [Integration Steps](#integration-steps)
- [Authentication](#authentication)
- [Form Submission](#form-submission)
- [File Uploads](#file-uploads)
- [Error Handling](#error-handling)
- [CORS Configuration](#cors-configuration)
- [Example Integration](#example-integration)

## API Overview

The HSQ Forms API provides endpoints to:

1. Submit form data
2. Upload files with form submissions
3. Retrieve form configurations
4. Track form submissions

Key endpoints include:

- `POST /api/forms/submit` - Submit form data
- `POST /api/forms/submit-with-files` - Submit form data with file uploads
- `GET /api/forms/{form_id}` - Get form configuration

## Integration Steps

### Step 1: Configure API URL and Authentication

In your frontend application, configure the API URL and authentication method. For the React template, create a `.env` file with:

```
VITE_API_URL=https://your-api-url.com/api
VITE_API_KEY=your-api-key
```

### Step 2: Set Up the API Client

The template includes an API client in `src/api/formsApi.ts` that handles communication with the HSQ Forms API. The client is preconfigured to:

- Make authenticated requests
- Handle file uploads
- Process API responses

### Step 3: Use the Form Components

Use one of the provided form components or create your own:

```jsx
import { ContactForm } from './components/ContactForm';

function App() {
  const handleSuccess = () => {
    // Handle successful submission
    console.log('Form submitted successfully');
  };

  return (
    <div className="App">
      <h1>Contact Us</h1>
      <ContactForm onSuccess={handleSuccess} />
    </div>
  );
}
```

## Authentication

The HSQ Forms API supports API key authentication. The API key should be sent in the `X-API-Key` header with each request.

In the React template, this is handled automatically when you set the `VITE_API_KEY` environment variable.

## Form Submission

### Basic Form Submission

```javascript
import { submitForm } from '../api/formsApi';

// Submit form data
const response = await submitForm({
  formId: 'contact-form',
  data: {
    name: 'John Doe',
    email: 'john@example.com',
    message: 'Hello world'
  }
});

if (response.success) {
  // Handle success
} else {
  // Handle error
}
```

### Form Submission with Metadata

You can include metadata with your form submissions to provide additional context:

```javascript
const response = await submitForm({
  formId: 'contact-form',
  data: formData,
  metadata: {
    source: 'marketing-campaign',
    campaign: 'summer-2023',
    browser: getBrowserInfo(),
    timestamp: new Date().toISOString()
  }
});
```

## File Uploads

To submit a form with file uploads, use the `submitForm` function with the `files` property:

```javascript
const file = fileInputRef.current.files[0];

const response = await submitForm({
  formId: 'document-submission',
  data: formData,
  files: [file]
});
```

The API handles file validation, secure storage, and virus scanning automatically.

## Error Handling

The API returns standardized error responses:

```javascript
try {
  const response = await submitForm({
    formId: 'contact-form',
    data: formData
  });
  
  if (!response.success) {
    console.error('API Error:', response.error);
    // Handle API error (e.g., validation error)
  }
} catch (error) {
  console.error('Network or unexpected error:', error);
  // Handle network or other unexpected errors
}
```

Common error scenarios:
- 400 - Bad Request (invalid data)
- 401 - Unauthorized (invalid API key)
- 413 - Payload Too Large (file size exceeded)
- 415 - Unsupported Media Type (invalid file type)
- 429 - Too Many Requests (rate limit exceeded)
- 500 - Internal Server Error

## CORS Configuration

The HSQ Forms API is configured to allow cross-origin requests from approved origins. To enable CORS for your domain:

1. Contact the API administrator to add your domain to the allowed origins list, or
2. Set the appropriate CORS configuration in your API deployment

For development, the API allows requests from `localhost` domains by default.

## Example Integration

### Complete Example Using React Hook Form

```jsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { submitForm } from '../api/formsApi';

// Form schema
const formSchema = z.object({
  name: z.string().min(2, 'Name must have at least 2 characters'),
  email: z.string().email('Invalid email address'),
  message: z.string().min(10, 'Message must have at least 10 characters')
});

function ContactFormExample() {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState(null);
  const [submitted, setSubmitted] = useState(false);
  
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset
  } = useForm({
    resolver: zodResolver(formSchema)
  });
  
  const onSubmit = async (data) => {
    setIsSubmitting(true);
    setSubmitError(null);
    
    try {
      const response = await submitForm({
        formId: 'contact-form',
        data,
        metadata: {
          source: 'website-contact',
          timestamp: new Date().toISOString()
        }
      });
      
      if (response.success) {
        reset();
        setSubmitted(true);
      } else {
        setSubmitError(response.error || 'Failed to submit form');
      }
    } catch (error) {
      setSubmitError('An unexpected error occurred');
      console.error('Form submission error:', error);
    } finally {
      setIsSubmitting(false);
    }
  };
  
  if (submitted) {
    return (
      <div className="success-message">
        Thank you for your submission! We'll get back to you soon.
      </div>
    );
  }
  
  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      {submitError && (
        <div className="error-message">{submitError}</div>
      )}
      
      <div className="form-group">
        <label htmlFor="name">Name</label>
        <input id="name" {...register('name')} />
        {errors.name && (
          <span className="error">{errors.name.message}</span>
        )}
      </div>
      
      <div className="form-group">
        <label htmlFor="email">Email</label>
        <input id="email" type="email" {...register('email')} />
        {errors.email && (
          <span className="error">{errors.email.message}</span>
        )}
      </div>
      
      <div className="form-group">
        <label htmlFor="message">Message</label>
        <textarea id="message" {...register('message')} rows={5} />
        {errors.message && (
          <span className="error">{errors.message.message}</span>
        )}
      </div>
      
      <button 
        type="submit" 
        disabled={isSubmitting}
        className="submit-button"
      >
        {isSubmitting ? 'Submitting...' : 'Submit'}
      </button>
    </form>
  );
}

export default ContactFormExample;
```

### API Response Structure

```javascript
// Success response
{
  "success": true,
  "data": {
    "id": "form-submission-123",
    "status": "success",
    "timestamp": "2023-12-01T14:30:00Z",
    "tracking_id": "abc123"
  }
}

// Error response
{
  "success": false,
  "error": "Invalid email format",
  "message": "The provided form data failed validation",
  "details": {
    "email": ["Invalid email address format"]
  }
}
```
