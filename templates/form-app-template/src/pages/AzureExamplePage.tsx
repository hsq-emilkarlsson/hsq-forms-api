import { useNavigate } from 'react-router-dom';
import AzureExampleForm from '../components/AzureExampleForm';

/**
 * Example page showing Azure integration
 */
const AzureExamplePage = () => {
  const navigate = useNavigate();
  
  const handleSuccess = () => {
    navigate('/success');
  };
  
  return (
    <div className="max-w-3xl mx-auto">
      <h1 className="text-3xl font-bold text-center mb-6">
        Azure Integration Example
      </h1>
      
      <div className="bg-white p-6 rounded-lg shadow-md">
        <div className="mb-6">
          <h2 className="text-xl font-semibold mb-2">Example Form with Azure Integration</h2>
          <p className="text-gray-600">
            This example demonstrates how to integrate the HSQ Forms API with Azure services.
            Fill out the form below to submit data that will be processed and stored using Azure.
          </p>
          <div className="mt-2 p-3 bg-blue-50 border border-blue-200 rounded-md">
            <p className="text-blue-700 text-sm">
              <strong>Note:</strong> This form uses Azure Blob Storage for file uploads and stores the form data
              securely. All data is processed in compliance with GDPR requirements.
            </p>
          </div>
        </div>
        
        <AzureExampleForm onSuccess={handleSuccess} />
      </div>
    </div>
  );
};

export default AzureExamplePage;
