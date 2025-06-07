import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Suspense, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import HomePage from './pages/HomePage';
import FormPage from './pages/FormPage';
import SuccessPage from './pages/SuccessPage';
import NotFoundPage from './pages/NotFoundPage';
import AzureExamplePage from './pages/AzureExamplePage';
import Header from './components/layout/Header';
import Footer from './components/layout/Footer';
import './i18n'; // Import i18n configuration
import LanguageSelector from './components/LanguageSelector';

// Loading component to show while translations are loading
const LoadingComponent = () => (
  <div className="flex justify-center items-center h-screen">
    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
  </div>
);

function LanguageRoute({ children }: { children: React.ReactNode }) {
  const { i18n } = useTranslation();
  const currentPath = window.location.pathname;
  
  // Extract language from path if it exists
  const pathParts = currentPath.split('/');
  const langFromPath = pathParts[1];
  const supportedLanguages = ['en', 'sv', 'us', 'se']; // Add all supported language/country codes
  
  useEffect(() => {
    // Map country codes to language codes if needed
    const languageMap: Record<string, string> = {
      'us': 'en',
      'se': 'sv'
    };
    
    if (supportedLanguages.includes(langFromPath)) {
      // Use mapped language or the path language directly
      const languageToUse = languageMap[langFromPath] || langFromPath;
      i18n.changeLanguage(languageToUse);
    }
  }, [langFromPath, i18n]);
  
  return <>{children}</>;
}

function App() {
  return (
    <Router>
      <Suspense fallback={<LoadingComponent />}>
        <LanguageRoute>
          <div className="flex flex-col min-h-screen">
            <Header />
            <div className="container mx-auto px-4 py-2">
              <LanguageSelector />
            </div>
            <main className="flex-grow container mx-auto px-4 py-8">
              <Routes>
                {/* Default routes with language prefix */}
                <Route path="/" element={<Navigate to="/en" replace />} />
                
                {/* English routes */}
                <Route path="/en" element={<HomePage />} />
                <Route path="/en/form" element={<FormPage />} />
                <Route path="/en/azure-example" element={<AzureExamplePage />} />
                <Route path="/en/success" element={<SuccessPage />} />
                
                {/* Swedish routes */}
                <Route path="/sv" element={<HomePage />} />
                <Route path="/sv/form" element={<FormPage />} />
                <Route path="/sv/azure-example" element={<AzureExamplePage />} />
                <Route path="/sv/success" element={<SuccessPage />} />
                
                {/* Country code routes (US) */}
                <Route path="/us" element={<HomePage />} />
                <Route path="/us/form" element={<FormPage />} />
                <Route path="/us/azure-example" element={<AzureExamplePage />} />
                <Route path="/us/success" element={<SuccessPage />} />
                
                {/* Country code routes (SE) */}
                <Route path="/se" element={<HomePage />} />
                <Route path="/se/form" element={<FormPage />} />
                <Route path="/se/azure-example" element={<AzureExamplePage />} />
                <Route path="/se/success" element={<SuccessPage />} />
                
                {/* Catch-all for 404 */}
                <Route path="*" element={<NotFoundPage />} />
              </Routes>
            </main>
            <Footer />
          </div>
        </LanguageRoute>
      </Suspense>
    </Router>
  );
}

export default App;
