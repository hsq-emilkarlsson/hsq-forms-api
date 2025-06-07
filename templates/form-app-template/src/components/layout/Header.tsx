import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const Header = () => {
  const { t } = useTranslation();
  const location = useLocation();
  
  // Extract language code from URL to use in navigation
  const pathParts = location.pathname.split('/');
  const currentLang = pathParts.length > 1 && ['en', 'sv', 'us', 'se'].includes(pathParts[1]) 
    ? pathParts[1] 
    : 'en';
  return (
    <header className="bg-white shadow-sm">
      <div className="container mx-auto px-4 py-4 flex justify-between items-center">
        <Link to={`/${currentLang}`} className="text-xl font-bold text-primary-600">
          {t('title') || import.meta.env.VITE_FORM_NAME || 'HSQ Forms'}
        </Link>
        
        <nav>
          <ul className="flex space-x-4">
            <li>
              <Link to={`/${currentLang}`} className="text-gray-600 hover:text-primary-600">
                {t('nav.home')}
              </Link>
            </li>
            <li>
              <Link to={`/${currentLang}/form`} className="text-gray-600 hover:text-primary-600">
                {t('nav.forms')}
              </Link>
            </li>
            <li>
              <Link to={`/${currentLang}/azure-example`} className="text-gray-600 hover:text-primary-600">
                Azure Example
              </Link>
            </li>
          </ul>
        </nav>
      </div>
    </header>
  );
};

export default Header;
