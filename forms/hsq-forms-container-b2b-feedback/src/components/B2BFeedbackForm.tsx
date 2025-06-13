import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useTranslation } from 'react-i18next';

const schema = z.object({
  companyName: z.string().min(1, 'Company name is required'),
  contactPerson: z.string().min(1, 'Contact person is required'),
  email: z.string().email('Invalid email address'),
  phone: z.string().optional(),
  businessType: z.string().min(1, 'Business type is required'),
  feedbackCategory: z.enum(['product', 'service', 'partnership', 'support', 'other']),
  message: z.string().min(10, 'Message must be at least 10 characters'),
  priority: z.enum(['low', 'medium', 'high']),
  followUpRequested: z.boolean(),
});

type FormData = z.infer<typeof schema>;

const B2BFeedbackForm = () => {
  const { t } = useTranslation();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      priority: 'medium',
      followUpRequested: false,
    }
  });

  const onSubmit = async (data: FormData) => {
    console.log('B2B Feedback submitted:', data);
    
    try {
      const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost:8000';
      const response = await fetch(`${apiUrl}/api/forms/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          form_type: 'b2b-feedback',
          data: data,
        }),
      });
      
      if (response.ok) {
        alert(t('form.success'));
      } else {
        throw new Error('Failed to submit form');
      }
    } catch (error) {
      console.error('Form submission error:', error);
      alert(t('form.error'));
    }
  };

  return (
    <div className="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        {t('b2b.title', 'B2B Feedback Form')}
      </h1>
      
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Company Information */}
        <div className="border-b border-gray-200 pb-6">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {t('b2b.companyInfo', 'Company Information')}
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="companyName" className="block text-sm font-medium text-gray-700">
                {t('b2b.companyName', 'Company Name')} *
              </label>
              <input
                id="companyName"
                type="text"
                {...register('companyName')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                placeholder={t('b2b.companyNamePlaceholder', 'Enter your company name')}
              />
              {errors.companyName && (
                <p className="text-red-500 text-sm mt-1">{errors.companyName.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="businessType" className="block text-sm font-medium text-gray-700">
                {t('b2b.businessType', 'Business Type')} *
              </label>
              <select
                id="businessType"
                {...register('businessType')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">{t('b2b.selectBusinessType', 'Select business type')}</option>
                <option value="technology">{t('b2b.technology', 'Technology')}</option>
                <option value="manufacturing">{t('b2b.manufacturing', 'Manufacturing')}</option>
                <option value="consulting">{t('b2b.consulting', 'Consulting')}</option>
                <option value="retail">{t('b2b.retail', 'Retail')}</option>
                <option value="healthcare">{t('b2b.healthcare', 'Healthcare')}</option>
                <option value="finance">{t('b2b.finance', 'Finance')}</option>
                <option value="other">{t('b2b.other', 'Other')}</option>
              </select>
              {errors.businessType && (
                <p className="text-red-500 text-sm mt-1">{errors.businessType.message}</p>
              )}
            </div>
          </div>
        </div>

        {/* Contact Information */}
        <div className="border-b border-gray-200 pb-6">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {t('b2b.contactInfo', 'Contact Information')}
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="contactPerson" className="block text-sm font-medium text-gray-700">
                {t('b2b.contactPerson', 'Contact Person')} *
              </label>
              <input
                id="contactPerson"
                type="text"
                {...register('contactPerson')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                placeholder={t('b2b.contactPersonPlaceholder', 'Enter contact person name')}
              />
              {errors.contactPerson && (
                <p className="text-red-500 text-sm mt-1">{errors.contactPerson.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                {t('b2b.email', 'Email Address')} *
              </label>
              <input
                id="email"
                type="email"
                {...register('email')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                placeholder={t('b2b.emailPlaceholder', 'Enter email address')}
              />
              {errors.email && (
                <p className="text-red-500 text-sm mt-1">{errors.email.message}</p>
              )}
            </div>

            <div className="md:col-span-2">
              <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
                {t('b2b.phone', 'Phone Number')} ({t('b2b.optional', 'Optional')})
              </label>
              <input
                id="phone"
                type="tel"
                {...register('phone')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                placeholder={t('b2b.phonePlaceholder', 'Enter phone number')}
              />
            </div>
          </div>
        </div>

        {/* Feedback Details */}
        <div className="border-b border-gray-200 pb-6">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {t('b2b.feedbackDetails', 'Feedback Details')}
          </h2>
          
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label htmlFor="feedbackCategory" className="block text-sm font-medium text-gray-700">
                  {t('b2b.category', 'Feedback Category')} *
                </label>
                <select
                  id="feedbackCategory"
                  {...register('feedbackCategory')}
                  className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">{t('b2b.selectCategory', 'Select category')}</option>
                  <option value="product">{t('b2b.categoryProduct', 'Product')}</option>
                  <option value="service">{t('b2b.categoryService', 'Service')}</option>
                  <option value="partnership">{t('b2b.categoryPartnership', 'Partnership')}</option>
                  <option value="support">{t('b2b.categorySupport', 'Support')}</option>
                  <option value="other">{t('b2b.categoryOther', 'Other')}</option>
                </select>
                {errors.feedbackCategory && (
                  <p className="text-red-500 text-sm mt-1">{errors.feedbackCategory.message}</p>
                )}
              </div>

              <div>
                <label htmlFor="priority" className="block text-sm font-medium text-gray-700">
                  {t('b2b.priority', 'Priority')} *
                </label>
                <select
                  id="priority"
                  {...register('priority')}
                  className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="low">{t('b2b.priorityLow', 'Low')}</option>
                  <option value="medium">{t('b2b.priorityMedium', 'Medium')}</option>
                  <option value="high">{t('b2b.priorityHigh', 'High')}</option>
                </select>
              </div>
            </div>

            <div>
              <label htmlFor="message" className="block text-sm font-medium text-gray-700">
                {t('b2b.message', 'Message')} *
              </label>
              <textarea
                id="message"
                rows={6}
                {...register('message')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                placeholder={t('b2b.messagePlaceholder', 'Please provide detailed feedback...')}
              />
              {errors.message && (
                <p className="text-red-500 text-sm mt-1">{errors.message.message}</p>
              )}
            </div>

            <div className="flex items-center">
              <input
                id="followUpRequested"
                type="checkbox"
                {...register('followUpRequested')}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label htmlFor="followUpRequested" className="ml-2 block text-sm text-gray-900">
                {t('b2b.followUp', 'I would like a follow-up response')}
              </label>
            </div>
          </div>
        </div>

        {/* Submit Button */}
        <div className="pt-4">
          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isSubmitting ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
                {t('b2b.submitting', 'Submitting...')}
              </div>
            ) : (
              t('b2b.submit', 'Submit Feedback')
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default B2BFeedbackForm;
