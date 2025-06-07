import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { submitForm } from '../api/formsApi';
import { contactFormWithFileSchema, ContactFormWithFileData } from '../utils/validation';
import { getBrowserInfo, formatBytes } from '../utils/helpers';

interface ContactFormWithFileProps {
  onSuccess: () => void;
}

const ContactFormWithFile = ({ onSuccess }: ContactFormWithFileProps) => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  
  const {
    register,
    handleSubmit,
    formState: { errors },
    watch,
    reset,
  } = useForm<ContactFormWithFileData>({
    resolver: zodResolver(contactFormWithFileSchema),
    mode: 'onBlur',
  });
  
  // Watch file input for changes
  const fileInput = watch('file');
  
  // Handle file selection
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (files?.length) {
      setSelectedFile(files[0]);
    } else {
      setSelectedFile(null);
    }
  };
  
  const onSubmit = async (data: ContactFormWithFileData) => {
    setIsSubmitting(true);
    setSubmitError(null);
    
    try {
      const formData: ContactFormWithFileData = {
        ...data,
      };
      
      // Prepare files array if a file was selected
      const files = data.file ? [data.file] : undefined;
      
      const response = await submitForm({
        formId: import.meta.env.VITE_FORM_ID || 'contact-form',
        data: {
          name: formData.name,
          email: formData.email,
          phone: formData.phone || '',
          message: formData.message,
          consent: formData.consent,
        },
        files,
        metadata: {
          source: 'contact-form-with-file-template',
          browser: getBrowserInfo(),
          timestamp: new Date().toISOString(),
        },
      });
      
      if (response.success) {
        // Reset form and trigger success callback
        reset();
        setSelectedFile(null);
        onSuccess();
      } else {
        setSubmitError(response.error || 'Ett fel uppstod vid skickande av formuläret.');
      }
    } catch (error) {
      console.error('Form submission error:', error);
      setSubmitError('Ett oväntat fel uppstod. Försök igen senare.');
    } finally {
      setIsSubmitting(false);
    }
  };
  
  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6" noValidate>
      {/* Name field */}
      <div>
        <label htmlFor="name" className="form-label">
          Namn <span className="text-red-500">*</span>
        </label>
        <input
          id="name"
          type="text"
          className="form-input"
          placeholder="Ditt namn"
          {...register('name')}
          disabled={isSubmitting}
        />
        {errors.name && (
          <p className="form-error">{errors.name.message}</p>
        )}
      </div>
      
      {/* Email field */}
      <div>
        <label htmlFor="email" className="form-label">
          E-post <span className="text-red-500">*</span>
        </label>
        <input
          id="email"
          type="email"
          className="form-input"
          placeholder="din.email@exempel.se"
          {...register('email')}
          disabled={isSubmitting}
        />
        {errors.email && (
          <p className="form-error">{errors.email.message}</p>
        )}
      </div>
      
      {/* Phone field */}
      <div>
        <label htmlFor="phone" className="form-label">
          Telefon
        </label>
        <input
          id="phone"
          type="tel"
          className="form-input"
          placeholder="+46 70 123 45 67"
          {...register('phone')}
          disabled={isSubmitting}
        />
        {errors.phone && (
          <p className="form-error">{errors.phone.message}</p>
        )}
      </div>
      
      {/* Message field */}
      <div>
        <label htmlFor="message" className="form-label">
          Meddelande <span className="text-red-500">*</span>
        </label>
        <textarea
          id="message"
          className="form-input min-h-[150px]"
          placeholder="Skriv ditt meddelande här..."
          {...register('message')}
          disabled={isSubmitting}
        />
        {errors.message && (
          <p className="form-error">{errors.message.message}</p>
        )}
      </div>
      
      {/* File upload */}
      <div>
        <label htmlFor="file" className="form-label">
          Bifoga fil (valfritt)
        </label>
        <div className="mt-1 flex items-center">
          <label className="block w-full">
            <span className="sr-only">Välj en fil</span>
            <input
              id="file"
              type="file"
              className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 
              file:rounded-md file:border-0 file:text-sm file:font-medium
              file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100"
              accept=".pdf,.jpg,.jpeg,.png"
              {...register('file')}
              onChange={handleFileChange}
              disabled={isSubmitting}
            />
          </label>
        </div>
        
        {selectedFile && (
          <div className="mt-2 text-sm text-gray-500">
            {selectedFile.name} ({formatBytes(selectedFile.size)})
          </div>
        )}
        
        <p className="mt-1 text-xs text-gray-500">
          Filstorlek max 10MB. Tillåtna format: PDF, JPEG, PNG.
        </p>
        
        {errors.file && (
          <p className="form-error">{errors.file.message}</p>
        )}
      </div>
      
      {/* Consent checkbox */}
      <div className="flex items-start">
        <div className="flex items-center h-5">
          <input
            id="consent"
            type="checkbox"
            className="w-4 h-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500"
            {...register('consent')}
            disabled={isSubmitting}
          />
        </div>
        <div className="ml-3 text-sm">
          <label htmlFor="consent" className="font-medium text-gray-700">
            Jag godkänner att mina uppgifter behandlas enligt <a href="#" className="text-primary-600 hover:underline">integritetspolicyn</a> <span className="text-red-500">*</span>
          </label>
          {errors.consent && (
            <p className="form-error">{errors.consent.message}</p>
          )}
        </div>
      </div>
      
      {/* Submit error message */}
      {submitError && (
        <div className="bg-red-50 p-4 rounded-md">
          <div className="flex">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-red-800">Ett fel uppstod</h3>
              <div className="mt-2 text-sm text-red-700">
                <p>{submitError}</p>
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* Submit button */}
      <div className="flex justify-end">
        <button
          type="submit"
          className="btn btn-primary"
          disabled={isSubmitting}
        >
          {isSubmitting ? (
            <span className="flex items-center">
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Skickar...
            </span>
          ) : (
            'Skicka meddelande'
          )}
        </button>
      </div>
    </form>
  );
};

export default ContactFormWithFile;
