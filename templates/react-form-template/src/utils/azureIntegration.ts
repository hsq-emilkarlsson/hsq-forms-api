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
