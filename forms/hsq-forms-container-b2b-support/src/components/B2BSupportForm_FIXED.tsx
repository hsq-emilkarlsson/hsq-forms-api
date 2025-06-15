import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useTranslation } from 'react-i18next';
import { useState, useEffect } from 'react';

const schema = z.object({
  supportType: z.enum(['technical', 'customer'], {
    required_error: 'Please select support type',
  }),
  customerNumber: z.string().min(1, 'Customer number is required'),
  email: z.string().email('Invalid email address'),
  companyName: z.string().min(1, 'Company name is required'),
  contactPerson: z.string().min(1, 'Contact person is required'),
  phone: z.string().optional(),
  // Technical support fields
  pncNumber: z.string().optional(),
  serialNumber: z.string().optional(),
  // Problem description
  subject: z.string().min(1, 'Subject is required'),
  problemDescription: z.string().min(10, 'Problem description must be at least 10 characters'),
  urgency: z.enum(['low', 'medium', 'high']),
  // File attachments
  attachments: z.array(z.instanceof(File)).optional(),
}).refine((data) => {
  // If technical support is selected, require either PNC or Serial Number
  if (data.supportType === 'technical') {
    return data.pncNumber || data.serialNumber;
  }
  return true;
}, {
  message: 'For technical support, either PNC or Serial Number is required',
  path: ['pncNumber'],
});

type FormData = z.infer<typeof schema>;

