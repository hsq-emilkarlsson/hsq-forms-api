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
  // ...existing code...
}

export default function App() {
  return (
    <Router>
      <Suspense fallback={<LoadingComponent />}>
        <Header />
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/form" element={<FormPage />} />
          <Route path="/success" element={<SuccessPage />} />
          <Route path="/azure-example" element={<AzureExamplePage />} />
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
        <Footer />
      </Suspense>
    </Router>
  );
}
