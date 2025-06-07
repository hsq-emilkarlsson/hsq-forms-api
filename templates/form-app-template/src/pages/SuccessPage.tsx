import { Link } from 'react-router-dom';

const SuccessPage = () => {
  return (
    <div className="max-w-2xl mx-auto text-center">
      <div className="bg-white p-8 rounded-lg shadow-md">
        <div className="flex justify-center mb-4">
          <div className="rounded-full bg-green-100 p-4">
            <svg 
              xmlns="http://www.w3.org/2000/svg" 
              className="h-12 w-12 text-green-600" 
              fill="none" 
              viewBox="0 0 24 24" 
              stroke="currentColor"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={2} 
                d="M5 13l4 4L19 7" 
              />
            </svg>
          </div>
        </div>
        
        <h1 className="text-3xl font-bold text-gray-900 mb-4">
          Tack för ditt meddelande!
        </h1>
        
        <p className="text-lg text-gray-600 mb-6">
          Vi har tagit emot din information och återkommer så snart som möjligt.
        </p>
        
        <p className="text-sm text-gray-500 mb-8">
          Ett bekräftelsemail har skickats om du angav en e-postadress.
        </p>
        
        <Link 
          to="/" 
          className="btn btn-primary"
        >
          Tillbaka till startsidan
        </Link>
      </div>
    </div>
  );
};

export default SuccessPage;
