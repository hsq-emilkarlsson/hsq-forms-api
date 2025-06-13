import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import Backend from 'i18next-http-backend';
import LanguageDetector from 'i18next-browser-languagedetector';

i18n
  // Load translation using http backend
  .use(Backend)
  // Detect user language
  .use(LanguageDetector)
  // Pass the i18n instance to react-i18next
  .use(initReactI18next)
  // init i18next
  .init({
    fallbackLng: 'sv',
    debug: process.env.NODE_ENV === 'development',
    
    interpolation: {
      escapeValue: false, // not needed for react as it escapes by default
    },
    
    // Detection options
    detection: {
      // Order and from where user language should be detected
      order: ['path', 'localStorage', 'navigator', 'htmlTag'],
      
      // Keys or params to lookup language from
      lookupPath: 'lang',
      lookupFromPathIndex: 0,
      
      // Cache user language
      caches: ['localStorage'],
      
      // Only detect languages that are in the whitelist
      checkWhitelist: true
    },

    backend: {
      loadPath: '/locales/{{lng}}/translation.json',
    },

    // Define supported languages
    supportedLngs: ['sv', 'en'],
    
    // Do not load a fallback
    load: 'languageOnly',
    
    // Remove country code from language
    cleanCode: true,
    
    // Default namespace
    defaultNS: 'translation',
    
    // Resources can be added directly here for faster initial load
    resources: undefined // Let it load from backend
  });

export default i18n;
