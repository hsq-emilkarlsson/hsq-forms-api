import React, { Suspense, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import B2BReturnsForm from './components/B2BReturnsForm';
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
    if (lang && ['se', 'en', 'de'].includes(lang)) {
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
          <div className="flex justify-between items-center py-4">
            <div>
              <h1 className="text-xl font-semibold text-gray-900">
                HSQ Forms
              </h1>
              <p className="text-sm text-gray-600">
                {t('app.subtitle', 'B2B Returns Portal')}
              </p>
            </div>
            <LanguageSelector />
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="max-w-3xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="mb-6">
            <h2 className="text-2xl font-bold text-gray-900 mb-2">
              {t('returns.title', 'Product Return Request')}
            </h2>
            <p className="text-gray-600">
              {t('returns.description', 'Please fill out this form to initiate a product return request. We will process your request and get back to you within 2-3 business days.')}
            </p>
          </div>
          
          <B2BReturnsForm />
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-white border-t mt-12">
        <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <p className="text-center text-sm text-gray-500">
            {t('app.footer', '© 2024 HSQ Forms. All rights reserved.')}
          </p>
        </div>
      </footer>
    </div>
  );
}

function App() {
  return (
    <Router>
      <Suspense fallback={<LoadingComponent />}>
        <Routes>
          {/* Default route redirects to English */}
          <Route path="/" element={<Navigate to="/en" replace />} />
          
          {/* Language-specific routes */}
          <Route path="/:lang" element={
            <LanguageRoute>
              <FormPage />
            </LanguageRoute>
          } />
          
          {/* Catch all route - redirect to English */}
          <Route path="*" element={<Navigate to="/en" replace />} />
        </Routes>
      </Suspense>
    </Router>
  );
}

export default App;