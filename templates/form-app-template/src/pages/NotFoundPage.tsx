import { Link } from 'react-router-dom';

const NotFoundPage = () => {
  return (
    <div className="max-w-2xl mx-auto text-center">
      <div className="bg-white p-8 rounded-lg shadow-md">
        <div className="flex justify-center mb-4">
          <div className="rounded-full bg-red-100 p-4">
            <svg 
              xmlns="http://www.w3.org/2000/svg" 
              className="h-12 w-12 text-red-600" 
              fill="none" 
              viewBox="0 0 24 24" 
              stroke="currentColor"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={2} 
                d="M6 18L18 6M6 6l12 12" 
              />
            </svg>
          </div>
        </div>
        
        <h1 className="text-3xl font-bold text-gray-900 mb-4">
          404 - Sidan kunde inte hittas
        </h1>
        
        <p className="text-lg text-gray-600 mb-6">
          Sidan du letar efter finns inte eller har flyttats.
        </p>
        
        <Link 
          to="/" 
          className="btn btn-primary"
        >
          Gå till startsidan
        </Link>
      </div>
    </div>
  );
};

export default NotFoundPage;
