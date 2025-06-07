import { useState } from 'react';
import { useForm, SubmitHandler } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useContext } from 'react';
import { ZodSchema } from 'zod';
import { FormContext, FormContextType } from '../contexts/FormContext';
import { getBrowserInfo } from '../utils/helpers';
import { trackEvent } from '../utils/azureIntegration';

interface UseFormHookProps<T> {
  validationSchema: ZodSchema<T>;
  onSubmit: (data: T) => Promise<void>;
  defaultValues?: Partial<T>;
  useFormContext?: boolean;
}

interface FormHookReturn<T> {
  register: ReturnType<typeof useForm<T>>['register'];
  handleSubmit: (e?: React.BaseSyntheticEvent) => Promise<void>;
  errors: Record<string, any>;
  isSubmitting: boolean;
  submitError: string | null;
  isDirty: boolean;
  isValid: boolean;
  reset: () => void;
  watch: ReturnType<typeof useForm<T>>['watch'];
  formData: T;
}

export function useFormHook<T extends Record<string, any>>({
  validationSchema,
  onSubmit,
  defaultValues = {},
  useFormContext = false,
}: UseFormHookProps<T>): FormHookReturn<T> {
  // Get the form context if needed
  const formContext = useContext(FormContext);
  
  // Use either local state or context state
  const [localIsSubmitting, setLocalIsSubmitting] = useState(false);
  const [localSubmitError, setLocalSubmitError] = useState<string | null>(null);
  
  const isSubmitting = useFormContext ? formContext?.isSubmitting : localIsSubmitting;
  const submitError = useFormContext ? formContext?.submitError : localSubmitError;
  const setIsSubmitting = useFormContext ? formContext?.setIsSubmitting : setLocalIsSubmitting;
  const setSubmitError = useFormContext ? formContext?.setSubmitError : setLocalSubmitError;

  // Initialize form with React Hook Form
  const {
    register,
    handleSubmit: hookHandleSubmit,
    formState: { errors, isDirty, isValid },
    reset,
    watch,
  } = useForm<T>({
    resolver: zodResolver(validationSchema),
    defaultValues: useFormContext && formContext ? 
      { ...defaultValues, ...formContext.formData } as any : 
      defaultValues as any,
    mode: 'onBlur',
  });

  // Form submission handler
  const submitHandler: SubmitHandler<T> = async (data) => {
    setIsSubmitting?.(true);
    setSubmitError?.(null);
    
    try {
      // Get current language from URL if possible
      const pathParts = window.location.pathname.split('/');
      const langFromPath = pathParts.length > 1 ? pathParts[1] : null;
      const supportedLanguages = ['en', 'sv', 'us', 'se'];
      const languageCode = supportedLanguages.includes(langFromPath || '') ? langFromPath : 'en';
      
      // Track form submission attempt with Azure Analytics
      trackEvent('form_submit_attempt', {
        formType: (data as any).formType || 'unknown',
        hasFiles: !!(data as any).files?.length,
        browserInfo: getBrowserInfo(),
        language: languageCode
      });
      
      // Update form context if needed
      if (useFormContext && formContext) {
        formContext.updateFormData(data);
      }
      
      await onSubmit(data);
      
      // Track successful form submission
      trackEvent('form_submit_success', {
        formType: (data as any).formType || 'unknown'
      });
    } catch (error) {
      console.error('Form submission error:', error);
      const errorMessage = error instanceof Error ? error.message : 'Ett okänt fel uppstod';
      setSubmitError?.(errorMessage);
      
      // Track form submission error
      trackEvent('form_submit_error', {
        formType: (data as any).formType || 'unknown',
        error: errorMessage,
        browserInfo: getBrowserInfo()
      });
    } finally {
      setIsSubmitting?.(false);
    }
  };

  const handleSubmit = hookHandleSubmit(submitHandler);

  return {
    register,
    handleSubmit,
    errors,
    isSubmitting: isSubmitting || false,
    submitError,
    isDirty,
    isValid,
    reset: () => {
      reset(defaultValues as any);
      setSubmitError?.(null);
      
      // Reset form context data if using context
      if (useFormContext && formContext) {
        formContext.resetForm();
      }
    },
    formData: useFormContext && formContext ? formContext.formData as T : {} as T,
    watch,
  };
}
