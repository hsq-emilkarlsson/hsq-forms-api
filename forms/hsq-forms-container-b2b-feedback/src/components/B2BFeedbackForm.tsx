import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useTranslation } from 'react-i18next';
import { useState } from 'react';

// Comprehensive validation schema for B2B feedback
const schema = z.object({
  // Company Information
  companyName: z.string()
    .min(2, 'Company name must be at least 2 characters')
    .max(100, 'Company name must be less than 100 characters'),
  contactPerson: z.string()
    .min(2, 'Contact person name must be at least 2 characters')
    .max(50, 'Contact person name must be less than 50 characters'),
  email: z.string()
    .email('Please enter a valid email address')
    .max(254, 'Email address is too long'),
  phone: z.string()
    .regex(/^[\+]?[\d\s\-\(\)]{7,20}$/, 'Please enter a valid phone number')
    .optional()
    .or(z.literal('')),
  
  // Feedback Content
  category: z.enum(['product_quality', 'customer_service', 'delivery', 'pricing', 'website', 'other'], {
    required_error: 'Please select a feedback category',
  }),
  subject: z.string()
    .min(5, 'Subject must be at least 5 characters')
    .max(100, 'Subject must be less than 100 characters'),
  message: z.string()
    .min(20, 'Message must be at least 20 characters')
    .max(2000, 'Message must be less than 2000 characters'),
  
  // Rating
  overallRating: z.number()
    .min(1, 'Please provide a rating')
    .max(5, 'Rating must be between 1 and 5'),
  
  // Follow-up
  allowContact: z.boolean(),
  urgency: z.enum(['low', 'medium', 'high'], {
    required_error: 'Please select urgency level',
  }),
});

type FormData = z.infer<typeof schema>;

