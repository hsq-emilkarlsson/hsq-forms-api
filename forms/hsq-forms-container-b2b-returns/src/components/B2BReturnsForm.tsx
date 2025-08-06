import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useTranslation } from 'react-i18next';

const schema = z.object({
  companyName: z.string().min(1, 'Company name is required'),
  contactPerson: z.string().min(1, 'Contact person is required'),
  email: z.string().email('Invalid email address'),
  phone: z.string().optional(),
  orderNumber: z.string().min(1, 'Order number is required'),
  productModel: z.string().min(1, 'Product model is required'),
  serialNumber: z.string().optional(),
  purchaseDate: z.string().min(1, 'Purchase date is required'),
  returnReason: z.enum(['defective', 'not_as_described', 'damaged', 'wrong_item', 'other']),
  condition: z.enum(['new', 'used', 'damaged']),
  description: z.string().min(10, 'Description must be at least 10 characters'),
  refundMethod: z.enum(['original_payment', 'store_credit', 'replacement']),
  urgency: z.enum(['low', 'medium', 'high']),
});

type FormData = z.infer<typeof schema>;

const B2BReturnsForm = () => {
  const { t } = useTranslation();
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      urgency: 'medium',
      refundMethod: 'original_payment',
      condition: 'used',
    }
  });

  const onSubmit = async (data: FormData) => {
    console.log('B2B Returns submitted:', data);
    
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000';
      const response = await fetch(`${apiUrl}/api/templates/b2b-returns/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          data: data,
          submitted_from: 'B2B Returns Form - Sitecore Embedded'
        }),
      });
      
      if (response.ok) {
        alert(t('form.success', 'Return request submitted successfully!'));
      } else {
        throw new Error('Failed to submit form');
      }
    } catch (error) {
      console.error('Form submission error:', error);
      alert(t('form.error', 'An error occurred while submitting the form. Please try again.'));
    }
  };

  return (
    <div className="max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md">
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Company Information */}
        <div className="border-b border-gray-200 pb-6">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {t('returns.companyInfo', 'Company Information')}
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="companyName" className="block text-sm font-medium text-gray-700">
                {t('returns.companyName', 'Company Name')} *
              </label>
              <input
                id="companyName"
                type="text"
                {...register('companyName')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.companyNamePlaceholder', 'Enter your company name')}
              />
              {errors.companyName && (
                <p className="text-red-500 text-sm mt-1">{errors.companyName.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="contactPerson" className="block text-sm font-medium text-gray-700">
                {t('returns.contactPerson', 'Contact Person')} *
              </label>
              <input
                id="contactPerson"
                type="text"
                {...register('contactPerson')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.contactPersonPlaceholder', 'Enter contact person name')}
              />
              {errors.contactPerson && (
                <p className="text-red-500 text-sm mt-1">{errors.contactPerson.message}</p>
              )}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                {t('returns.email', 'Email Address')} *
              </label>
              <input
                id="email"
                type="email"
                {...register('email')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.emailPlaceholder', 'Enter your email address')}
              />
              {errors.email && (
                <p className="text-red-500 text-sm mt-1">{errors.email.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="phone" className="block text-sm font-medium text-gray-700">
                {t('returns.phone', 'Phone Number')}
              </label>
              <input
                id="phone"
                type="tel"
                {...register('phone')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.phonePlaceholder', 'Enter your phone number')}
              />
            </div>
          </div>
        </div>

        {/* Product Information */}
        <div className="border-b border-gray-200 pb-6">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {t('returns.productInfo', 'Product Information')}
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="orderNumber" className="block text-sm font-medium text-gray-700">
                {t('returns.orderNumber', 'Order Number')} *
              </label>
              <input
                id="orderNumber"
                type="text"
                {...register('orderNumber')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.orderNumberPlaceholder', 'Enter order number')}
              />
              {errors.orderNumber && (
                <p className="text-red-500 text-sm mt-1">{errors.orderNumber.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="productModel" className="block text-sm font-medium text-gray-700">
                {t('returns.productModel', 'Product Model')} *
              </label>
              <input
                id="productModel"
                type="text"
                {...register('productModel')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.productModelPlaceholder', 'Enter product model')}
              />
              {errors.productModel && (
                <p className="text-red-500 text-sm mt-1">{errors.productModel.message}</p>
              )}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
            <div>
              <label htmlFor="serialNumber" className="block text-sm font-medium text-gray-700">
                {t('returns.serialNumber', 'Serial Number')}
              </label>
              <input
                id="serialNumber"
                type="text"
                {...register('serialNumber')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.serialNumberPlaceholder', 'Enter serial number if available')}
              />
            </div>

            <div>
              <label htmlFor="purchaseDate" className="block text-sm font-medium text-gray-700">
                {t('returns.purchaseDate', 'Purchase Date')} *
              </label>
              <input
                id="purchaseDate"
                type="date"
                {...register('purchaseDate')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
              />
              {errors.purchaseDate && (
                <p className="text-red-500 text-sm mt-1">{errors.purchaseDate.message}</p>
              )}
            </div>
          </div>
        </div>

        {/* Return Details */}
        <div className="border-b border-gray-200 pb-6">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {t('returns.returnDetails', 'Return Details')}
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="returnReason" className="block text-sm font-medium text-gray-700">
                {t('returns.returnReason', 'Reason for Return')} *
              </label>
              <select
                id="returnReason"
                {...register('returnReason')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
              >
                <option value="">{t('returns.selectReason', 'Select reason')}</option>
                <option value="defective">{t('returns.defective', 'Defective/Not Working')}</option>
                <option value="not_as_described">{t('returns.notAsDescribed', 'Not as Described')}</option>
                <option value="damaged">{t('returns.damaged', 'Damaged in Shipping')}</option>
                <option value="wrong_item">{t('returns.wrongItem', 'Wrong Item Received')}</option>
                <option value="other">{t('returns.other', 'Other')}</option>
              </select>
              {errors.returnReason && (
                <p className="text-red-500 text-sm mt-1">{errors.returnReason.message}</p>
              )}
            </div>

            <div>
              <label htmlFor="condition" className="block text-sm font-medium text-gray-700">
                {t('returns.condition', 'Product Condition')} *
              </label>
              <select
                id="condition"
                {...register('condition')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
              >
                <option value="new">{t('returns.conditionNew', 'New/Unused')}</option>
                <option value="used">{t('returns.conditionUsed', 'Used/Opened')}</option>
                <option value="damaged">{t('returns.conditionDamaged', 'Damaged')}</option>
              </select>
            </div>
          </div>

          <div className="mt-4">
            <label htmlFor="description" className="block text-sm font-medium text-gray-700">
              {t('returns.description', 'Detailed Description')} *
            </label>
            <textarea
              id="description"
              rows={4}
              {...register('description')}
              className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
              placeholder={t('returns.descriptionPlaceholder', 'Please provide detailed information about the return...')}
            />
            {errors.description && (
              <p className="text-red-500 text-sm mt-1">{errors.description.message}</p>
            )}
          </div>
        </div>

        {/* Return Preferences */}
        <div className="pb-6">
          <h2 className="text-lg font-medium text-gray-900 mb-4">
            {t('returns.preferences', 'Return Preferences')}
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="refundMethod" className="block text-sm font-medium text-gray-700">
                {t('returns.refundMethod', 'Preferred Resolution')} *
              </label>
              <select
                id="refundMethod"
                {...register('refundMethod')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
              >
                <option value="original_payment">{t('returns.originalPayment', 'Refund to Original Payment')}</option>
                <option value="store_credit">{t('returns.storeCredit', 'Store Credit')}</option>
                <option value="replacement">{t('returns.replacement', 'Product Replacement')}</option>
              </select>
            </div>

            <div>
              <label htmlFor="urgency" className="block text-sm font-medium text-gray-700">
                {t('returns.urgency', 'Urgency Level')} *
              </label>
              <select
                id="urgency"
                {...register('urgency')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
              >
                <option value="low">{t('returns.lowUrgency', 'Low (7-10 business days)')}</option>
                <option value="medium">{t('returns.mediumUrgency', 'Medium (3-5 business days)')}</option>
                <option value="high">{t('returns.highUrgency', 'High (1-2 business days)')}</option>
              </select>
            </div>
          </div>
        </div>

        <button
          type="submit"
          disabled={isSubmitting}
          className="w-full bg-blue-600 text-white py-3 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isSubmitting 
            ? t('returns.submitting', 'Submitting...') 
            : t('returns.submit', 'Submit Return Request')
          }
        </button>
      </form>
    </div>
  );
};

export default B2BReturnsForm;