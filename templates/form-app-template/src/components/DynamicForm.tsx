import { useState, useEffect } from 'react';
import { submitForm } from '../api/formsApi';
import { getBrowserInfo } from '../utils/helpers';

interface DynamicFormProps {
  formId: string;
  fields: {
    id: string;
    type: string;
    label: string;
    placeholder?: string;
    required?: boolean;
    options?: { label: string; value: string }[];
  }[];
  onSuccess: () => void;
}

const DynamicForm = ({ formId, fields, onSuccess }: DynamicFormProps) => {
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  
  // Initialize form data with default values
  useEffect(() => {
    const initialData: Record<string, any> = {};
    fields.forEach(field => {
      initialData[field.id] = '';
      
      // Set default value based on field type
      if (field.type === 'checkbox') {
        initialData[field.id] = false;
      } else if (field.type === 'select' && field.options && field.options.length > 0) {
        initialData[field.id] = field.options[0].value;
      }
    });
    
    setFormData(initialData);
  }, [fields]);
  
  // Handle input change
  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name, value, type } = e.target as HTMLInputElement;
    
    // Handle checkboxes specially
    if (type === 'checkbox') {
      const checked = (e.target as HTMLInputElement).checked;
      setFormData(prev => ({ ...prev, [name]: checked }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
    
    // Clear error for this field when changed
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };
  
  // Validate form
  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};
    let isValid = true;
    
    fields.forEach(field => {
      if (field.required) {
        let value = formData[field.id];
        
        if (field.type === 'checkbox' && value !== true) {
          newErrors[field.id] = `${field.label} är obligatorisk`;
          isValid = false;
        } else if (field.type !== 'checkbox' && (!value || (typeof value === 'string' && value.trim() === ''))) {
          newErrors[field.id] = `${field.label} är obligatorisk`;
          isValid = false;
        }
      }
      
      // Email validation
      if (field.type === 'email' && formData[field.id]) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(formData[field.id])) {
          newErrors[field.id] = 'Ogiltig e-postadress';
          isValid = false;
        }
      }
    });
    
    setErrors(newErrors);
    return isValid;
  };
  
  // Handle form submission
  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }
    
    setIsSubmitting(true);
    setSubmitError(null);
    
    try {
      const response = await submitForm({
        formId: formId,
        data: formData,
        metadata: {
          source: 'dynamic-form-template',
          browser: getBrowserInfo(),
          timestamp: new Date().toISOString(),
        },
      });
      
      if (response.success) {
        // Reset form
        const initialData: Record<string, any> = {};
        fields.forEach(field => {
          initialData[field.id] = field.type === 'checkbox' ? false : '';
        });
        setFormData(initialData);
        
        // Trigger success callback
        onSuccess();
      } else {
        setSubmitError(response.error || 'Ett fel uppstod vid skickande av formuläret.');
      }
    } catch (error) {
      console.error('Form submission error:', error);
      setSubmitError('Ett oväntat fel uppstod. Försök igen senare.');
    } finally {
      setIsSubmitting(false);
    }
  };
  
  return (
    <form onSubmit={handleSubmit} className="space-y-6" noValidate>
      {fields.map(field => (
        <div key={field.id}>
          {/* Text, Email, Phone inputs */}
          {(field.type === 'text' || field.type === 'email' || field.type === 'phone') && (
            <div>
              <label htmlFor={field.id} className="form-label">
                {field.label} {field.required && <span className="text-red-500">*</span>}
              </label>
              <input
                id={field.id}
                name={field.id}
                type={field.type === 'email' ? 'email' : field.type === 'phone' ? 'tel' : 'text'}
                className="form-input"
                placeholder={field.placeholder}
                value={formData[field.id] || ''}
                onChange={handleChange}
                disabled={isSubmitting}
                required={field.required}
              />
              {errors[field.id] && (
                <p className="form-error">{errors[field.id]}</p>
              )}
            </div>
          )}
          
          {/* Textarea */}
          {field.type === 'textarea' && (
            <div>
              <label htmlFor={field.id} className="form-label">
                {field.label} {field.required && <span className="text-red-500">*</span>}
              </label>
              <textarea
                id={field.id}
                name={field.id}
                className="form-input min-h-[150px]"
                placeholder={field.placeholder}
                value={formData[field.id] || ''}
                onChange={handleChange}
                disabled={isSubmitting}
                required={field.required}
              />
              {errors[field.id] && (
                <p className="form-error">{errors[field.id]}</p>
              )}
            </div>
          )}
          
          {/* Select dropdown */}
          {field.type === 'select' && (
            <div>
              <label htmlFor={field.id} className="form-label">
                {field.label} {field.required && <span className="text-red-500">*</span>}
              </label>
              <select
                id={field.id}
                name={field.id}
                className="form-input"
                value={formData[field.id] || ''}
                onChange={handleChange}
                disabled={isSubmitting}
                required={field.required}
              >
                {field.options?.map(option => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
              {errors[field.id] && (
                <p className="form-error">{errors[field.id]}</p>
              )}
            </div>
          )}
          
          {/* Checkbox */}
          {field.type === 'checkbox' && (
            <div className="flex items-start">
              <div className="flex items-center h-5">
                <input
                  id={field.id}
                  name={field.id}
                  type="checkbox"
                  className="w-4 h-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500"
                  checked={formData[field.id] || false}
                  onChange={handleChange}
                  disabled={isSubmitting}
                  required={field.required}
                />
              </div>
              <div className="ml-3 text-sm">
                <label htmlFor={field.id} className="font-medium text-gray-700">
                  {field.label} {field.required && <span className="text-red-500">*</span>}
                </label>
                {errors[field.id] && (
                  <p className="form-error">{errors[field.id]}</p>
                )}
              </div>
            </div>
          )}
        </div>
      ))}
      
      {/* Submit error message */}
      {submitError && (
        <div className="bg-red-50 p-4 rounded-md">
          <div className="flex">
            <div className="flex-shrink-0">
              <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clipRule="evenodd" />
              </svg>
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-red-800">Ett fel uppstod</h3>
              <div className="mt-2 text-sm text-red-700">
                <p>{submitError}</p>
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* Submit button */}
      <div className="flex justify-end">
        <button
          type="submit"
          className="btn btn-primary"
          disabled={isSubmitting}
        >
          {isSubmitting ? (
            <span className="flex items-center">
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Skickar...
            </span>
          ) : (
            'Skicka'
          )}
        </button>
      </div>
    </form>
  );
};

export default DynamicForm;
