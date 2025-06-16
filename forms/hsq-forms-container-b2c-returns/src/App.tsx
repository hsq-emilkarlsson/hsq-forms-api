import React, { Suspense, useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate, useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import B2CReturnsForm from './components/B2CReturnsForm';
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
    if (lang && ['sv', 'en', 'de'].includes(lang)) {
      i18n.changeLanguage(lang);
    }
  }, [lang, i18n]);

  return <>{children}</>;
}

// Main page component with header and form
function FormPage() {
  const { t } = useTranslation();
  const { lang } = useParams<{ lang: string }>();
  const [isEmbedded, setIsEmbedded] = useState(false);
  const [isCompact, setIsCompact] = useState(false);

  useEffect(() => {
    // Detect if running in iframe
    const inIframe = window.self !== window.top;
    setIsEmbedded(inIframe);

    // Check URL parameters for embedding options
    const urlParams = new URLSearchParams(window.location.search);
    const embedMode = urlParams.get('embed');
    const compactMode = urlParams.get('compact');
    
    if (embedMode === 'true' || embedMode === '1') {
      setIsEmbedded(true);
    }
    
    if (compactMode === 'true' || compactMode === '1') {
      setIsCompact(true);
    }

    // Apply iframe-specific styles to body
    if (inIframe || embedMode) {
      document.body.classList.add('iframe-embedded');
    }
  }, []);

  // For embedded/iframe mode, show simplified layout
  if (isEmbedded) {
    return (
      <div className="min-h-screen bg-transparent p-0">
        <main className="w-full">
          <B2CReturnsForm isEmbedded={true} compact={isCompact} />
        </main>
      </div>
    );
  }

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

      {/* Main content */}
      <main className="max-w-3xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="mb-6">
            <h2 className="text-2xl font-bold text-gray-900 mb-2">
              {t('returns.title', 'Product Return Request')}
            </h2>
            <p className="text-gray-600">
              {t('returns.description', 'Please fill out this form to initiate a product return request.')}
            </p>
          </div>
          
          <B2CReturnsForm isEmbedded={false} compact={false} />
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