const B2BFeedbackForm = () => {
  const { t } = useTranslation();
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'submitting' | 'success' | 'error'>('idle');
  const [submitMessage, setSubmitMessage] = useState<string>('');

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    watch,
    reset,
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      overallRating: 5,
      category: 'product_quality',
      urgency: 'medium',
      allowContact: true,
    }
  });

  // Watch rating for dynamic display
  const rating = watch('overallRating');

  const onSubmit = async (data: FormData) => {
    console.log('B2B Feedback submitted:', data);
    setSubmitStatus('submitting');
    
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000';
      const apiKey = import.meta.env.VITE_API_KEY || 'dev-api-key-1';
      const templateId = 'b2b-feedback';
      
      const response = await fetch(`${apiUrl}/api/templates/${templateId}/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': apiKey
        },
        body: JSON.stringify({
          data: data,
          submitted_from: 'B2B Feedback Form - Enhanced'
        }),
      });
      
      if (response.ok) {
        const result = await response.json();
        setSubmitStatus('success');
        setSubmitMessage(t('form.success', 'Thank you for your feedback! We appreciate your input and will review it carefully.'));
        reset(); // Clear form after successful submission
      } else {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Failed to submit feedback');
      }
    } catch (error) {
      console.error('Form submission error:', error);
      setSubmitStatus('error');
      setSubmitMessage(
        error instanceof Error 
          ? error.message 
          : t('form.error', 'An error occurred while submitting your feedback. Please try again.')
      );
    }
  };

  const renderStars = (currentRating: number) => {
    return [1, 2, 3, 4, 5].map((star) => (
      <label key={star} className="cursor-pointer">
        <input
          type="radio"
          {...register('overallRating', { valueAsNumber: true })}
          value={star}
          className="sr-only"
        />
        <svg
          className={`w-8 h-8 transition-colors ${
            star <= currentRating ? 'text-yellow-400' : 'text-gray-300'
          } hover:text-yellow-500`}
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
        </svg>
      </label>
    ));
  };

  return (
    <div className="max-w-4xl mx-auto p-6 bg-white rounded-lg shadow-md">
      {/* Header */}
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          {t('feedback.title', 'B2B Customer Feedback')}
        </h1>
        <p className="text-gray-600">
          {t('feedback.subtitle', 'Help us improve our products and services with your valuable feedback')}
        </p>
      </div>

      {/* Status Messages */}
      {submitStatus === 'success' && (
        <div className="mb-6 p-4 bg-green-50 border border-green-200 rounded-md">
          <div className="flex">
            <svg className="w-5 h-5 text-green-400 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            <div className="ml-3">
              <p className="text-sm font-medium text-green-800">{submitMessage}</p>
            </div>
          </div>
        </div>
      )}

      {submitStatus === 'error' && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
          <div className="flex">
            <svg className="w-5 h-5 text-red-400 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
            </svg>
            <div className="ml-3">
              <p className="text-sm font-medium text-red-800">{submitMessage}</p>
            </div>
          </div>
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
        
        {/* Company Information Section */}
        <div className="bg-gray-50 p-6 rounded-lg">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            {t('feedback.companyInfo', 'Company Information')}
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Company Name */}
            <div>
              <label htmlFor="companyName" className="block text-sm font-medium text-gray-700 mb-2">
                {t('feedback.companyName', 'Company Name')} *
              </label>
              <input
                id="companyName"
                type="text"
                {...register('companyName')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder={t('feedback.companyNamePlaceholder', 'Enter your company name')}
              />
              {errors.companyName && (
                <p className="mt-1 text-sm text-red-600">{errors.companyName.message}</p>
              )}
            </div>

            {/* Contact Person */}
            <div>
              <label htmlFor="contactPerson" className="block text-sm font-medium text-gray-700 mb-2">
                {t('feedback.contactPerson', 'Contact Person')} *
              </label>
              <input
                id="contactPerson"
                type="text"
                {...register('contactPerson')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder={t('feedback.contactPersonPlaceholder', 'Your full name')}
              />
              {errors.contactPerson && (
                <p className="mt-1 text-sm text-red-600">{errors.contactPerson.message}</p>
              )}
            </div>

            {/* Email */}
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                {t('feedback.email', 'Email Address')} *
              </label>
              <input
                id="email"
                type="email"
                {...register('email')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder={t('feedback.emailPlaceholder', 'your.email@company.com')}
              />
              {errors.email && (
                <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
              )}
            </div>

            {/* Phone */}
            <div>
              <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-2">
                {t('feedback.phone', 'Phone Number')} <span className="text-gray-500">({t('feedback.optional', 'optional')})</span>
              </label>
              <input
                id="phone"
                type="tel"
                {...register('phone')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder={t('feedback.phonePlaceholder', '+46 70 123 45 67')}
              />
              {errors.phone && (
                <p className="mt-1 text-sm text-red-600">{errors.phone.message}</p>
              )}
            </div>
          </div>
        </div>

        {/* Feedback Content Section */}
        <div className="bg-blue-50 p-6 rounded-lg">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            {t('feedback.feedbackContent', 'Feedback Details')}
          </h2>

          {/* Overall Rating */}
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-3">
              {t('feedback.overallRating', 'Overall Rating')} *
            </label>
            <div className="flex items-center space-x-2">
              {renderStars(rating)}
              <span className="ml-4 text-sm text-gray-600">
                ({rating}/5 - {rating >= 4 ? t('feedback.excellent', 'Excellent') : 
                              rating >= 3 ? t('feedback.good', 'Good') : 
                              rating >= 2 ? t('feedback.average', 'Average') : 
                              t('feedback.poor', 'Poor')})
              </span>
            </div>
            {errors.overallRating && (
              <p className="mt-1 text-sm text-red-600">{errors.overallRating.message}</p>
            )}
          </div>

          {/* Category */}
          <div className="mb-6">
            <label htmlFor="category" className="block text-sm font-medium text-gray-700 mb-2">
              {t('feedback.category', 'Feedback Category')} *
            </label>
            <select
              id="category"
              {...register('category')}
              className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            >
              <option value="product_quality">{t('feedback.categories.productQuality', 'Product Quality')}</option>
              <option value="customer_service">{t('feedback.categories.customerService', 'Customer Service')}</option>
              <option value="delivery">{t('feedback.categories.delivery', 'Delivery & Logistics')}</option>
              <option value="pricing">{t('feedback.categories.pricing', 'Pricing')}</option>
              <option value="website">{t('feedback.categories.website', 'Website & Online Experience')}</option>
              <option value="other">{t('feedback.categories.other', 'Other')}</option>
            </select>
            {errors.category && (
              <p className="mt-1 text-sm text-red-600">{errors.category.message}</p>
            )}
          </div>

          {/* Subject */}
          <div className="mb-6">
            <label htmlFor="subject" className="block text-sm font-medium text-gray-700 mb-2">
              {t('feedback.subject', 'Subject')} *
            </label>
            <input
              id="subject"
              type="text"
              {...register('subject')}
              className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder={t('feedback.subjectPlaceholder', 'Brief summary of your feedback')}
            />
            {errors.subject && (
              <p className="mt-1 text-sm text-red-600">{errors.subject.message}</p>
            )}
          </div>

          {/* Message */}
          <div className="mb-6">
            <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-2">
              {t('feedback.message', 'Detailed Feedback')} *
            </label>
            <textarea
              id="message"
              rows={6}
              {...register('message')}
              className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder={t('feedback.messagePlaceholder', 'Please provide detailed feedback about your experience with our products or services...')}
            />
            <p className="mt-1 text-xs text-gray-500">
              {t('feedback.charactersRemaining', 'Characters')} : {watch('message')?.length || 0}/2000
            </p>
            {errors.message && (
              <p className="mt-1 text-sm text-red-600">{errors.message.message}</p>
            )}
          </div>
        </div>

        {/* Additional Options Section */}
        <div className="bg-yellow-50 p-6 rounded-lg">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">
            {t('feedback.additionalOptions', 'Additional Options')}
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Urgency */}
            <div>
              <label htmlFor="urgency" className="block text-sm font-medium text-gray-700 mb-2">
                {t('feedback.urgency', 'Urgency Level')} *
              </label>
              <select
                id="urgency"
                {...register('urgency')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="low">{t('feedback.urgency.low', 'Low - General feedback')}</option>
                <option value="medium">{t('feedback.urgency.medium', 'Medium - Improvement suggestion')}</option>
                <option value="high">{t('feedback.urgency.high', 'High - Issue requiring attention')}</option>
              </select>
              {errors.urgency && (
                <p className="mt-1 text-sm text-red-600">{errors.urgency.message}</p>
              )}
            </div>

            {/* Allow Contact */}
            <div className="flex items-center">
              <input
                id="allowContact"
                type="checkbox"
                {...register('allowContact')}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label htmlFor="allowContact" className="ml-2 block text-sm text-gray-700">
                {t('feedback.allowContact', 'Allow us to contact you for follow-up questions')}
              </label>
            </div>
          </div>
        </div>

        {/* Submit Button */}
        <div className="flex justify-center pt-6">
          <button
            type="submit"
            disabled={isSubmitting || submitStatus === 'submitting'}
            className="inline-flex items-center px-8 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors duration-200"
          >
            {submitStatus === 'submitting' ? (
              <>
                <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                {t('feedback.submitting', 'Submitting Feedback...')}
              </>
            ) : (
              <>
                <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                </svg>
                {t('feedback.submit', 'Submit Feedback')}
              </>
            )}
          </button>
        </div>

        {/* Information Note */}
        <div className="mt-6 p-4 bg-gray-100 rounded-md">
          <p className="text-xs text-gray-600 text-center">
            {t('feedback.privacyNote', 'Your feedback is important to us. All information will be handled confidentially and used only to improve our services.')}
          </p>
        </div>
      </form>
    </div>
  );
};

export default B2BFeedbackForm;
