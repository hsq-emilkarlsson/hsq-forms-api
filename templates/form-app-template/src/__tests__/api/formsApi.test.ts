import { submitForm, getFormConfig, checkSubmissionStatus } from '../../api/formsApi';
import axios from 'axios';

// Mock axios
jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

describe('Forms API Service', () => {
  beforeEach(() => {
    jest.resetAllMocks();
  });

  describe('submitForm', () => {
    it('submits form data without files correctly', async () => {
      // Setup mock response
      const mockResponse = { 
        data: { 
          success: true, 
          submission: { id: 'test-submission-id' } 
        } 
      };
      
      mockedAxios.post.mockResolvedValueOnce(mockResponse);
      
      // Test data
      const formData = {
        formId: 'contact-form',
        data: {
          name: 'Test User',
          email: 'test@example.com',
          message: 'This is a test message'
        }
      };
      
      // Call the function
      const result = await submitForm(formData);
      
      // Assertions
      expect(mockedAxios.post).toHaveBeenCalledWith(
        '/forms/templates/contact-form/submit', 
        {
          data: formData.data,
          metadata: {}
        }
      );
      
      expect(result).toEqual({
        success: true,
        submission: { id: 'test-submission-id' }
      });
    });
    
    it('submits form data with language metadata correctly', async () => {
      // Setup mock response
      const mockResponse = { 
        data: { 
          success: true, 
          submission: { id: 'test-submission-id' } 
        } 
      };
      
      mockedAxios.post.mockResolvedValueOnce(mockResponse);
      
      // Test data with language
      const formData = {
        formId: 'contact-form',
        data: {
          name: 'Test User',
          email: 'test@example.com',
          message: 'This is a test message'
        },
        language: 'en',
        metadata: {
          source: 'website'
        }
      };
      
      // Call the function
      const result = await submitForm(formData);
      
      // Assertions
      expect(mockedAxios.post).toHaveBeenCalledWith(
        '/forms/templates/contact-form/submit', 
        {
          data: formData.data,
          metadata: {
            source: 'website',
            language: 'en'
          }
        }
      );
      
      expect(result).toEqual({
        success: true,
        submission: { id: 'test-submission-id' }
      });
    });
    
    it('handles form submission errors correctly', async () => {
      // Setup mock error
      const errorResponse = {
        response: {
          data: {
            success: false,
            error: 'Invalid data'
          },
          status: 400
        }
      };
      
      mockedAxios.post.mockRejectedValueOnce(errorResponse);
      
      // Test data
      const formData = {
        formId: 'contact-form',
        data: {
          name: 'Test User'
          // Missing required fields
        }
      };
      
      // Call the function
      const result = await submitForm(formData);
      
      // Assertions
      expect(result).toEqual({
        success: false,
        error: 'Invalid data'
      });
    });
  });

  describe('getFormConfig', () => {
    it('retrieves form configuration correctly', async () => {
      // Setup mock response
      const mockResponse = { 
        data: { 
          success: true, 
          form: { 
            id: 'contact-form',
            name: 'Contact Form',
            fields: [] 
          } 
        } 
      };
      
      mockedAxios.get.mockResolvedValueOnce(mockResponse);
      
      // Call the function
      const result = await getFormConfig('contact-form');
      
      // Assertions
      expect(mockedAxios.get).toHaveBeenCalledWith('/forms/templates/contact-form');
      expect(result).toEqual({
        success: true,
        form: {
          id: 'contact-form',
          name: 'Contact Form',
          fields: []
        }
      });
    });

    it('retrieves form configuration with language parameter', async () => {
      // Setup mock response
      const mockResponse = { 
        data: { 
          success: true, 
          form: { 
            id: 'contact-form',
            name: 'Kontaktformulär', // Swedish name
            fields: [] 
          } 
        } 
      };
      
      mockedAxios.get.mockResolvedValueOnce(mockResponse);
      
      // Call the function with language parameter
      const result = await getFormConfig('contact-form', 'sv');
      
      // Assertions
      expect(mockedAxios.get).toHaveBeenCalledWith('/forms/templates/contact-form?language=sv');
      expect(result).toEqual({
        success: true,
        form: {
          id: 'contact-form',
          name: 'Kontaktformulär',
          fields: []
        }
      });
    });
  });

  describe('getFormsByLanguage', () => {
    it('retrieves forms by language code correctly', async () => {
      // Import the function first (since it wasn't imported at the top)
      const { getFormsByLanguage } = require('../../api/formsApi');

      // Setup mock response
      const mockResponse = { 
        data: { 
          success: true, 
          forms: [
            {
              id: 'contact-form',
              name: 'Contact Form',
              fields: []
            },
            {
              id: 'newsletter-form',
              name: 'Newsletter',
              fields: []
            }
          ]
        } 
      };
      
      mockedAxios.get.mockResolvedValueOnce(mockResponse);
      
      // Call the function
      const result = await getFormsByLanguage('en');
      
      // Assertions
      expect(mockedAxios.get).toHaveBeenCalledWith('/en/templates');
      expect(result).toEqual({
        success: true,
        forms: [
          {
            id: 'contact-form',
            name: 'Contact Form',
            fields: []
          },
          {
            id: 'newsletter-form',
            name: 'Newsletter',
            fields: []
          }
        ]
      });
    });

    it('retrieves forms by language code with project filter', async () => {
      // Import the function
      const { getFormsByLanguage } = require('../../api/formsApi');

      // Setup mock response
      const mockResponse = { 
        data: { 
          success: true, 
          forms: [
            {
              id: 'contact-form',
              name: 'Kontaktformulär',
              fields: []
            }
          ]
        } 
      };
      
      mockedAxios.get.mockResolvedValueOnce(mockResponse);
      
      // Call the function with project name
      const result = await getFormsByLanguage('sv', 'website');
      
      // Assertions
      expect(mockedAxios.get).toHaveBeenCalledWith('/sv/templates?project_id=website');
      expect(result).toEqual({
        success: true,
        forms: [
          {
            id: 'contact-form',
            name: 'Kontaktformulär',
            fields: []
          }
        ]
      });
    });
  });
});
