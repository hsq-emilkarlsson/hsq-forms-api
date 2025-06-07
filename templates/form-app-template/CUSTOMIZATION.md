# Form Template Customization Guide

This guide provides instructions on how to customize the HSQ Forms API template application to fit your specific needs.

## Table of Contents
- [Basic Customization](#basic-customization)
- [Form Configuration](#form-configuration)
- [Styling](#styling)
- [Advanced Customization](#advanced-customization)
- [API Integration](#api-integration)

## Basic Customization

### Environment Variables

The template uses environment variables for basic configuration. Create a `.env` file based on the `.env.example`:

```bash
# API Configuration
VITE_API_URL=http://localhost:8000/api
VITE_API_KEY=your-api-key

# Form Configuration
VITE_FORM_ID=contact-form
VITE_FORM_NAME=Kontaktformulär
VITE_FORM_DESCRIPTION=Fyll i formuläret nedan för att skicka din förfrågan. Vi återkommer så snart som möjligt.
```

### App Name and Metadata

Update the following files to change basic application information:

1. `index.html` - Update title, description, and favicon
2. `package.json` - Change the name and version
3. `src/components/layout/Header.tsx` - Customize header and navigation
4. `src/components/layout/Footer.tsx` - Update footer content

## Form Configuration

### Using Existing Form Components

The template includes three main form components:

1. **ContactForm**: Basic contact form with name, email, phone, and message fields
2. **ContactFormWithFile**: Extends the basic contact form with file upload
3. **DynamicForm**: A configurable form component that renders fields based on configuration

To use these components:

```tsx
import ContactForm from '../components/ContactForm';

// In your component:
<ContactForm 
  onSuccess={() => {
    // Handle successful submission
    navigate('/success');
  }} 
/>
```

### Creating Custom Forms

To create a custom form:

1. Define your form schema in `src/utils/validation.ts`:

```typescript
export const myCustomFormSchema = z.object({
  field1: z.string().min(2).max(100),
  field2: z.number().min(1),
  // Add more fields
});

export type MyCustomFormData = z.infer<typeof myCustomFormSchema>;
```

2. Create your form component:

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { submitForm } from '../api/formsApi';
import { myCustomFormSchema, MyCustomFormData } from '../utils/validation';

const MyCustomForm = ({ onSuccess }) => {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<MyCustomFormData>({
    resolver: zodResolver(myCustomFormSchema),
    mode: 'onBlur',
  });
  
  const onSubmit = async (data) => {
    try {
      const response = await submitForm({
        formId: 'my-custom-form',
        data,
        metadata: {
          source: 'custom-form',
        },
      });
      
      if (response.success) {
        onSuccess();
      }
    } catch (error) {
      console.error('Form submission error:', error);
    }
  };
  
  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      {/* Form fields */}
    </form>
  );
};
```

## Styling

The template uses Tailwind CSS for styling. Customization can be done in several ways:

### Tailwind Theme

Modify `tailwind.config.js` to change the color scheme and other theme settings:

```js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          // Add your custom color palette
          600: '#0369a1', // Primary action color
        },
        // Add more custom colors
      },
      // Add custom fonts, spacing, etc.
    },
  },
  // ...
};
```

### Component Styling

Component styles can be modified directly using Tailwind classes:

```tsx
// Before
<button className="bg-primary-600 text-white px-4 py-2 rounded">
  Submit
</button>

// After customization
<button className="bg-emerald-600 text-white px-6 py-3 rounded-lg font-bold">
  Submit
</button>
```

## Advanced Customization

### Adding New Pages

1. Create a new page component in `src/pages/`:

```tsx
// src/pages/NewPage.tsx
import React from 'react';

const NewPage = () => {
  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-3xl font-bold text-center mb-6">
        My New Page
      </h1>
      
      <div className="bg-white p-6 rounded-lg shadow-md">
        {/* Your content here */}
      </div>
    </div>
  );
};

export default NewPage;
```

2. Add the route in `App.tsx`:

```tsx
// In App.tsx
import NewPage from './pages/NewPage';

// In the Routes component:
<Route path="/new-page" element={<NewPage />} />
```

### Using the Form Context

The FormContext provides state management for multi-step forms:

```tsx
import { useFormContext } from '../hooks/useFormContext';

const MyComponent = () => {
  const { 
    formData, 
    updateFormData, 
    isSubmitting,
    submitError,
    resetForm 
  } = useFormContext();
  
  // Use these methods to manage form state
  
  return (
    // Your component
  );
};
```

## API Integration

### Configuring the API Client

The API client is configured in `src/api/formsApi.ts`. Modify this to match your API:

```typescript
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  headers: {
    'Content-Type': 'application/json',
    // Add any other default headers
  },
});
```

### Custom API Functions

Add custom API functions as needed:

```typescript
// Get form configuration
export const getFormConfig = async (formId: string): Promise<ApiResponse<FormConfig>> => {
  try {
    const response = await api.get(`/forms/${formId}/config`);
    return response.data;
  } catch (error) {
    // Handle error
    return {
      success: false,
      error: 'Failed to fetch form configuration',
    };
  }
};
```

### CORS Configuration

When deploying your API and form app to different domains, ensure CORS is configured in your API:

1. Set the appropriate CORS origins in your API's environment variables
2. If using Azure Static Web Apps, the CORS headers are automatically handled
3. For local development, ensure the development server allows CORS from your frontend domain

---

This guide covers the basics of customizing the form template. For more advanced customizations, refer to the API documentation and React component reference.
