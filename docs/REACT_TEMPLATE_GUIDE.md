# React Form Template Integration Guide

This guide explains how to use the HSQ Forms API with the provided React form template in the `templates/form-app-template` directory.

## Table of Contents
1. [Overview](#overview)
2. [Setup and Configuration](#setup-and-configuration)
3. [Working with Forms](#working-with-forms)
4. [File Attachment Handling](#file-attachment-handling)
5. [Error Handling and Retries](#error-handling-and-retries)
6. [Azure Integration](#azure-integration)
7. [Advanced Customization](#advanced-customization)

## Overview

The React form template provides a ready-to-use frontend implementation that connects to the HSQ Forms API. It includes:

- Form components with validation
- API integration with error handling and retries
- File upload support
- Azure Application Insights integration
- Accessibility features

## Setup and Configuration

### Prerequisites

- Node.js 16+
- npm or yarn
- Access to HSQ Forms API (local or remote)

### Installation

1. Navigate to the template directory:

```bash
cd templates/form-app-template
```

2. Install dependencies:

```bash
npm install
# or
yarn install
```

3. Configure environment variables:

Create a `.env` file in the root of the template directory:

```
# API configuration
VITE_API_URL=http://localhost:8001
VITE_API_KEY=your_api_key_here
VITE_FORM_ID=contact-form

# Azure configuration (optional)
VITE_AZURE_ENABLED=false
VITE_AZURE_STORAGE_URL=
VITE_ENABLE_ANALYTICS=false
VITE_APPLICATION_INSIGHTS_KEY=
```

4. Start the development server:

```bash
npm run dev
# or
yarn dev
```

### Project Structure

Key files in the template:

- `/src/api/formsApi.ts` - API integration methods
- `/src/components/ContactForm.tsx` - Example form component
- `/src/utils/errorHandling.ts` - Error handling and retry logic
- `/src/utils/azureIntegration.ts` - Azure integration
- `/src/contexts/FormContext.tsx` - Form state management
- `/src/hooks/useFormHook.ts` - Custom form hook

## Working with Forms

### Basic Form Submission

The template provides a pre-built `ContactForm` component that demonstrates form submission:

```tsx
// Example usage of ContactForm
import ContactForm from './components/ContactForm';

const MyPage = () => {
  const handleSuccess = () => {
    console.log('Form submitted successfully!');
    // Redirect or show success message
  };

  return (
    <div>
      <h1>Contact Us</h1>
      <ContactForm onSuccess={handleSuccess} />
    </div>
  );
};
```

### Using the Form Hook

For custom forms, use the `useFormHook` hook:

```tsx
import { useFormHook } from '../hooks/useFormHook';
import { z } from 'zod';
import { submitForm } from '../api/formsApi';

// Define validation schema with zod
const myFormSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  subject: z.string().min(3, 'Subject is required'),
  message: z.string().min(10, 'Message must be at least 10 characters'),
});

// Type based on schema
type MyFormData = z.infer<typeof myFormSchema>;

const MyCustomForm = () => {
  const handleFormSubmit = async (data: MyFormData) => {
    // Submit to API
    const response = await submitForm({
      formId: import.meta.env.VITE_FORM_ID || 'custom-form',
      data,
      metadata: {
        source: 'custom-form',
        timestamp: new Date().toISOString(),
      },
    });

    if (!response.success) {
      throw new Error(response.error || 'Submission failed');
    }
    
    // Handle success
    console.log('Submission successful!');
  };

  const {
    register,
    handleSubmit,
    errors,
    isSubmitting,
    submitError,
  } = useFormHook({
    validationSchema: myFormSchema,
    onSubmit: handleFormSubmit,
    defaultValues: {
      name: '',
      email: '',
      subject: '',
      message: '',
    },
  });

  return (
    <form onSubmit={handleSubmit} className="space-y-6" noValidate>
      {/* Form fields */}
      <div>
        <label htmlFor="name" className="form-label">Name</label>
        <input id="name" type="text" {...register('name')} />
        {errors.name && <p className="form-error">{errors.name.message}</p>}
      </div>
      
      {/* More fields... */}
      
      {submitError && <div className="text-red-500">{submitError}</div>}
      
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Submitting...' : 'Submit'}
      </button>
    </form>
  );
};
```

### Using FormContext

For multi-step forms or forms with complex state, use the FormContext:

```tsx
import { FormProvider } from '../contexts/FormContext';

const MyApp = () => {
  return (
    <FormProvider>
      <MyMultiStepForm />
    </FormProvider>
  );
};

// In a component
import { useContext } from 'react';
import { FormContext } from '../contexts/FormContext';

const FormStep = () => {
  const { formData, updateFormData } = useContext(FormContext);
  
  return (
    // Form fields that update formData
  );
};
```

## File Attachment Handling

The template supports file uploads with the HSQ Forms API:

```tsx
import { useState } from 'react';
import { submitForm } from '../api/formsApi';

const FileUploadForm = () => {
  const [files, setFiles] = useState<File[]>([]);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    message: '',
  });
  
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setFiles(Array.from(e.target.files));
    }
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      const response = await submitForm({
        formId: 'file-upload-form',
        data: formData,
        files,
        metadata: {
          source: 'file-upload-example',
        },
      });
      
      if (response.success) {
        console.log('Form with files submitted successfully');
      } else {
        console.error('Error:', response.error);
      }
    } catch (error) {
      console.error('Submission error:', error);
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      {/* Regular form fields */}
      <div>
        <label htmlFor="name">Name</label>
        <input 
          id="name"
          value={formData.name}
          onChange={e => setFormData({...formData, name: e.target.value})}
        />
      </div>
      
      {/* More fields... */}
      
      {/* File input */}
      <div>
        <label htmlFor="files">Attachments (max 5 files)</label>
        <input 
          id="files" 
          type="file" 
          multiple 
          onChange={handleFileChange} 
          accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
        />
        <p className="text-sm text-gray-500">
          Selected files: {files.length > 0 ? files.map(f => f.name).join(', ') : 'None'}
        </p>
      </div>
      
      <button type="submit">Submit with Files</button>
    </form>
  );
};
```

## Error Handling and Retries

The template includes a robust error handling system with automatic retries:

### How Retries Work

The `requestWithRetry` function in `errorHandling.ts` automatically retries failed API requests:

- Retries on network errors and specific HTTP status codes (408, 429, 500, 502, 503, 504)
- Uses exponential backoff
- Configurable max retries, delay, and retry conditions

```typescript
// Example of custom retry configuration
import { requestWithRetry } from '../utils/errorHandling';
import axios from 'axios';

const fetchData = async () => {
  try {
    const response = await requestWithRetry({
      method: 'get',
      url: '/some-endpoint',
      baseURL: 'http://api.example.com',
    }, {
      maxRetries: 5,               // Override default retry count
      retryDelay: 500,             // Start with 500ms delay
      useExponentialBackoff: true, // Increase delay with each retry
      retryStatusCodes: [500, 502, 503, 504] // Only retry on these status codes
    });
    
    return response.data;
  } catch (error) {
    // Handle final failure after all retries
    console.error('Failed after multiple retries:', error);
    throw error;
  }
};
```

### User-friendly Error Messages

The `formatUserFriendlyError` function converts technical errors to user-friendly messages:

```typescript
import { formatUserFriendlyError } from '../utils/errorHandling';

try {
  // API call that might fail
} catch (error) {
  // Display user-friendly error
  const message = formatUserFriendlyError(error);
  setErrorMessage(message);
}
```

## Azure Integration

The template includes integration with Azure services:

### Azure Blob Storage

For accessing files stored in Azure Blob Storage:

```typescript
import { getAzureFileUrl } from '../utils/azureIntegration';

const FilePreview = ({ fileUrl }) => {
  // Convert API file path to full Azure URL if needed
  const fullUrl = getAzureFileUrl(fileUrl);
  
  return <a href={fullUrl} target="_blank" rel="noopener noreferrer">View File</a>;
};
```

### Application Insights

To track analytics in Azure Application Insights:

```typescript
import { setupAzureAnalytics, trackEvent } from '../utils/azureIntegration';

// Setup analytics (typically in your main component or initialization)
const App = () => {
  useEffect(() => {
    // Initialize Azure analytics
    setupAzureAnalytics({
      enableAutoRouteTracking: true,
    });
  }, []);
  
  return <div>App content</div>;
};

// Track custom events
const handleButtonClick = () => {
  // Track the event
  trackEvent('button_clicked', { 
    buttonName: 'submit',
    page: 'contact'
  });
  
  // Perform action
  // ...
};
```

## Advanced Customization

### Custom API Integration

To add custom API endpoints:

```typescript
// In src/api/customApi.ts
import axios from 'axios';
import { requestWithRetry } from '../utils/errorHandling';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add custom API methods
export const getSurveyData = async (surveyId: string) => {
  try {
    const response = await requestWithRetry({
      method: 'get',
      url: `/surveys/${surveyId}`,
      baseURL: api.defaults.baseURL,
      headers: api.defaults.headers,
    });
    
    return response.data;
  } catch (error) {
    // Handle error
    console.error('Failed to fetch survey data:', error);
    throw error;
  }
};
```

### Adding Tests

The template includes Jest and React Testing Library setup. To add tests:

```typescript
// In src/__tests__/components/MyComponent.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import MyComponent from '../../components/MyComponent';
import { rest } from 'msw';
import { setupServer } from 'msw/node';

// Mock API responses
const server = setupServer(
  rest.post('/api/forms/templates/test-form/submit', (req, res, ctx) => {
    return res(
      ctx.status(201),
      ctx.json({
        success: true,
        message: 'Form submitted successfully',
        submission: {
          id: '123-456-789'
        }
      })
    );
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test('submits form data correctly', async () => {
  render(<MyComponent />);
  
  // Fill out form
  fireEvent.change(screen.getByLabelText(/name/i), { target: { value: 'Test User' } });
  fireEvent.change(screen.getByLabelText(/email/i), { target: { value: 'test@example.com' } });
  
  // Submit form
  fireEvent.click(screen.getByText(/submit/i));
  
  // Check loading state
  expect(screen.getByText(/submitting/i)).toBeInTheDocument();
  
  // Wait for success message
  await waitFor(() => {
    expect(screen.getByText(/success/i)).toBeInTheDocument();
  });
});
```

### Extending Form Components

To create a new form component based on the existing pattern:

```tsx
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { submitForm } from '../api/formsApi';

// Define your schema
const surveySchema = z.object({
  // Your form fields with validation
});

type SurveyData = z.infer<typeof surveySchema>;

const SurveyForm = ({ onSuccess }) => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<SurveyData>({
    resolver: zodResolver(surveySchema),
    mode: 'onBlur',
  });
  
  const onSubmit = async (data: SurveyData) => {
    setIsSubmitting(true);
    setSubmitError(null);
    
    try {
      const response = await submitForm({
        formId: 'survey-form',
        data,
        metadata: {
          source: 'survey-component',
        },
      });
      
      if (response.success) {
        reset();
        onSuccess();
      } else {
        setSubmitError(response.error || 'Form submission failed');
      }
    } catch (error) {
      console.error('Form error:', error);
      setSubmitError('An unexpected error occurred');
    } finally {
      setIsSubmitting(false);
    }
  };
  
  // Render your form
};
```

This guide covers the essential aspects of working with the React form template. For more details, refer to the individual component files and the API documentation.
