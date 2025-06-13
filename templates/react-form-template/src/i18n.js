import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

const resources = {
  en: {
    translation: {
      form: {
        name: 'Name',
        email: 'Email',
        submit: 'Submit',
      },
    },
  },
  se: {
    translation: {
      form: {
        name: 'Namn',
        email: 'E-post',
        submit: 'Skicka',
      },
    },
  },
};

i18n.use(initReactI18next).init({
  resources,
  lng: 'en',
  fallbackLng: 'en',
  interpolation: {
    escapeValue: false,
  },
});

export default i18n;
