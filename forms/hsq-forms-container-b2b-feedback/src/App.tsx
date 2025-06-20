import React, { Suspense, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import B2BFeedbackForm from './components/B2BFeedbackForm';
import LanguageSelector from './components/LanguageSelector';
import './i18n'; // Import i18n configuration

// Loading component to show while translations are loading
const LoadingComponent = () => (
  <div className="flex justify-center items-center h-screen">
    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
  </div>
);

// Language wrapper component
function LanguageRoute({ children }: { children: React.ReactNode }) {
  const { lang } = useParams<{ lang: string }>();
  const { i18n } = useTranslation();

  useEffect(() => {
    if (lang && ['sv', 'en', 'da', 'no', 'fi', 'de'].includes(lang)) {
      i18n.changeLanguage(lang);
    }
  }, [lang, i18n]);

  return <>{children}</>;
}

// Main page component with header and form
function FormPage() {
  const { t } = useTranslation();
  const { lang } = useParams<{ lang: string }>();

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-center items-center py-4 relative">
            {/* Centered Husqvarna Logo */}
            <div className="flex items-center justify-center">
              <img 
                src="https://portal.husqvarnagroup.com/static/b2b/assets/with-name.4d5589ae.svg" 
                alt="Husqvarna Group" 
                className="h-16 w-16"
              />
            </div>
            
            {/* Language Selector positioned to the right */}
            <div className="absolute right-0">
              <LanguageSelector />
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <B2BFeedbackForm />
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-white border-t mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <p className="text-center text-sm text-gray-500">
            © 2025 HSQ Forms API. {t('app.footer', 'All rights reserved.')}
          </p>
        </div>
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <Router>
      <Suspense fallback={<LoadingComponent />}>
        <Routes>
          {/* Redirect root to default language */}
          <Route path="/" element={<Navigate to="/en" replace />} />
          
          {/* Language-specific routes */}
          <Route path="/:lang" element={
            <LanguageRoute>
              <FormPage />
            </LanguageRoute>
          } />
          
          {/* Catch all other routes */}
          <Route path="*" element={<Navigate to="/en" replace />} />
        </Routes>
      </Suspense>
    </Router>
  );
}
