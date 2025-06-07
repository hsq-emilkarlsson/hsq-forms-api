/**
 * Azure Integration Utilities
 * 
 * This module provides utilities for working with Azure services
 * in conjunction with the HSQ Forms API.
 */

/**
 * Check if Azure integration is enabled
 */
export const isAzureEnabled = (): boolean => {
  const enabled = import.meta.env.VITE_AZURE_ENABLED === 'true';
  return enabled;
};

/**
 * Get the Azure Storage URL for blob storage
 */
export const getAzureStorageUrl = (): string => {
  return import.meta.env.VITE_AZURE_STORAGE_URL || '';
};

/**
 * Generate a SAS token URL for a file
 * Note: This is normally handled by the API, but this is a helper for direct access
 * if needed
 * 
 * @param filename The filename in Azure Blob Storage
 * @param containerName The container name (defaults to form-uploads)
 * @returns The full URL with SAS token if available from the API
 */
export const getAzureFileUrl = (
  fileUrl: string, 
  apiBaseUrl: string = import.meta.env.VITE_API_URL || '/api'
): string => {
  if (!fileUrl) return '';
  
  // If the URL is already a full URL, return it
  if (fileUrl.startsWith('http')) {
    return fileUrl;
  }
  
  // Otherwise, construct the URL through the API proxy
  return `${apiBaseUrl}/files/view/${encodeURIComponent(fileUrl)}`;
};

/**
 * Configure Application Insights
 * 
 * @param config Configuration options
 * @returns true if successfully configured
 */
export const setupAzureAnalytics = (config: {
  instrumentationKey?: string;
  enableAutoRouteTracking?: boolean;
} = {}): boolean => {
  // Check if analytics is enabled
  if (import.meta.env.VITE_ENABLE_ANALYTICS !== 'true') {
    return false;
  }
  
  const instrumentationKey = 
    config.instrumentationKey || 
    import.meta.env.VITE_APPLICATION_INSIGHTS_KEY;
    
  if (!instrumentationKey) {
    console.warn('Application Insights key not provided');
    return false;
  }
  
  try {
    // Dynamic import for Application Insights to avoid bundling it when not used
    import('@microsoft/applicationinsights-web').then(({ ApplicationInsights }) => {
      const appInsights = new ApplicationInsights({
        config: {
          connectionString: `InstrumentationKey=${instrumentationKey}`,
          enableAutoRouteTracking: config.enableAutoRouteTracking ?? true,
          disableFetchTracking: false,
          enableCorsCorrelation: true,
          enableRequestHeaderTracking: true,
          enableResponseHeaderTracking: true
        }
      });
      
      appInsights.loadAppInsights();
      appInsights.trackPageView();
      
      // Save instance to window for global access
      (window as any).__appInsights = appInsights;
    });
    
    return true;
  } catch (error) {
    console.error('Failed to initialize Application Insights:', error);
    return false;
  }
};

/**
 * Track an event in Application Insights
 * 
 * @param eventName Name of the event to track
 * @param properties Event properties
 */
export const trackEvent = (
  eventName: string, 
  properties: Record<string, any> = {}
): void => {
  if (import.meta.env.VITE_ENABLE_ANALYTICS !== 'true') {
    return;
  }
  
  try {
    // Use Application Insights instance if available
    const appInsights = (window as any).__appInsights;
    if (appInsights) {
      appInsights.trackEvent({ name: eventName }, properties);
    } else {
      // Fallback if App Insights isn't initialized yet
      console.log(`Tracked event: ${eventName}`, properties);
      
      // Try to initialize App Insights if not done yet
      setupAzureAnalytics();
    }
  } catch (error) {
    console.error('Failed to track event:', error);
  }
};

export default {
  isAzureEnabled,
  getAzureStorageUrl,
  getAzureFileUrl,
  setupAzureAnalytics,
  trackEvent,
};
