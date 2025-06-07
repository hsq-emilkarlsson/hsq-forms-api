import { useContext } from 'react';
import { FormContext } from '../contexts/FormContext';

/**
 * Custom hook to access the FormContext
 * 
 * @returns The form context object with form data and methods
 * @throws Error if used outside of a FormProvider
 */
export const useFormContext = () => {
  const context = useContext(FormContext);
  
  if (context === undefined) {
    throw new Error(
      'useFormContext must be used within a FormProvider'
    );
  }
  
  return context;
};
