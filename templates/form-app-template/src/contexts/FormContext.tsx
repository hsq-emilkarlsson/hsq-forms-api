import { createContext, useState, ReactNode, useContext } from 'react';

/**
 * Form context interface
 */
export interface FormContextType {
  formData: Record<string, any>;
  updateFormData: (data: Record<string, any>) => void;
  resetForm: () => void;
  isSubmitting: boolean;
  setIsSubmitting: (value: boolean) => void;
  submitError: string | null;
  setSubmitError: (error: string | null) => void;
}

/**
 * Create the form context
 */
export const FormContext = createContext<FormContextType | undefined>(undefined);

interface FormProviderProps {
  children: ReactNode;
  initialData?: Record<string, any>;
}

/**
 * Form provider component for managing form state
 * 
 * @param props Component props
 * @returns Form provider component
 */
export const FormProvider = ({ children, initialData = {} }: FormProviderProps) => {
  const [formData, setFormData] = useState<Record<string, any>>(initialData);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  /**
   * Update form data
   * 
   * @param data New data to merge with existing data
   */
  const updateFormData = (data: Record<string, any>) => {
    setFormData((prev) => ({ ...prev, ...data }));
  };

  /**
   * Reset form to initial state
   */
  const resetForm = () => {
    setFormData(initialData);
    setSubmitError(null);
  };

  return (
    <FormContext.Provider
      value={{
        formData,
        updateFormData,
        resetForm,
        isSubmitting,
        setIsSubmitting,
        submitError,
        setSubmitError,
      }}
    >
      {children}
    </FormContext.Provider>
  );
};

export const useFormContext = (): FormContextType => {
  const context = useContext(FormContext);
  if (context === undefined) {
    throw new Error('useFormContext must be used within a FormProvider');
  }
  return context;
};

export default FormContext;
