import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';
import { BrowserRouter, Routes, Route, Navigate, useParams } from 'react-router-dom';
import localesRaw from './locales.json';

// Typa locales korrekt
const locales: Record<string, any> = localesRaw;

function AppWithLang() {
  const { lang } = useParams();
  const language = lang && locales[lang] ? lang : 'se';
  return <App lang={language} translations={locales[language]} />;
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/se" replace />} />
        <Route path=":lang" element={<AppWithLang />} />
      </Routes>
    </BrowserRouter>
  </React.StrictMode>
);

export {};
