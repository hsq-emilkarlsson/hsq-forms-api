import { Link } from 'react-router-dom';

const HomePage = () => {
  return (
    <div className="max-w-3xl mx-auto">
      <section className="text-center py-10">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          HSQ Forms Template
        </h1>
        <p className="text-lg text-gray-600 mb-8">
          A powerful and flexible form template that integrates with HSQ Forms API
        </p>
        
        <div className="flex flex-col sm:flex-row justify-center gap-4">
          <Link 
            to="/form" 
            className="inline-flex items-center justify-center px-5 py-3 border border-transparent text-base font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700"
          >
            Basic Form Example
          </Link>
          
          <Link 
            to="/azure-example" 
            className="inline-flex items-center justify-center px-5 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
          >
            Azure Integration Example
          </Link>
        </div>
      </section>
      
      <section className="mt-12 bg-white p-6 rounded-lg shadow-md">
        <h2 className="text-2xl font-semibold mb-4">Template Features</h2>
        <div className="prose max-w-none">
          <p>
            This template showcases forms that integrate with the HSQ Forms API. 
            The templates can be customized for different purposes by modifying 
            the components and validation schemas.
          </p>
          <p>
            These forms use React Hook Form for state management  
            and Zod for validation. They communicate with the HSQ Forms API to 
            submit data and files securely to the backend service.
          </p>
          
          <h3 className="text-xl font-semibold mt-6 mb-2">Available Examples</h3>
          <ul className="list-disc pl-5 space-y-2">
            <li>
              <strong>Basic Contact Form</strong> - A standard contact form with validation
            </li>
            <li>
              <strong>Azure Integration Example</strong> - Form with file upload that demonstrates 
              Azure Blob Storage integration
            </li>
          </ul>
          
          <h3 className="text-xl font-semibold mt-6 mb-2">Documentation</h3>
          <p>
            This template includes comprehensive documentation to help you customize and deploy your form:
          </p>
          <ul className="list-disc pl-5 space-y-1">
            <li>
              <strong>CUSTOMIZATION.md</strong> - How to customize the forms for your needs
            </li>
            <li>
              <strong>INTEGRATION.md</strong> - How to integrate with the HSQ Forms API
            </li>
            <li>
              <strong>AZURE_DEPLOYMENT.md</strong> - How to deploy to Azure Static Web Apps
            </li>
          </ul>
        </div>
      </section>
    </div>
  );
};

export default HomePage;
