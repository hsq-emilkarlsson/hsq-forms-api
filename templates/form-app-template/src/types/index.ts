// Form data types
export interface FormData {
  [key: string]: any;
}

export interface FormConfig {
  id: string;
  name: string;
  fields: FormField[];
}

export interface FormField {
  id: string;
  name: string;
  label: string;
  type: 'text' | 'email' | 'phone' | 'textarea' | 'select' | 'checkbox' | 'radio' | 'file';
  required?: boolean;
  placeholder?: string;
  options?: { label: string; value: string }[];
  validation?: {
    pattern?: string;
    minLength?: number;
    maxLength?: number;
    min?: number;
    max?: number;
  };
}

// API response types
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface FormSubmissionResponse {
  id: string;
  status: 'success' | 'error' | 'pending';
  message: string;
  timestamp: string;
  tracking_id?: string;
}

// Form submission types
export interface FormSubmission {
  formId: string;
  data: FormData;
  files?: File[];
  language?: string;
  metadata?: {
    source?: string;
    browser?: string;
    platform?: string;
    language?: string;
    [key: string]: any;
  };
}

// Error types
export interface ValidationError {
  field: string;
  message: string;
}
