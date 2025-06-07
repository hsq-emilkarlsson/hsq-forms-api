import { useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import ContactForm from '../components/ContactForm';

const FormPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { t, i18n } = useTranslation();
  
  // Get current language from URL path
  const pathParts = location.pathname.split('/');
  const currentLang = pathParts.length > 1 ? pathParts[1] : 'en';
  
  const handleSuccess = () => {
    navigate(`/${currentLang}/success`);
  };
  
  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-3xl font-bold text-center mb-6">
        {t('form.title') || import.meta.env.VITE_FORM_NAME || 'Contact Form'}
      </h1>
      
      <div className="bg-white p-6 rounded-lg shadow-md">
        <p className="text-gray-600 mb-6">
          {t('form.description') || import.meta.env.VITE_FORM_DESCRIPTION || 
            'Fill out the form below to send your inquiry. We will get back to you as soon as possible.'}
        </p>
        
        <ContactForm onSuccess={handleSuccess} language={i18n.language} />
      </div>
    </div>
  );
};

export default FormPage;
