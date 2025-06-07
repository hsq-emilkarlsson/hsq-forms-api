import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import ContactForm from '../../components/ContactForm';
import { submitForm } from '../../api/formsApi';

// Mock the API module
jest.mock('../../api/formsApi', () => ({
  submitForm: jest.fn()
}));

describe('ContactForm', () => {
  const mockOnSuccess = jest.fn();
  
  beforeEach(() => {
    jest.resetAllMocks();
    (submitForm as jest.Mock).mockResolvedValue({
      success: true,
      submission: { id: 'mock-submission-id' }
    });
  });
  
  it('renders all form fields correctly', () => {
    render(<ContactForm onSuccess={mockOnSuccess} />);
    
    expect(screen.getByLabelText(/name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/phone/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/message/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument();
  });
  
  it('displays validation errors for invalid inputs', async () => {
    render(<ContactForm onSuccess={mockOnSuccess} />);
    
    // Click submit without entering any data
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));
    
    // Check for validation error messages
    await waitFor(() => {
      expect(screen.getByText(/name is required/i)).toBeInTheDocument();
      expect(screen.getByText(/email is required/i)).toBeInTheDocument();
      expect(screen.getByText(/message is required/i)).toBeInTheDocument();
    });
    
    // API should not be called if validation fails
    expect(submitForm).not.toHaveBeenCalled();
  });
  
  it('submits the form successfully with valid data', async () => {
    render(<ContactForm onSuccess={mockOnSuccess} />);
    
    // Fill out the form
    await userEvent.type(screen.getByLabelText(/name/i), 'John Doe');
    await userEvent.type(screen.getByLabelText(/email/i), 'john@example.com');
    await userEvent.type(screen.getByLabelText(/phone/i), '123-456-7890');
    await userEvent.type(screen.getByLabelText(/message/i), 'This is a test message');
    
    // Submit the form
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));
    
    // Check that the submitForm function was called with the right data
    await waitFor(() => {
      expect(submitForm).toHaveBeenCalledWith({
        formId: 'contact-form',
        data: {
          name: 'John Doe',
          email: 'john@example.com',
          phone: '123-456-7890',
          message: 'This is a test message'
        }
      });
    });
    
    // Check that the onSuccess callback was called
    expect(mockOnSuccess).toHaveBeenCalled();
  });
  
  it('shows an error message when form submission fails', async () => {
    // Mock the API to return an error
    (submitForm as jest.Mock).mockResolvedValue({
      success: false,
      error: 'Server error'
    });
    
    render(<ContactForm onSuccess={mockOnSuccess} />);
    
    // Fill out the form
    await userEvent.type(screen.getByLabelText(/name/i), 'John Doe');
    await userEvent.type(screen.getByLabelText(/email/i), 'john@example.com');
    await userEvent.type(screen.getByLabelText(/message/i), 'This is a test message');
    
    // Submit the form
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));
    
    // Check that the error message is displayed
    await waitFor(() => {
      expect(screen.getByText(/server error/i)).toBeInTheDocument();
    });
    
    // The success callback should not be called
    expect(mockOnSuccess).not.toHaveBeenCalled();
  });
});