const B2BSupportForm = () => {
  const { t } = useTranslation();
  const [files, setFiles] = useState<File[]>([]);
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle');
  const [submitMessage, setSubmitMessage] = useState<string>('');
  
  // Customer validation state
  const [customerValidation, setCustomerValidation] = useState<{
    status: 'idle' | 'validating' | 'valid' | 'invalid';
    message: string;
    accountId?: string;
  }>({ status: 'idle', message: '' });
  
  const {
    register,
    handleSubmit,
    watch,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      urgency: 'medium',
      supportType: 'technical',
    }
  });

  const supportType = watch('supportType');
  const customerNumber = watch('customerNumber');

  // Function to validate customer number
  const validateCustomer = async (customerNum: string) => {
    if (!customerNum || customerNum.length < 3) {
      setCustomerValidation({ status: 'idle', message: '' });
      return;
    }

    setCustomerValidation({ status: 'validating', message: 'Validerar kundnummer...' });
    
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';
      const response = await fetch(`${apiUrl}/esb/validate-customer`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          customer_number: customerNum,
          customer_code: 'DOJ'  // Default customer code
        }),
      });

      const result = await response.json();
      
      if (result.is_valid) {
        setCustomerValidation({
          status: 'valid',
          message: 'Kundnummer giltigt',
          accountId: result.account_id
        });
      } else {
        setCustomerValidation({
          status: 'invalid',
          message: result.message || 'Ogiltigt kundnummer'
        });
      }
    } catch (error) {
      console.error('Customer validation error:', error);
      setCustomerValidation({
        status: 'invalid',
        message: 'Kunde inte validera kundnummer'
      });
    }
  };

  // Validate customer when number changes
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      if (customerNumber) {
        validateCustomer(customerNumber);
      }
    }, 800); // Debounce validation

    return () => clearTimeout(timeoutId);
  }, [customerNumber]);

  const onSubmit = async (data: FormData) => {
    console.log('B2B Support Form submission started:', data);
    setSubmitStatus('idle');
    setSubmitMessage('');
    
    // Check if customer is validated
    if (customerValidation.status !== 'valid') {
      setSubmitStatus('error');
      setSubmitMessage('Vänligen kontrollera att kundnumret är giltigt innan du skickar.');
      return;
    }

    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';
      console.log('Using API URL:', apiUrl);
      
      // Use the new ESB integration endpoint
      const payload = {
        customer_number: data.customerNumber,
        customer_code: 'DOJ',
        description: data.problemDescription,
        company_name: data.companyName,
        contact_person: data.contactPerson,
        email: data.email,
        phone: data.phone || '',
        support_type: data.supportType,
        subject: data.subject,
        urgency: data.urgency
      };

      console.log('Sending ESB payload:', payload);

      const response = await fetch(`${apiUrl}/esb/b2b-support`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      const result = await response.json();
      console.log('ESB Response:', result);
      
      if (result.success) {
        // Show success message
        setSubmitStatus('success');
        let successMsg = result.message || 'Ärende skapat framgångsrikt!';
        if (result.submission_id) {
          successMsg += ` (Ref: ${result.submission_id})`;
        }
        if (result.case_id) {
          successMsg += ` (Ärende-ID: ${result.case_id})`;
        }
        setSubmitMessage(successMsg);
        
        // Reset form after success
        reset();
        setFiles([]);
        setCustomerValidation({ status: 'idle', message: '' });
      } else {
        throw new Error(result.message || 'Submission failed');
      }
      
    } catch (error) {
      console.error('Error submitting form:', error);
      setSubmitStatus('error');
      
      // Provide more specific error messages
      let errorMessage = t('form.error', 'Ett fel uppstod vid skickning av formuläret. Vänligen försök igen.');
      
      if (error instanceof Error) {
        if (error.message.includes('fetch')) {
          errorMessage = 'Cannot connect to the server. Please check your internet connection or try again later.';
        } else if (error.message.includes('HTTP')) {
          errorMessage = error.message;
        } else {
          errorMessage = error.message;
        }
      }
      
      setSubmitMessage(errorMessage);
    }
  };

  // File handling functions
  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = Array.from(event.target.files || []);
    setFiles(prev => [...prev, ...selectedFiles]);
  };

  const removeFile = (index: number) => {
    setFiles(prev => prev.filter((_, i) => i !== index));
  };

  return (
    <div className="max-w-4xl mx-auto p-6 bg-white rounded-lg shadow-lg">
      <h1 className="text-3xl font-bold text-gray-900 mb-2">
        {t('support.title', 'B2B Support')}
      </h1>
      <p className="text-gray-600 mb-8">
        {t('support.description', 'Fyll i formuläret nedan för att få hjälp med dina Husqvarna-produkter.')}
      </p>

      {/* Status Messages */}
      {submitStatus !== 'idle' && (
        <div className={`mb-6 p-4 rounded-md ${
          submitStatus === 'success' 
            ? 'bg-green-50 border border-green-200 text-green-800' 
            : 'bg-red-50 border border-red-200 text-red-800'
        }`}>
          <div className="flex">
            <div className="flex-shrink-0">
              {submitStatus === 'success' ? (
                <svg className="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
              ) : (
                <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clipRule="evenodd" />
                </svg>
              )}
            </div>
            <div className="ml-3">
              <p className="text-sm font-medium">{submitMessage}</p>
            </div>
          </div>
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Support Type Selection */}
        <div className="space-y-4">
          <h2 className="text-xl font-semibold text-gray-900">
            {t('support.supportType', 'Supporttyp')}
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <label className="flex items-center p-4 border rounded-lg cursor-pointer hover:bg-gray-50">
              <input
                type="radio"
                value="technical"
                {...register('supportType')}
                className="mr-3"
              />
              <div>
                <div className="font-medium">{t('support.technical', 'Teknisk support')}</div>
                <div className="text-sm text-gray-500">
                  {t('support.technicalDesc', 'Produktproblem, installation eller tekniska frågor')}
                </div>
              </div>
            </label>
            <label className="flex items-center p-4 border rounded-lg cursor-pointer hover:bg-gray-50">
              <input
                type="radio"
                value="customer"
                {...register('supportType')}
                className="mr-3"
              />
              <div>
                <div className="font-medium">{t('support.customer', 'Kundsupport')}</div>
                <div className="text-sm text-gray-500">
                  {t('support.customerDesc', 'Frågor om beställningar, leveranser eller fakturor')}
                </div>
              </div>
            </label>
          </div>
          {errors.supportType && (
            <p className="text-red-600 text-sm">{errors.supportType.message}</p>
          )}
        </div>

        {/* Customer Information */}
        <div className="space-y-4">
          <h2 className="text-xl font-semibold text-gray-900">Kundinformation</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Customer Number with validation */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {t('support.customerNumber', 'Kundnummer')} <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                {...register('customerNumber')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder={t('support.customerNumberPlaceholder', 'Ange ditt kundnummer')}
              />
              {/* Customer validation feedback */}
              {customerValidation.status !== 'idle' && (
                <div className={`mt-1 text-sm flex items-center ${
                  customerValidation.status === 'validating' ? 'text-blue-600' :
                  customerValidation.status === 'valid' ? 'text-green-600' :
                  'text-red-600'
                }`}>
                  {customerValidation.status === 'validating' && (
                    <svg className="animate-spin -ml-1 mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                  )}
                  {customerValidation.status === 'valid' && (
                    <svg className="mr-2 h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                    </svg>
                  )}
                  {customerValidation.status === 'invalid' && (
                    <svg className="mr-2 h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clipRule="evenodd" />
                    </svg>
                  )}
                  {customerValidation.message}
                </div>
              )}
              {errors.customerNumber && (
                <p className="text-red-600 text-sm mt-1">{errors.customerNumber.message}</p>
              )}
            </div>

            {/* Email */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {t('support.email', 'E-postadress')} <span className="text-red-500">*</span>
              </label>
              <input
                type="email"
                {...register('email')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder={t('support.emailPlaceholder', 'din.email@foretag.se')}
              />
              {errors.email && (
                <p className="text-red-600 text-sm mt-1">{errors.email.message}</p>
              )}
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Company Name */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {t('support.companyName', 'Företagsnamn')} <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                {...register('companyName')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder={t('support.companyNamePlaceholder', 'Ange företagsnamn')}
              />
              {errors.companyName && (
                <p className="text-red-600 text-sm mt-1">{errors.companyName.message}</p>
              )}
            </div>

            {/* Contact Person */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {t('support.contactPerson', 'Kontaktperson')} <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                {...register('contactPerson')}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder={t('support.contactPersonPlaceholder', 'Förnamn Efternamn')}
              />
              {errors.contactPerson && (
                <p className="text-red-600 text-sm mt-1">{errors.contactPerson.message}</p>
              )}
            </div>
          </div>

          {/* Phone */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('support.phone', 'Telefonnummer')}
            </label>
            <input
              type="tel"
              {...register('phone')}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder={t('support.phonePlaceholder', '+46 70 123 45 67')}
            />
            {errors.phone && (
              <p className="text-red-600 text-sm mt-1">{errors.phone.message}</p>
            )}
          </div>
        </div>

        {/* Product Information - only for technical support */}
        {supportType === 'technical' && (
          <div className="space-y-4">
            <h2 className="text-xl font-semibold text-gray-900">
              {t('support.productInfo', 'Produktinformation')}
            </h2>
            <p className="text-sm text-gray-600">
              {t('support.productInfoNote', 'Ange antingen PNC-nummer eller serienummer för att hjälpa oss identifiera din produkt.')}
            </p>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {t('support.pncNumber', 'PNC-nummer')}
                </label>
                <input
                  type="text"
                  {...register('pncNumber')}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder={t('support.pncPlaceholder', 't.ex. 967 12 34-56')}
                />
                {errors.pncNumber && (
                  <p className="text-red-600 text-sm mt-1">{errors.pncNumber.message}</p>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {t('support.serialNumber', 'Serienummer')}
                </label>
                <input
                  type="text"
                  {...register('serialNumber')}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder={t('support.serialPlaceholder', 't.ex. 12345678')}
                />
                {errors.serialNumber && (
                  <p className="text-red-600 text-sm mt-1">{errors.serialNumber.message}</p>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Problem Description */}
        <div className="space-y-4">
          <h2 className="text-xl font-semibold text-gray-900">Ärendebeskrivning</h2>
          
          {/* Subject */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('support.subject', 'Ämne')} <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              {...register('subject')}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder={t('support.subjectPlaceholder', 'Kort beskrivning av ditt ärende')}
            />
            {errors.subject && (
              <p className="text-red-600 text-sm mt-1">{errors.subject.message}</p>
            )}
          </div>

          {/* Problem Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('support.problemDescription', 'Problembeskrivning')} <span className="text-red-500">*</span>
            </label>
            <textarea
              {...register('problemDescription')}
              rows={5}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder={t('support.problemPlaceholder', 'Beskriv ditt problem eller din fråga så detaljerat som möjligt...')}
            />
            {errors.problemDescription && (
              <p className="text-red-600 text-sm mt-1">{errors.problemDescription.message}</p>
            )}
          </div>

          {/* Urgency */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              {t('support.urgency', 'Prioritet')}
            </label>
            <select
              {...register('urgency')}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="low">{t('support.urgencyLow', 'Låg - Inom en vecka')}</option>
              <option value="medium">{t('support.urgencyMedium', 'Normal - Inom 2-3 dagar')}</option>
              <option value="high">{t('support.urgencyHigh', 'Hög - Så snart som möjligt')}</option>
            </select>
            {errors.urgency && (
              <p className="text-red-600 text-sm mt-1">{errors.urgency.message}</p>
            )}
          </div>
        </div>

        {/* File Attachments */}
        <div className="space-y-4">
          <h2 className="text-xl font-semibold text-gray-900">
            {t('support.attachments', 'Bilagor')}
          </h2>
          <p className="text-sm text-gray-600">
            {t('support.attachmentsNote', 'Ladda upp relevanta filer (PDF, Word, bilder). Max 10MB per fil.')}
          </p>
          
          <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center">
            <input
              type="file"
              multiple
              accept=".pdf,.doc,.docx,.jpg,.jpeg,.png"
              onChange={handleFileChange}
              className="hidden"
              id="file-upload"
            />
            <label htmlFor="file-upload" className="cursor-pointer">
              <svg className="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48">
                <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
              <div className="mt-4">
                <p className="text-sm text-gray-600">
                  Klicka för att ladda upp filer eller drag och släpp
                </p>
              </div>
            </label>
          </div>

          {/* Selected Files */}
          {files.length > 0 && (
            <div className="space-y-2">
              <h3 className="text-sm font-medium text-gray-700">
                {t('support.selectedFiles', 'Valda filer')}
              </h3>
              {files.map((file, index) => (
                <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                  <span className="text-sm text-gray-600">{file.name}</span>
                  <button
                    type="button"
                    onClick={() => removeFile(index)}
                    className="text-red-600 hover:text-red-800 text-sm"
                  >
                    {t('support.remove', 'Ta bort')}
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Submit Button */}
        <div className="flex justify-end">
          <button
            type="submit"
            disabled={isSubmitting || customerValidation.status !== 'valid'}
            className={`px-6 py-3 rounded-md font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 ${
              isSubmitting || customerValidation.status !== 'valid'
                ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                : 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500'
            }`}
          >
            {isSubmitting ? (
              <span className="flex items-center">
                <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                {t('support.submitting', 'Skickar...')}
              </span>
            ) : (
              t('support.submit', 'Skicka supportförfrågan')
            )}
          </button>
        </div>
      </form>
    </div>
  );
};

export default B2BSupportForm;
