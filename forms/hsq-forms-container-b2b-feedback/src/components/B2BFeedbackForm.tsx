import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useTranslation } from 'react-i18next';

const schema = z.object({
  message: z.string().min(10, 'Message must be at least 10 characters'),
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
      <h1 className="text-2xl font-bold text-gray-900 mb-4">
        {t('feedback.title', 'Feedback Form')}
      </h1>
      
      {/* Description and Guidelines */}
      <div className="mb-6 p-4 bg-blue-50 border rounded-md" style={{ backgroundColor: '#f0f4f8', borderColor: '#273A60' }}>
        <p className="text-sm text-gray-700 mb-3">
          <strong>{t('feedback.description')}</strong>
        </p>
        <p className="text-sm text-gray-700 mb-3">
          {t('feedback.usage')}
        </p>
        <p className="text-sm text-gray-600">
          <strong>{t('feedback.note').split(':')[0]}:</strong> {t('feedback.note').split(':')[1]}
        </p>
      </div>
      
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Feedback Message */}
        <div>
          <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-2">
            {t('feedback.message', 'Din feedback')} *
          </label>
          <textarea
            id="message"
            rows={8}
            {...register('message')}
            className="mt-1 block w-full border-gray-300 rounded-md shadow-sm p-3 focus:outline-none focus:ring-2 focus:ring-offset-2"
            style={{ '--tw-ring-color': '#273A60', borderColor: '#273A60' } as React.CSSProperties}
            placeholder={t('feedback.messagePlaceholder', 'Dela med dig av dina idéer, förslag och synpunkter för att göra portalen bättre...')}
          />
          {errors.message && (
            <p className="text-red-500 text-sm mt-1">{errors.message.message}</p>
          )}
        </div>

        {/* File Upload */}
        <div>
          <label htmlFor="attachments" className="block text-sm font-medium text-gray-700 mb-2">
            {t('feedback.attachments', 'Bifogade filer')} ({t('feedback.optional', 'Valfritt')})
          </label>
          <div className="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md">
            <div className="space-y-1 text-center">
              <svg
                className="mx-auto h-12 w-12 text-gray-400"
                stroke="currentColor"
                fill="none"
                viewBox="0 0 48 48"
                aria-hidden="true"
              >
                <path
                  d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                  strokeWidth={2}
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
              <div className="flex text-sm text-gray-600">
                <label
                  htmlFor="attachments"
                  className="relative cursor-pointer bg-white rounded-md font-medium focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2"
                  style={{ color: '#273A60' }}
                >
                  <span>{t('feedback.uploadFile', 'Ladda upp fil')}</span>
                  <input
                    id="attachments"
                    name="attachments"
                    type="file"
                    multiple
                    accept="image/*,.pdf,.doc,.docx"
                    className="sr-only"
                  />
                </label>
                <p className="pl-1">{t('feedback.dragDrop', 'eller dra och släpp')}</p>
              </div>
              <p className="text-xs text-gray-500">
                {t('feedback.fileTypes', 'PNG, JPG, PDF, DOC upp till 10MB')}
              </p>
            </div>
          </div>
        </div>

        {/* Submit Button */}
        <div className="pt-4">
          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
            style={{ backgroundColor: '#273A60', '--tw-ring-color': '#273A60' } as React.CSSProperties}
          >
            {isSubmitting ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
                {t('feedback.submitting', 'Skickar...')}
              </div>
            ) : (
              t('feedback.submit', 'Skicka feedback')
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default B2BFeedbackForm;
