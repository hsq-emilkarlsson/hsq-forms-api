import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useTranslation } from 'react-i18next';
import { submitForm } from '../api/formsApi';
import { contactFormSchema, ContactFormData } from '../utils/validation';
import { getBrowserInfo } from '../utils/helpers';

interface ContactFormProps {
  onSuccess: () => void;
  language?: string;
}

const ContactForm = ({ onSuccess, language }: ContactFormProps) => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const { t } = useTranslation();
  
  const {
    register,
    handleSubmit,
    formState: { errors, isValid },
    reset,
  } = useForm<ContactFormData>({
    resolver: zodResolver(contactFormSchema),
    mode: 'onBlur',
  });
  
  const onSubmit = async (data: ContactFormData) => {
    setIsSubmitting(true);
    setSubmitError(null);
    
    try {
      // Use the provided language prop or get it from URL path
      const currentLanguage = language || 
        window.location.pathname.split('/')[1] || 
        'en';
        
      const response = await submitForm({
        formId: import.meta.env.VITE_FORM_ID || 'contact-form',
        data,
        language: currentLanguage,
        metadata: {
          source: 'contact-form-template',
          browser: getBrowserInfo(),
          timestamp: new Date().toISOString(),
        },
      });
      
      if (response.success) {
        // Reset form and trigger success callback
        reset();
        onSuccess();
      } else {
        setSubmitError(response.error || t('form.error') || 'An error occurred while submitting the form.');
      }
    } catch (error) {
      console.error('Form submission error:', error);
      setSubmitError(t('form.unexpectedError') || 'An unexpected error occurred. Please try again later.');
    } finally {
      setIsSubmitting(false);
    }
  };
  
  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6" noValidate aria-label="Contact form">
      {/* Name field */}
      <div>
        <label htmlFor="name" className="form-label">
          {t('form.name')} <span className="text-red-500" aria-hidden="true">*</span>
          <span className="sr-only">(required)</span>
        </label>
        <input
          id="name"
          type="text"
          className="form-input"
          placeholder="Ditt namn"
          {...register('name')}
          disabled={isSubmitting}
          aria-invalid={errors.name ? "true" : "false"}
          aria-describedby={errors.name ? "name-error" : undefined}
          aria-required="true"
        />
        {errors.name && (
          <p id="name-error" className="form-error" role="alert">{errors.name.message}</p>
        )}
      </div>
      
      {/* Email field */}
      <div>
        <label htmlFor="email" className="form-label">
          {t('form.email')} <span className="text-red-500" aria-hidden="true">*</span>
          <span className="sr-only">(required)</span>
        </label>
        <input
          id="email"
          type="email"
          className="form-input"
          placeholder={t('form.email')}
          {...register('email')}
          disabled={isSubmitting}
          aria-invalid={errors.email ? "true" : "false"}
          aria-describedby={errors.email ? "email-error" : undefined}
          aria-required="true"
        />
        {errors.email && (
          <p id="email-error" className="form-error" role="alert">{errors.email.message}</p>
        )}
      </div>
      
      {/* Phone field */}
      <div>
        <label htmlFor="phone" className="form-label">
          {t('form.phone')}
        </label>
        <input
          id="phone"
          type="tel"
          className="form-input"
          placeholder={t('form.phone')}
          {...register('phone')}
          disabled={isSubmitting}
          aria-invalid={errors.phone ? "true" : "false"}
          aria-describedby={errors.phone ? "phone-error" : undefined}
        />
        {errors.phone && (
          <p id="phone-error" className="form-error" role="alert">{errors.phone.message}</p>
        )}
      </div>
      
      {/* Message field */}
      <div>
        <label htmlFor="message" className="form-label">
          {t('form.message')} <span className="text-red-500" aria-hidden="true">*</span>
          <span className="sr-only">(required)</span>
        </label>
        <textarea
          id="message"
          className="form-input min-h-[150px]"
          placeholder={t('form.message')}
          {...register('message')}
          disabled={isSubmitting}
          aria-invalid={errors.message ? "true" : "false"}
          aria-describedby={errors.message ? "message-error" : undefined}
          aria-required="true"
        />
        {errors.message && (
          <p id="message-error" className="form-error" role="alert">{errors.message.message}</p>
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
            aria-invalid={errors.consent ? "true" : "false"}
            aria-describedby={errors.consent ? "consent-error" : undefined}
            aria-required="true"
          />
        </div>
        <div className="ml-3 text-sm">
          <label htmlFor="consent" className="font-medium text-gray-700">
            {t('form.consentText')} <a href="#" className="text-primary-600 hover:underline">{t('form.privacyPolicy')}</a> <span className="text-red-500" aria-hidden="true">*</span>
            <span className="sr-only">(required)</span>
          </label>
          {errors.consent && (
            <p id="consent-error" className="form-error" role="alert">{errors.consent.message}</p>
          )}
        </div>
      </div>
      
      {/* Submit error message */}
      {submitError && (
        <div className="bg-red-50 p-4 rounded-md" role="alert" aria-live="assertive">
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
          aria-busy={isSubmitting}
        >
          {isSubmitting ? (
            <span className="flex items-center">
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" aria-hidden="true">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              {t('form.submitting')}
              <span className="sr-only">{t('form.waitWhileSubmitting')}</span>
            </span>
          ) : (
            t('form.submit')
          )}
        </button>
      </div>
    </form>
  );
};

export default ContactForm;
