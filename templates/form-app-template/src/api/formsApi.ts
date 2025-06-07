import axios, { AxiosRequestConfig } from 'axios';
import { FormData, FormSubmission, ApiResponse, FormSubmissionResponse } from '../types';
import { requestWithRetry, formatUserFriendlyError } from '../utils/errorHandling';
import { trackEvent } from '../utils/azureIntegration';

// Create axios instance with base URL and default headers
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 seconds timeout
});

// Add API key if available
if (import.meta.env.VITE_API_KEY) {
  api.defaults.headers.common['X-API-Key'] = import.meta.env.VITE_API_KEY;
}

// Submit form data
export const submitForm = async (formData: FormSubmission): Promise<ApiResponse<FormSubmissionResponse>> => {
  try {
    // Construct endpoint from template ID
    const endpoint = `/forms/templates/${formData.formId}/submit`;
    
    // Track the submission attempt
    trackEvent('form_submit_attempt', {
      formId: formData.formId,
      hasFiles: Boolean(formData.files?.length),
      language: formData.language
    });
    
    // Prepare metadata with language if provided
    const metadata = { ...formData.metadata } || {};
    if (formData.language) {
      metadata.language = formData.language;
    }
    
    // If there are files, use FormData
    if (formData.files && formData.files.length > 0) {
      // First submit the form data
      const payload = {
        data: formData.data,
        metadata: metadata,
      };
      
      // Submit form data first with retry
      const formResponse = await requestWithRetry({
        method: 'post',
        url: endpoint,
        baseURL: api.defaults.baseURL,
        headers: api.defaults.headers,
        data: payload,
      });
      
      const submissionId = formResponse.data.submission?.id;
      
      if (!submissionId) {
        trackEvent('form_submit_error', {
          formId: formData.formId,
          error: 'No submission ID returned'
        });
        
        return {
          success: false,
          error: 'No submission ID returned after form submission.',
        };
      }
      
      // Then upload files to the submission
      const formDataObj = new FormData();
      
      // Add files
      formData.files.forEach((file) => {
        formDataObj.append('files', file);
      });
      
      const config: AxiosRequestConfig = {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      };
      
      // Upload files to the submission with retry
      await requestWithRetry({
        method: 'post',
        url: `/files/upload/${submissionId}`,
        baseURL: api.defaults.baseURL,
        ...config,
        data: formDataObj,
      });
      
      // Track successful submission
      trackEvent('form_submit_success', {
        formId: formData.formId,
        submissionId,
        filesUploaded: formData.files.length
      });
      
      // Return the original form response
      return formResponse.data;
    } 
    
    // If no files, use JSON
    else {
      const payload = {
        data: formData.data,
        metadata: metadata,
      };
      
      // Submit with retry capability
      const response = await requestWithRetry({
        method: 'post',
        url: endpoint,
        baseURL: api.defaults.baseURL,
        headers: api.defaults.headers,
        data: payload,
      });
      
      // Track successful submission
      trackEvent('form_submit_success', {
        formId: formData.formId,
        submissionId: response.data.submission?.id
      });
      
      return response.data;
    }
  } catch (error) {
    // Track error
    trackEvent('form_submit_error', {
      formId: formData.formId,
      error: axios.isAxiosError(error) && error.response 
        ? `${error.response.status}: ${JSON.stringify(error.response.data)}`
        : String(error)
    });
    
    if (axios.isAxiosError(error) && error.response) {
      return error.response.data as ApiResponse;
    }
    
    return {
      success: false,
      error: 'An error occurred while communicating with the server.',
      details: formatUserFriendlyError(error),
    };
  }
};

// Get form configuration
export const getFormConfig = async (formId: string, language?: string): Promise<ApiResponse> => {
  try {
    const url = language 
      ? `/forms/templates/${formId}?language=${language}`
      : `/forms/templates/${formId}`;
      
    const response = await api.get(url);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error) && error.response) {
      return error.response.data as ApiResponse;
    }
    
    return {
      success: false,
      error: 'Ett fel uppstod vid hämtning av formulärkonfiguration.',
      details: error instanceof Error ? error.message : String(error),
    };
  }
};

// Check form submission status
export const checkSubmissionStatus = async (submissionId: string): Promise<ApiResponse> => {
  try {
    const response = await api.get(`/forms/submissions/${submissionId}`);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error) && error.response) {
      return error.response.data as ApiResponse;
    }
    
    return {
      success: false,
      error: 'Ett fel uppstod vid kontroll av status.',
      details: error instanceof Error ? error.message : String(error),
    };
  }
};

// Get form schema
export const getFormSchema = async (formId: string, language?: string): Promise<ApiResponse> => {
  try {
    const url = language
      ? `/forms/templates/${formId}/schema?language=${language}`
      : `/forms/templates/${formId}/schema`;
      
    const response = await api.get(url);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error) && error.response) {
      return error.response.data as ApiResponse;
    }
    
    return {
      success: false,
      error: 'Ett fel uppstod vid hämtning av formulärschema.',
      details: error instanceof Error ? error.message : String(error),
    };
  }
};

// List forms for a project
export const getProjectForms = async (projectName: string): Promise<ApiResponse> => {
  try {
    const response = await api.get(`/forms/projects/${projectName}/forms`);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error) && error.response) {
      return error.response.data as ApiResponse;
    }
    
    return {
      success: false,
      error: 'Ett fel uppstod vid hämtning av projektets formulär.',
      details: error instanceof Error ? error.message : String(error),
    };
  }
};

// Get forms by language code
export const getFormsByLanguage = async (languageCode: string, projectName?: string): Promise<ApiResponse> => {
  try {
    const url = projectName 
      ? `/${languageCode}/templates?project_id=${projectName}`
      : `/${languageCode}/templates`;
      
    const response = await api.get(url);
    return response.data;
  } catch (error) {
    if (axios.isAxiosError(error) && error.response) {
      return error.response.data as ApiResponse;
    }
    
    return {
      success: false,
      error: `Error fetching forms for language: ${languageCode}`,
      details: error instanceof Error ? error.message : String(error),
    };
  }
};
