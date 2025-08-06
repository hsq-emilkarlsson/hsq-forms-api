import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useTranslation } from 'react-i18next';
import { useState, useEffect } from 'react';

const schema = z.object({
  firstName: z.string().min(1, 'First name is required'),
  lastName: z.string().min(1, 'Last name is required'),
  email: z.string().email('Invalid email address'),
  phone: z.string().optional(),
  address: z.string().min(1, 'Address is required'),
  postalCode: z.string().min(1, 'Postal code is required'),
  city: z.string().min(1, 'City is required'),
  orderNumber: z.string().optional(),
  productModel: z.string().min(1, 'Product model is required'),
  serialNumber: z.string().optional(),
  purchaseDate: z.string().min(1, 'Purchase date is required'),
  returnReason: z.enum(['defective', 'not_as_described', 'damaged', 'wrong_item', 'other']),
  condition: z.enum(['new', 'used', 'damaged']),
  description: z.string().min(10, 'Description must be at least 10 characters'),
  refundMethod: z.enum(['original_payment', 'store_credit', 'replacement']),
});

type FormData = z.infer<typeof schema>;

interface B2CReturnsFormProps {
  isEmbedded?: boolean;
  compact?: boolean;
}

const B2CReturnsForm = ({ isEmbedded = false, compact = false }: B2CReturnsFormProps) => {
  const { t } = useTranslation();
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [isIframeContext, setIsIframeContext] = useState(false);

  // Detect if running in iframe
  useEffect(() => {
    const isInIframe = window.self !== window.top;
    setIsIframeContext(isInIframe || isEmbedded);
  }, [isEmbedded]);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      refundMethod: 'original_payment',
      condition: 'used',
    }
  });

  const onSubmit = async (data: FormData) => {
    console.log('B2C Returns submitted:', data);
    setSubmitStatus('idle');
    
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';
      // Using B2B Support template temporarily for B2C returns
      const templateId = '958915ec-fed1-4e7e-badd-4598502fe6a1';
      
      const response = await fetch(`${apiUrl}/api/templates/${templateId}/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          data: data,
          submitted_from: 'B2C Returns Form - Sitecore Embedded'
        }),
      });
      
      if (response.ok) {
        setSubmitStatus('success');
      } else {
        throw new Error('Failed to submit form');
      }
    } catch (error) {
      console.error('Form submission error:', error);
      setSubmitStatus('error');
    }
  };

  // Dynamic CSS classes based on context
  const containerClasses = isIframeContext || compact 
    ? "iframe-form-container w-full"
    : "max-w-2xl mx-auto p-6 bg-white rounded-lg shadow-md";

  const gridClasses = compact 
    ? "grid grid-cols-1 gap-3"
    : "grid grid-cols-1 md:grid-cols-2 gap-4";

  const spacingClasses = compact ? "space-y-4" : "space-y-6";

  return (
    <div className={containerClasses}>
      {/* Accessibility announcements */}
      <div 
        aria-live="polite" 
        aria-relevant="additions text"
        className="sr-only"
        id="form-announcements"
      >
        {submitStatus === 'success' && t('form.success', 'Return request submitted successfully!')}
        {submitStatus === 'error' && t('form.error', 'An error occurred while submitting the form.')}
      </div>

      {/* Success Message */}
      {submitStatus === 'success' && (
        <div className="success-message" role="alert">
          <strong>{t('form.success', 'Return request submitted successfully!')}</strong>
          <p>{t('form.successDetails', 'We will contact you within 2-3 business days regarding your return.')}</p>
        </div>
      )}

      {/* Error Message */}
      {submitStatus === 'error' && (
        <div className="error-message bg-red-50 border border-red-200 rounded-md p-3 mb-4" role="alert">
          <strong>{t('form.error', 'An error occurred while submitting the form.')}</strong>
          <p>{t('form.errorDetails', 'Please check your information and try again.')}</p>
        </div>
      )}

      <form 
        onSubmit={handleSubmit(onSubmit)} 
        className={`${spacingClasses} ${isSubmitting ? 'form-loading' : ''}`}
        aria-labelledby="b2c-returns-form-title"
        noValidate
      >
        {/* Form Title */}
        <h1 id="b2c-returns-form-title" className={compact ? "text-lg font-medium text-gray-900 mb-3" : "text-xl font-semibold text-gray-900 mb-4"}>
          {t('returns.title', 'B2C Returns Form')}
        </h1>

        {/* Personal Information */}
        <fieldset className="border-b border-gray-200 pb-4">
          <legend className={compact ? "text-base font-medium text-gray-900 mb-3" : "text-lg font-medium text-gray-900 mb-4"}>
            {t('returns.personalInfo', 'Personal Information')}
          </legend>
          
          <div className={gridClasses}>
            <div>
              <label 
                htmlFor="firstName" 
                className="block text-sm font-medium text-gray-700"
                id="firstName-label"
              >
                {t('returns.firstName', 'First Name')} *
              </label>
              <input
                id="firstName"
                type="text"
                {...register('firstName')}
                aria-labelledby="firstName-label"
                aria-describedby={errors.firstName ? 'firstName-error' : undefined}
                aria-required="true"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.firstNamePlaceholder', 'Enter your first name')}
              />
              {errors.firstName && (
                <p id="firstName-error" className="text-red-500 text-sm mt-1" role="alert">
                  {errors.firstName.message}
                </p>
              )}
            </div>

            <div>
              <label 
                htmlFor="lastName" 
                className="block text-sm font-medium text-gray-700"
                id="lastName-label"
              >
                {t('returns.lastName', 'Last Name')} *
              </label>
              <input
                id="lastName"
                type="text"
                {...register('lastName')}
                aria-labelledby="lastName-label"
                aria-describedby={errors.lastName ? 'lastName-error' : undefined}
                aria-required="true"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.lastNamePlaceholder', 'Enter your last name')}
              />
              {errors.lastName && (
                <p id="lastName-error" className="text-red-500 text-sm mt-1" role="alert">
                  {errors.lastName.message}
                </p>
              )}
            </div>
          </div>

          <div className={`${gridClasses} ${compact ? 'mt-3' : 'mt-4'}`}>
            <div>
              <label 
                htmlFor="email" 
                className="block text-sm font-medium text-gray-700"
                id="email-label"
              >
                {t('returns.email', 'Email Address')} *
              </label>
              <input
                id="email"
                type="email"
                {...register('email')}
                aria-labelledby="email-label"
                aria-describedby={errors.email ? 'email-error' : undefined}
                aria-required="true"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.emailPlaceholder', 'Enter your email address')}
              />
              {errors.email && (
                <p id="email-error" className="text-red-500 text-sm mt-1" role="alert">
                  {errors.email.message}
                </p>
              )}
            </div>

            <div>
              <label 
                htmlFor="phone" 
                className="block text-sm font-medium text-gray-700"
                id="phone-label"
              >
                {t('returns.phone', 'Phone Number')}
              </label>
              <input
                id="phone"
                type="tel"
                {...register('phone')}
                aria-labelledby="phone-label"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.phonePlaceholder', 'Enter your phone number')}
              />
            </div>
          </div>

          <div className={`grid grid-cols-1 ${compact ? 'md:grid-cols-2' : 'md:grid-cols-3'} gap-4 ${compact ? 'mt-3' : 'mt-4'}`}>
            <div className={compact ? '' : 'md:col-span-1'}>
              <label 
                htmlFor="address" 
                className="block text-sm font-medium text-gray-700"
                id="address-label"
              >
                {t('returns.address', 'Address')} *
              </label>
              <input
                id="address"
                type="text"
                {...register('address')}
                aria-labelledby="address-label"
                aria-describedby={errors.address ? 'address-error' : undefined}
                aria-required="true"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.addressPlaceholder', 'Enter your address')}
              />
              {errors.address && (
                <p id="address-error" className="text-red-500 text-sm mt-1" role="alert">
                  {errors.address.message}
                </p>
              )}
            </div>

            <div>
              <label 
                htmlFor="postalCode" 
                className="block text-sm font-medium text-gray-700"
                id="postalCode-label"
              >
                {t('returns.postalCode', 'Postal Code')} *
              </label>
              <input
                id="postalCode"
                type="text"
                {...register('postalCode')}
                aria-labelledby="postalCode-label"
                aria-describedby={errors.postalCode ? 'postalCode-error' : undefined}
                aria-required="true"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.postalCodePlaceholder', 'Enter postal code')}
              />
              {errors.postalCode && (
                <p id="postalCode-error" className="text-red-500 text-sm mt-1" role="alert">
                  {errors.postalCode.message}
                </p>
              )}
            </div>

            <div>
              <label 
                htmlFor="city" 
                className="block text-sm font-medium text-gray-700"
                id="city-label"
              >
                {t('returns.city', 'City')} *
              </label>
              <input
                id="city"
                type="text"
                {...register('city')}
                aria-labelledby="city-label"
                aria-describedby={errors.city ? 'city-error' : undefined}
                aria-required="true"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.cityPlaceholder', 'Enter your city')}
              />
              {errors.city && (
                <p id="city-error" className="text-red-500 text-sm mt-1" role="alert">
                  {errors.city.message}
                </p>
              )}
            </div>
          </div>
        </fieldset>

        {/* Product Information */}
        <fieldset className="border-b border-gray-200 pb-4">
          <legend className={compact ? "text-base font-medium text-gray-900 mb-3" : "text-lg font-medium text-gray-900 mb-4"}>
            {t('returns.productInfo', 'Product Information')}
          </legend>
          
          <div className={gridClasses}>
            <div>
              <label 
                htmlFor="orderNumber" 
                className="block text-sm font-medium text-gray-700"
                id="orderNumber-label"
              >
                {t('returns.orderNumber', 'Order Number')}
              </label>
              <input
                id="orderNumber"
                type="text"
                {...register('orderNumber')}
                aria-labelledby="orderNumber-label"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.orderNumberPlaceholder', 'Enter order number (if available)')}
              />
            </div>

            <div>
              <label 
                htmlFor="productModel" 
                className="block text-sm font-medium text-gray-700"
                id="productModel-label"
              >
                {t('returns.productModel', 'Product Model')} *
              </label>
              <input
                id="productModel"
                type="text"
                {...register('productModel')}
                aria-labelledby="productModel-label"
                aria-describedby={errors.productModel ? 'productModel-error' : undefined}
                aria-required="true"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.productModelPlaceholder', 'Enter product model')}
              />
              {errors.productModel && (
                <p id="productModel-error" className="text-red-500 text-sm mt-1" role="alert">
                  {errors.productModel.message}
                </p>
              )}
            </div>
          </div>

          <div className={`${gridClasses} ${compact ? 'mt-3' : 'mt-4'}`}>
            <div>
              <label 
                htmlFor="serialNumber" 
                className="block text-sm font-medium text-gray-700"
                id="serialNumber-label"
              >
                {t('returns.serialNumber', 'Serial Number')}
              </label>
              <input
                id="serialNumber"
                type="text"
                {...register('serialNumber')}
                aria-labelledby="serialNumber-label"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
                placeholder={t('returns.serialNumberPlaceholder', 'Enter serial number if available')}
              />
            </div>

            <div>
              <label 
                htmlFor="purchaseDate" 
                className="block text-sm font-medium text-gray-700"
                id="purchaseDate-label"
              >
                {t('returns.purchaseDate', 'Purchase Date')} *
              </label>
              <input
                id="purchaseDate"
                type="date"
                {...register('purchaseDate')}
                aria-labelledby="purchaseDate-label"
                aria-describedby={errors.purchaseDate ? 'purchaseDate-error' : undefined}
                aria-required="true"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
              />
              {errors.purchaseDate && (
                <p id="purchaseDate-error" className="text-red-500 text-sm mt-1" role="alert">
                  {errors.purchaseDate.message}
                </p>
              )}
            </div>
          </div>
        </fieldset>

        {/* Return Details */}
        <fieldset className="border-b border-gray-200 pb-4">
          <legend className={compact ? "text-base font-medium text-gray-900 mb-3" : "text-lg font-medium text-gray-900 mb-4"}>
            {t('returns.returnDetails', 'Return Details')}
          </legend>
          
          <div className={gridClasses}>
            <div>
              <label 
                htmlFor="returnReason" 
                className="block text-sm font-medium text-gray-700"
                id="returnReason-label"
              >
                {t('returns.returnReason', 'Reason for Return')} *
              </label>
              <select
                id="returnReason"
                {...register('returnReason')}
                aria-labelledby="returnReason-label"
                aria-describedby={errors.returnReason ? 'returnReason-error' : undefined}
                aria-required="true"
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
                <p id="returnReason-error" className="text-red-500 text-sm mt-1" role="alert">
                  {errors.returnReason.message}
                </p>
              )}
            </div>

            <div>
              <label 
                htmlFor="condition" 
                className="block text-sm font-medium text-gray-700"
                id="condition-label"
              >
                {t('returns.condition', 'Product Condition')} *
              </label>
              <select
                id="condition"
                {...register('condition')}
                aria-labelledby="condition-label"
                aria-required="true"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
              >
                <option value="new">{t('returns.conditionNew', 'New/Unused')}</option>
                <option value="used">{t('returns.conditionUsed', 'Used/Opened')}</option>
                <option value="damaged">{t('returns.conditionDamaged', 'Damaged')}</option>
              </select>
            </div>
          </div>

          <div className={compact ? "mt-3" : "mt-4"}>
            <label 
              htmlFor="description" 
              className="block text-sm font-medium text-gray-700"
              id="description-label"
            >
              {t('returns.description', 'Detailed Description')} *
            </label>
            <textarea
              id="description"
              rows={compact ? 3 : 4}
              {...register('description')}
              aria-labelledby="description-label"
              aria-describedby={errors.description ? 'description-error' : undefined}
              aria-required="true"
              className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
              placeholder={t('returns.descriptionPlaceholder', 'Please provide detailed information about the return...')}
            />
            {errors.description && (
              <p id="description-error" className="text-red-500 text-sm mt-1" role="alert">
                {errors.description.message}
              </p>
            )}
          </div>
        </fieldset>

        {/* Return Preferences */}
        <fieldset className="pb-4">
          <legend className={compact ? "text-base font-medium text-gray-900 mb-3" : "text-lg font-medium text-gray-900 mb-4"}>
            {t('returns.preferences', 'Return Preferences')}
          </legend>
          
          <div className="grid grid-cols-1 gap-4">
            <div>
              <label 
                htmlFor="refundMethod" 
                className="block text-sm font-medium text-gray-700"
                id="refundMethod-label"
              >
                {t('returns.refundMethod', 'Preferred Resolution')} *
              </label>
              <select
                id="refundMethod"
                {...register('refundMethod')}
                aria-labelledby="refundMethod-label"
                aria-required="true"
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 p-2"
              >
                <option value="original_payment">{t('returns.originalPayment', 'Refund to Original Payment')}</option>
                <option value="store_credit">{t('returns.storeCredit', 'Store Credit')}</option>
                <option value="replacement">{t('returns.replacement', 'Product Replacement')}</option>
              </select>
            </div>
          </div>
        </fieldset>

        <button
          type="submit"
          disabled={isSubmitting || submitStatus === 'success'}
          aria-describedby="form-announcements"
          className={`w-full bg-blue-600 text-white py-3 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors ${compact ? 'py-2 text-sm' : 'py-3'}`}
        >
          {isSubmitting 
            ? t('returns.submitting', 'Submitting...') 
            : submitStatus === 'success'
            ? t('returns.submitted', 'Submitted')
            : t('returns.submit', 'Submit Return Request')
          }
        </button>
      </form>
    </div>
  );
};

export default B2CReturnsForm;