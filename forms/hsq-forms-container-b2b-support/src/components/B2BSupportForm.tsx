import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useTranslation } from 'react-i18next';
import { useState, useEffect, useMemo } from 'react';

const B2BSupportForm = () => {
  const { t } = useTranslation();
  
  // Create schema with translated error messages
  const schema = useMemo(() => z.object({
    supportType: z.enum(['technical', 'customer'], {
      required_error: t('validation.supportTypeRequired', 'Please select support type'),
    }),
    customerNumber: z.string().min(1, t('validation.customerNumberRequired', 'Customer number is required')),
    email: z.string().email(t('validation.invalidEmail', 'Invalid email address')),
    companyName: z.string().min(1, t('validation.companyNameRequired', 'Company name is required')),
    contactPerson: z.string().min(1, t('validation.contactPersonRequired', 'Contact person is required')),
    phone: z.string().optional(),
    // Technical support fields
    pncNumber: z.string().optional(),
    serialNumber: z.string().optional(),
    // Problem description
    subject: z.string().min(1, t('validation.subjectRequired', 'Subject is required')),
    problemDescription: z.string().min(10, t('validation.problemDescriptionMinLength', 'Problem description must be at least 10 characters')),
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
    message: t('validation.pncOrSerialRequired', 'For technical support, either PNC or Serial Number is required'),
    path: ['pncNumber'],
  }), [t]);

  type FormData = z.infer<typeof schema>;
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

  // Function to validate customer number against Husqvarna Group API
  const validateCustomer = async (customerNum: string) => {
    if (!customerNum || customerNum.length < 3) {
      setCustomerValidation({ status: 'idle', message: '' });
      return;
    }

    setCustomerValidation({ status: 'validating', message: '🔍 Validerar kundnummer...' });
    
    try {
      // Get backend API configuration
      const backendApiBaseUrl = import.meta.env.VITE_BACKEND_API_URL || 'http://localhost:8000';
      
      // Default customer code (can be made configurable later)
      const customerCode = 'DOJ';
      
      console.log('🔍 CUSTOMER VALIDATION DEBUG:', {
        customerNum,
        customerCode,
        backendApiBaseUrl,
        env_VITE_BACKEND_API_URL: import.meta.env.VITE_BACKEND_API_URL,
        all_env_vars: import.meta.env,
        backendUrl: `${backendApiBaseUrl}/api/husqvarna/validate-customer?customer_number=${customerNum}&customer_code=${customerCode}`
      });
      
      // Call backend proxy for Husqvarna Group API validation
      try {
        const backendProxyUrl = `${backendApiBaseUrl}/api/husqvarna/validate-customer?customer_number=${customerNum}&customer_code=${customerCode}`;
        console.log('🌐 Making API request to backend proxy:', backendProxyUrl);
        
        const husqvarnaResponse = await fetch(backendProxyUrl, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
        });
        
        console.log('📡 Backend proxy API response status:', husqvarnaResponse.status);
        console.log('📋 Backend proxy API response headers:', Object.fromEntries(husqvarnaResponse.headers.entries()));

        if (husqvarnaResponse.ok) {
          const husqvarnaResult = await husqvarnaResponse.json();
          console.log('Backend proxy API response:', husqvarnaResult);
          
          if (husqvarnaResult.valid && husqvarnaResult.account_id) {
            setCustomerValidation({
              status: 'valid',
              message: husqvarnaResult.message || `✅ Kundnummer ${customerNum} verifierat! (Account ID: ${husqvarnaResult.account_id.substring(0, 8)}...)`,
              accountId: husqvarnaResult.account_id
            });
            return;
          } else {
            setCustomerValidation({
              status: 'invalid',
              message: husqvarnaResult.message || `❌ Kundnummer ${customerNum} hittades inte i Husqvarna Group systemet`
            });
            return;
          }
        } else {
          console.warn('🚨 Backend proxy API validation failed with status:', husqvarnaResponse.status);
          const errorText = await husqvarnaResponse.text();
          console.warn('🚨 Backend proxy API error response:', errorText);
        }
      } catch (husqvarnaError) {
        console.error('🚨 Backend proxy API validation failed, falling back to ESB validation:', husqvarnaError);
        if (husqvarnaError instanceof Error) {
          console.error('🚨 Detailed error info:', {
            name: husqvarnaError.name,
            message: husqvarnaError.message,
            stack: husqvarnaError.stack,
            cause: husqvarnaError.cause
          });
        }
      }

      // Fallback to ESB validation if Husqvarna Group API is unavailable
      try {
        const esbResponse = await fetch('https://api.hsqforms.se/esb/validate-customer', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ customerNumber: customerNum }),
        });

        if (esbResponse.ok) {
          const esbResult = await esbResponse.json();
          if (esbResult.valid) {
            setCustomerValidation({
              status: 'valid',
              message: `🟡 Kundnummer ${customerNum} validerat via ESB (fallback system)`,
              accountId: esbResult.accountId || customerNum
            });
            return;
          } else {
            setCustomerValidation({
              status: 'invalid',
              message: esbResult.message || `❌ Kundnummer ${customerNum} hittades inte i något system`
            });
            return;
          }
        }
      } catch (esbError) {
        console.warn('ESB validation also failed, using local validation:', esbError);
      }

      // Final fallback to basic local validation
      const isValidFormat = /^[A-Z0-9]{3,20}$/.test(customerNum.toUpperCase());
      
      // Simulate API delay for better UX
      await new Promise(resolve => setTimeout(resolve, 300));
      
      if (isValidFormat) {
        setCustomerValidation({
          status: 'valid',
          message: `🟡 Kundnummer ${customerNum} har giltigt format (offline validering - ej verifierat)`,
          accountId: customerNum
        });
      } else {
        // Provide more specific error messages
        let errorMessage = '';
        if (customerNum.length < 3) {
          errorMessage = `❌ Kundnummer för kort: "${customerNum}" (minimum 3 tecken)`;
        } else if (customerNum.length > 20) {
          errorMessage = `❌ Kundnummer för långt: "${customerNum}" (maximum 20 tecken)`;
        } else if (!/^[A-Z0-9]+$/i.test(customerNum)) {
          errorMessage = `❌ Ogiltiga tecken i kundnummer: "${customerNum}" (endast bokstäver och siffror)`;
        } else {
          errorMessage = `❌ Ogiltigt kundnummer format: "${customerNum}"`;
        }
        
        setCustomerValidation({
          status: 'invalid',
          message: errorMessage
        });
      }
    } catch (error) {
      console.error('Customer validation error:', error);
      setCustomerValidation({
        status: 'invalid',
        message: `⚠️ Kunde inte validera kundnummer "${customerNum}" - tekniskt fel`
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
      setSubmitMessage(t('support.customerValidationRequired', 'Vänligen kontrollera att kundnumret är giltigt innan du skickar.'));
      return;
    }

    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';
      console.log('Using API URL:', apiUrl);
      
      // Use the new template-based API endpoint
      const templateId = '958915ec-fed1-4e7e-badd-4598502fe6a1'; // B2B Support Form template ID
      
      // Prepare form data according to the template schema
      const formSubmissionData = {
        companyName: data.companyName,
        contactPerson: data.contactPerson,
        customerNumber: data.customerNumber,
        email: data.email,
        phone: data.phone || '',
        subject: data.subject,
        supportType: data.supportType,
        pncNumber: data.pncNumber || '',
        serialNumber: data.serialNumber || '',
        problemDescription: data.problemDescription,
        urgency: data.urgency,
        language: 'sv' // Default to Swedish
      };

      console.log('Sending form submission data:', formSubmissionData);

      const response = await fetch(`${apiUrl}/templates/${templateId}/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          data: formSubmissionData,
          metadata: {
            source: 'b2b-support-form',
            customerValidated: true,
            accountId: customerValidation.accountId
          }
        }),
      });

      const result = await response.json();
      console.log('API Response:', result);
      
      if (!response.ok) {
        throw new Error(result.detail || result.error || 'Submission failed');
      }
      
      if (result.success !== false) {
        // Handle file uploads if there are any
        let submissionId = result.submission?.id || result.id;
        
        if (files.length > 0 && submissionId) {
          const fileFormData = new FormData();
          files.forEach(file => {
            fileFormData.append('files', file);
          });

          const fileResponse = await fetch(`${apiUrl}/files/upload/${submissionId}`, {
            method: 'POST',
            body: fileFormData,
          });

          if (!fileResponse.ok) {
            console.warn('File upload failed, but form was submitted successfully');
          }
        }

        // Also send to Husqvarna Group Cases API and ESB system as complement
        try {
          console.log('Sending to Husqvarna Group Cases API and ESB system...');
          
          // Get Husqvarna API configuration
          const husqvarnaApiBaseUrl = import.meta.env.VITE_HUSQVARNA_API_BASE_URL || 'https://api-qa.integration.husqvarnagroup.com/hqw170/v1';
          const husqvarnaApiKey = import.meta.env.VITE_HUSQVARNA_API_KEY || '3d9c4d8a3c5c47f1a2a0ec096496a786';
          
          // Default customer code (DOJ for EMEA, can be expanded for APAC routing)
          const customerCode = 'DOJ';
          
          // First try Husqvarna Group Cases API
          try {
            const casesPayload = {
              accountId: customerValidation.accountId,
              customerNumber: data.customerNumber,
              customerCode: customerCode,
              caseOriginCode: '115000008',
              description: `Subject: ${data.subject}\n\nType: ${data.supportType}\nUrgency: ${data.urgency}\n\nDescription:\n${data.problemDescription}${data.pncNumber ? `\n\nPNC: ${data.pncNumber}` : ''}${data.serialNumber ? `\nSerial: ${data.serialNumber}` : ''}\n\nContact: ${data.contactPerson} (${data.email})${data.phone ? ` - ${data.phone}` : ''}\nCompany: ${data.companyName}`
            };

            console.log('Sending to Husqvarna Cases API:', casesPayload);

            const casesResponse = await fetch(`${husqvarnaApiBaseUrl}/cases`, {
              method: 'POST',
              headers: {
                'Ocp-Apim-Subscription-Key': husqvarnaApiKey,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify(casesPayload),
            });

            if (casesResponse.ok) {
              const casesResult = await casesResponse.json();
              console.log('Successfully created case in Husqvarna Group system:', casesResult);
            } else {
              console.warn('Husqvarna Cases API failed with status:', casesResponse.status);
              const errorData = await casesResponse.text();
              console.warn('Husqvarna Cases API error:', errorData);
            }
          } catch (casesError) {
            console.warn('Husqvarna Group Cases API error:', casesError);
          }

          // Fallback to ESB system
          try {
            const esbResponse = await fetch('https://api.hsqforms.se/esb/b2b-support', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                // ESB format - map from our form data
                name: data.contactPerson,
                email: data.email,
                company: data.companyName,
                phone: data.phone || '',
                customerNumber: data.customerNumber,
                subject: data.subject,
                message: data.problemDescription,
                supportType: data.supportType,
                pncNumber: data.pncNumber || '',
                serialNumber: data.serialNumber || '',
                urgency: data.urgency,
                // Include reference to our local submission and Husqvarna data
                localSubmissionId: submissionId,
                accountId: customerValidation.accountId,
                customerCode: customerCode,
                source: 'b2b-support-form-v2-husqvarna'
              }),
            });

            if (esbResponse.ok) {
              console.log('Successfully sent to ESB system as fallback');
            } else {
              console.warn('ESB submission failed');
            }
          } catch (esbError) {
            console.warn('ESB submission error (non-critical):', esbError);
          }

        } catch (systemError) {
          console.warn('External systems submission error (non-critical):', systemError);
          // Don't fail the whole form submission if external systems fail
        }
        
        // Show success message
        setSubmitStatus('success');
        let successMsg = 'Ärende skapat framgångsrikt!';
        if (submissionId) {
          successMsg += ` (Ref: ${submissionId})`;
        }
        setSubmitMessage(successMsg);
        
        // Reset form after success
        reset();
        setFiles([]);
        setCustomerValidation({ status: 'idle', message: '' });
      } else {
        throw new Error(result.error || result.message || 'Submission failed');
      }
      
    } catch (error) {
      console.error('Error submitting form:', error);
      setSubmitStatus('error');
      
      // Provide more specific error messages
      let errorMessage = t('form.error', 'Ett fel uppstod vid skickning av formuläret. Vänligen försök igen.');
      
      if (error instanceof Error) {
        if (error.message.includes('fetch')) {
          errorMessage = t('errors.networkError', 'Cannot connect to the server. Please check your internet connection or try again later.');
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
        {t('support.description', 'Fyll i formuläret nedan för att få hjälp med dina Husqvarna-produkter. Vi återkommer inom 2-3 arbetsdagar.')}
      </p>

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
          <h2 className="text-xl font-semibold text-gray-900">
            {t('support.customerInfo', 'Customer Information')}
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Customer Number with validation */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                {t('support.customerNumber', 'Kundnummer')} <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                {...register('customerNumber')}
                className={`w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:border-transparent ${
                  customerValidation.status === 'valid' ? 'border-green-300 focus:ring-green-500' :
                  customerValidation.status === 'invalid' ? 'border-red-300 focus:ring-red-500' :
                  customerValidation.status === 'validating' ? 'border-blue-300 focus:ring-blue-500' :
                  'border-gray-300 focus:ring-blue-500'
                }`}
                placeholder={t('support.customerNumberPlaceholder', 'Ange ditt kundnummer (ex: 1411768)')}
              />
              {/* Customer validation feedback */}
              {customerValidation.status !== 'idle' && (
                <div className={`mt-2 p-3 rounded-md border flex items-center text-sm font-medium ${
                  customerValidation.status === 'validating' ? 'bg-blue-50 border-blue-200 text-blue-700' :
                  customerValidation.status === 'valid' ? 'bg-green-50 border-green-200 text-green-700' :
                  'bg-red-50 border-red-200 text-red-700'
                }`}>
                  {customerValidation.status === 'validating' && (
                    <svg className="animate-spin -ml-1 mr-3 h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                  )}
                  {customerValidation.status === 'valid' && (
                    <svg className="mr-3 h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                    </svg>
                  )}
                  {customerValidation.status === 'invalid' && (
                    <svg className="mr-3 h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clipRule="evenodd" />
                    </svg>
                  )}
                  <span>{customerValidation.message}</span>
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
          <h2 className="text-xl font-semibold text-gray-900">
            {t('support.caseDescription', 'Case Description')}
          </h2>
          
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
                  {t('support.uploadPrompt', 'Click to upload files or drag and drop')}
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

        {/* Submit Button */}
        <div className="flex justify-end">
          <button
            type="submit"
            disabled={isSubmitting || customerValidation.status !== 'valid'}
            className={`px-6 py-3 rounded-md font-medium focus:outline-none focus:ring-2 focus:ring-offset-2 ${
              isSubmitting || customerValidation.status !== 'valid'
                ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                : 'bg-husqvarna-blue text-white hover:bg-husqvarna-blue-dark focus:ring-husqvarna-blue'
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
