import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route, Navigate, useParams } from 'react-router-dom';
import App from './App';
import './index.css';
import ErrorBoundary from './ErrorBoundary';
import localesRaw from './locales.json';

// Type definitions
interface LocaleData {
  [key: string]: string;
}

interface Locales {
  [lang: string]: LocaleData;
}

const locales = localesRaw as Locales;

// Language wrapper component
function AppWithLang() {
  const params = useParams<{ lang: string }>();
  const { lang } = params;
  
  const language = lang && locales[lang] ? lang : 'se';
  
  return <App lang={language} translations={locales[language]} />;
}

// Initialize app
const rootElement = document.getElementById('root');

if (!rootElement) {
  console.error('Root element not found');
  document.body.innerHTML = `
    <div style="background: #ff4444; color: white; padding: 20px; text-align: center;">
      <h1>🚫 KRITISKT FEL</h1>
      <p>Root element saknas. Kontakta support.</p>
    </div>
  `;
} else {
  try {
    console.log('🚀 Starting Husqvarna Form Feedback App');
    console.log('📍 Available languages:', Object.keys(locales));
    
    ReactDOM.createRoot(rootElement).render(
      <React.StrictMode>
        <ErrorBoundary>
          <BrowserRouter>
            <Routes>
              <Route path="/" element={<Navigate to="/se" replace />} />
              <Route path="/se" element={<App lang="se" translations={locales.se} />} />
              <Route path="/en" element={<App lang="en" translations={locales.en} />} />
              <Route path="/:lang" element={<AppWithLang />} />
              <Route path="*" element={<Navigate to="/se" replace />} />
            </Routes>
          </BrowserRouter>
        </ErrorBoundary>
      </React.StrictMode>
    );
    
    console.log('✅ App initialized successfully');
  } catch (error) {
    console.error('❌ Failed to initialize app:', error);
    rootElement.innerHTML = `
      <div style="background: #ff4444; color: white; padding: 20px; text-align: center; font-family: Arial, sans-serif;">
        <h1>🚫 Något gick fel</h1>
        <p><strong>Fel:</strong> ${error instanceof Error ? error.message : String(error)}</p>
        <button onclick="window.location.reload()" style="background: white; color: #ff4444; padding: 10px 20px; border: none; border-radius: 4px; margin-top: 10px; cursor: pointer;">
          🔄 Ladda om sidan
        </button>
      </div>
    `;
  }
}
