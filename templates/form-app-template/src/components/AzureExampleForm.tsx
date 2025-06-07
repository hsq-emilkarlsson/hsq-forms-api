import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { submitForm } from '../api/formsApi';
import { getBrowserInfo } from '../utils/helpers';
import { isAzureEnabled, trackEvent } from '../utils/azureIntegration';

// Define the form schema with Zod
const formSchema = z.object({
  name: z.string().min(2, 'Namnet måste innehålla minst 2 tecken').max(100),
  email: z.string().email('Ogiltig e-postadress'),
  company: z.string().optional(),
  phone: z.string().optional(),
  message: z.string().min(10, 'Meddelandet måste innehålla minst 10 tecken'),
  consent: z.boolean().refine(val => val === true, {
    message: 'Du måste acceptera villkoren för att fortsätta',
  }),
});

// Derive TypeScript type from schema
type AzureFormData = z.infer<typeof formSchema>;

interface AzureExampleFormProps {
  onSuccess: () => void;
}

/**
 * Azure Example Form component that demonstrates integration with Azure services
 * through the HSQ Forms API
 */
const AzureExampleForm = ({ onSuccess }: AzureExampleFormProps) => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [file, setFile] = useState<File | null>(null);
  const [azureEnabled, setAzureEnabled] = useState<boolean>(false);
  
  useEffect(() => {
    // Check if Azure integration is enabled
    const azureConfig = isAzureEnabled();
    setAzureEnabled(azureConfig);
    
    // Track page view for analytics
    trackEvent('form_view', { 
      formType: 'azure-example',
      azureEnabled: azureConfig
    });
  }, []);
  
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<AzureFormData>({
    resolver: zodResolver(formSchema),
    mode: 'onBlur',
  });
  
  // Handle file change
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setFile(e.target.files[0]);
    } else {
      setFile(null);
    }
  };
  
  // Handle form submission
  const onSubmit = async (data: AzureFormData) => {
    setIsSubmitting(true);
    setSubmitError(null);
    
    // Track submission attempt
    trackEvent('form_submission_attempt', {
      formType: 'azure-example',
      azureEnabled: azureEnabled,
      hasFile: !!file
    });
    
    try {
      // Prepare submission data
      const submission = {
        formId: import.meta.env.VITE_FORM_ID || 'azure-example-form',
        data,
        files: file ? [file] : undefined,
        metadata: {
          source: 'azure-example-form',
          azureEnabled: azureEnabled,
          browser: getBrowserInfo(),
          timestamp: new Date().toISOString(),
        },
      };
      
      // Submit to API
      const response = await submitForm(submission);
      
      if (response.success) {
        // Track successful submission
        trackEvent('form_submission_success', {
          formType: 'azure-example',
          submissionId: response.data?.id || 'unknown'
        });
        
        // Reset form and notify parent
        reset();
        setFile(null);
        onSuccess();
      } else {
        // Track submission error
        trackEvent('form_submission_error', {
          formType: 'azure-example',
          error: response.error || 'Unknown error'
        });
        
        setSubmitError(
          response.error || 
          'Ett fel uppstod vid skickande av formuläret. Vänligen försök igen.'
        );
      }
    } catch (error) {
      console.error('Form submission error:', error);
      
      // Track submission exception
      trackEvent('form_submission_exception', {
        formType: 'azure-example',
        error: error instanceof Error ? error.message : 'Unknown error'
      });
      
      setSubmitError('Ett tekniskt fel uppstod. Vänligen försök igen senare.');
    } finally {
      setIsSubmitting(false);
    }
  };
  
  return (
    <form 
      onSubmit={handleSubmit(onSubmit)}
      className="space-y-6"
    >
      {/* Azure integration status */}
      <div className={`p-2 text-sm rounded-md ${azureEnabled ? 'bg-blue-50 text-blue-700' : 'bg-gray-50 text-gray-500'}`}>
        <div className="flex items-center">
          <div className={`w-2 h-2 rounded-full mr-2 ${azureEnabled ? 'bg-blue-500' : 'bg-gray-400'}`}></div>
          <p>
            Azure Integration: <strong>{azureEnabled ? 'Active' : 'Inactive'}</strong>
          </p>
        </div>
        <p className="mt-1 text-xs">
          {azureEnabled 
            ? 'Files will be uploaded to Azure Blob Storage and form data will be processed with Azure services.' 
            : 'Azure integration is disabled. Enable it by setting VITE_AZURE_ENABLED=true in your .env file.'}
        </p>
      </div>
      
      {/* Show error message if submission failed */}
      {submitError && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-md text-red-700">
          {submitError}
        </div>
      )}
      
      {/* Name field */}
      <div>
        <label htmlFor="name" className="block text-sm font-medium text-gray-700">
          Namn *
        </label>
        <input
          type="text"
          id="name"
          {...register('name')}
          className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 ${
            errors.name ? 'border-red-300' : ''
          }`}
        />
        {errors.name && (
          <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>
        )}
      </div>
      
      {/* Email field */}
      <div>
        <label htmlFor="email" className="block text-sm font-medium text-gray-700">
          E-post *
        </label>
        <input
          type="email"
          id="email"
          {...register('email')}
          className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 ${
            errors.email ? 'border-red-300' : ''
          }`}
        />
        {errors.email && (
          <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
        )}
      </div>
      
      {/* Two column layout for company and phone */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Company field */}
        <div>
          <label htmlFor="company" className="block text-sm font-medium text-gray-700">
            Företag
          </label>
          <input
            type="text"
            id="company"
            {...register('company')}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
          />
        </div>
        
        {/* Phone field */}
        <div>
          <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
            Telefonnummer
          </label>
          <input
            type="tel"
            id="phone"
            {...register('phone')}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500"
          />
        </div>
      </div>
      
      {/* Message field */}
      <div>
        <label htmlFor="message" className="block text-sm font-medium text-gray-700">
          Meddelande *
        </label>
        <textarea
          id="message"
          rows={4}
          {...register('message')}
          className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-500 focus:ring-primary-500 ${
            errors.message ? 'border-red-300' : ''
          }`}
        />
        {errors.message && (
          <p className="mt-1 text-sm text-red-600">{errors.message.message}</p>
        )}
      </div>
      
      {/* File upload */}
      <div>
        <label htmlFor="file" className="block text-sm font-medium text-gray-700">
          Bilaga (max 5MB)
        </label>
        <input
          type="file"
          id="file"
          onChange={handleFileChange}
          className="mt-1 block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-medium file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100"
        />
        {file && (
          <p className="mt-1 text-sm text-gray-600">
            Vald fil: {file.name} ({Math.round(file.size / 1024)} KB)
          </p>
        )}
      </div>
      
      {/* Terms consent */}
      <div className="flex items-start">
        <div className="flex items-center h-5">
          <input
            id="consent"
            type="checkbox"
            {...register('consent')}
            className={`h-4 w-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500 ${
              errors.consent ? 'border-red-300' : ''
            }`}
          />
        </div>
        <div className="ml-3 text-sm">
          <label htmlFor="consent" className={`font-medium ${errors.consent ? 'text-red-700' : 'text-gray-700'}`}>
            Jag godkänner att HSQ sparar mina uppgifter *
          </label>
          <p className="text-gray-500">
            Vi använder dina uppgifter endast för att kontakta dig angående din förfrågan.
          </p>
          {errors.consent && (
            <p className="mt-1 text-sm text-red-600">{errors.consent.message}</p>
          )}
        </div>
      </div>
      
      {/* Submit button */}
      <div className="flex justify-end">
        <button
          type="submit"
          disabled={isSubmitting}
          className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSubmitting ? 'Skickar...' : 'Skicka'}
        </button>
      </div>
    </form>
  );
};

export default AzureExampleForm;
