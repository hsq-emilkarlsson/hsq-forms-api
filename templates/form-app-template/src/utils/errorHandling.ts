/**
 * Error handling and retry utilities
 */
import axios, { AxiosError, AxiosRequestConfig, AxiosResponse } from 'axios';
import { trackEvent } from './azureIntegration';

/**
 * Retry configuration options
 */
export interface RetryConfig {
  /** Maximum number of retry attempts */
  maxRetries: number;
  /** Base delay between retries in ms */
  retryDelay: number;
  /** Whether to use exponential backoff */
  useExponentialBackoff: boolean;
  /** Status codes that should trigger a retry */
  retryStatusCodes: number[];
}

/**
 * Default retry configuration
 */
export const defaultRetryConfig: RetryConfig = {
  maxRetries: 3,
  retryDelay: 1000,
  useExponentialBackoff: true,
  retryStatusCodes: [408, 429, 500, 502, 503, 504],
};

/**
 * Create an axios request with retry capability
 * 
 * @param config Axios request config
 * @param retryConfig Retry configuration
 * @returns Promise with axios response
 */
export async function requestWithRetry<T = any>(
  config: AxiosRequestConfig,
  retryConfig: Partial<RetryConfig> = {}
): Promise<AxiosResponse<T>> {
  const { 
    maxRetries, 
    retryDelay, 
    useExponentialBackoff, 
    retryStatusCodes 
  } = { ...defaultRetryConfig, ...retryConfig };

  let lastError: AxiosError | Error | null = null;
  let attempt = 0;

  while (attempt <= maxRetries) {
    try {
      return await axios(config);
    } catch (error) {
      lastError = error as AxiosError | Error;
      attempt += 1;
      
      // If we've reached the maximum number of retries, throw the error
      if (attempt > maxRetries) {
        break;
      }

      // Only retry on specific status codes or network errors
      if (axios.isAxiosError(error)) {
        const shouldRetry = error.code === 'ECONNABORTED' || 
                           !error.response || 
                           retryStatusCodes.includes(error.response.status);

        if (!shouldRetry) {
          break;
        }
      }

      // Calculate delay with exponential backoff if enabled
      const delay = useExponentialBackoff 
        ? retryDelay * Math.pow(2, attempt - 1)
        : retryDelay;

      // Log the retry attempt
      console.warn(`API request failed, retrying (${attempt}/${maxRetries}) in ${delay}ms`, config.url);
      
      // Track retry event if analytics is enabled
      trackEvent('api_retry', { 
        url: config.url, 
        attempt,
        status: axios.isAxiosError(lastError) && lastError.response ? lastError.response.status : 'unknown'
      });
      
      // Wait before retrying
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  // If we get here, all retries failed
  if (lastError) {
    throw lastError;
  }
  
  // This should never happen, but TypeScript requires a return statement
  throw new Error('Unexpected error in request retry logic');
}

/**
 * Format an error to a user-friendly message
 * 
 * @param error The error to format
 * @returns User-friendly error message
 */
export function formatUserFriendlyError(error: unknown): string {
  // If it's an Axios error, try to get a meaningful message
  if (axios.isAxiosError(error)) {
    // Try to get the error message from the API response
    const apiErrorMessage = error.response?.data?.error || error.response?.data?.message;
    if (apiErrorMessage) {
      return String(apiErrorMessage);
    }
    
    // Network error
    if (error.code === 'ECONNABORTED') {
      return 'The request timed out. Please check your internet connection and try again.';
    }
    
    // Handle common HTTP status codes
    if (error.response) {
      switch (error.response.status) {
        case 400: return 'The request was invalid. Please check your form data and try again.';
        case 401: return 'You need to be logged in to perform this action.';
        case 403: return 'You do not have permission to perform this action.';
        case 404: return 'The requested resource could not be found.';
        case 429: return 'Too many requests. Please try again later.';
        case 500: return 'An internal server error occurred. Please try again later.';
        default: return `Server error (${error.response.status}). Please try again later.`;
      }
    }
    
    return 'A network error occurred. Please check your internet connection and try again.';
  }
  
  // For standard errors, just get the message
  if (error instanceof Error) {
    return error.message;
  }
  
  // For anything else, convert to string
  return String(error);
}
