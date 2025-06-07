import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { useCallback } from 'react';

// Language option with label and value
interface LanguageOption {
  label: string;
  value: string;
  country: string;
}

const LanguageSelector = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  
  // Define available languages
  const languages: LanguageOption[] = [
    { label: 'English (US)', value: 'en', country: 'us' },
    { label: 'Svenska (SE)', value: 'sv', country: 'se' },
  ];
  
  // Get current path without language prefix
  const getCurrentPath = useCallback(() => {
    const path = window.location.pathname;
    const parts = path.split('/');
    
    // Check if the first part is a language code
    if (parts.length > 1 && ['en', 'sv', 'us', 'se'].includes(parts[1])) {
      // Return the path without the language prefix
      return '/' + parts.slice(2).join('/');
    }
    
    // Return the current path if no language prefix is found
    return path;
  }, []);

  // Handle language change
  const handleLanguageChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const selectedCountry = event.target.value;
    const selectedLang = languages.find(lang => lang.country === selectedCountry);
    
    if (selectedLang) {
      i18n.changeLanguage(selectedLang.value);
      
      // Navigate to the same path but with the new language prefix
      const currentPath = getCurrentPath();
      const newPath = `/${selectedCountry}${currentPath === '/' ? '' : currentPath}`;
      navigate(newPath);
    }
  };
  
  // Determine current country code from URL
  const getCurrentCountry = () => {
    const path = window.location.pathname;
    const parts = path.split('/');
    
    if (parts.length > 1 && ['en', 'sv', 'us', 'se'].includes(parts[1])) {
      return parts[1];
    }
    
    return 'en'; // Default to English
  };

  return (
    <div className="flex items-center justify-end mb-4">
      <label htmlFor="language-select" className="mr-2 text-sm font-medium text-gray-700">
        {t('nav.language')}:
      </label>
      <select
        id="language-select"
        className="bg-white border border-gray-300 text-gray-700 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-1.5"
        onChange={handleLanguageChange}
        value={getCurrentCountry()}
      >
        {languages.map((lang) => (
          <option key={lang.value} value={lang.country}>
            {lang.label}
          </option>
        ))}
      </select>
    </div>
  );
};

export default LanguageSelector;
