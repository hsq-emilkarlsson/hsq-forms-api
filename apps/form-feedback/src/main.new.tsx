// This is the main entry point for Vite
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'
import { BrowserRouter, Routes, Route, Navigate, useParams } from 'react-router-dom'
import localesRaw from './locales.json'
import ErrorBoundary from './ErrorBoundary'

// Import these to make sure they're included in the build
import 'react'
import 'react-dom'
import 'react-router-dom'

// Type check locales with proper typing
interface LocaleData {
  [key: string]: string
}

interface Locales {
  [lang: string]: LocaleData
}

const locales = localesRaw as Locales

// AppWithLang component that safely selects language based on URL parameter
function AppWithLang() {
  const params = useParams<{ lang: string }>()
  const { lang } = params
  
  // Safe language selection with fallback
  const language = lang && locales[lang] ? lang : 'se'
  
  return <App lang={language} translations={locales[language]} />
}

// Main rendering with error handling
const rootElement = document.getElementById('root')
if (rootElement) {
  try {
    console.log('DEBUG: Mounting React app')
    
    // För felsökning - se om locales laddas korrekt
    console.log('DEBUG: Locales loaded:', Object.keys(locales))

    ReactDOM.createRoot(rootElement).render(
      <React.StrictMode>
        <ErrorBoundary>
          <BrowserRouter basename="">
            <Routes>
              <Route path="/" element={<Navigate to="/se" replace />} />
              <Route path="/se" element={<App lang="se" translations={locales.se} />} />
              <Route path="/en" element={<App lang="en" translations={locales.en} />} />
              <Route path="/:lang/*" element={<AppWithLang />} />
              <Route path="*" element={<Navigate to="/se" replace />} />
            </Routes>
          </BrowserRouter>
        </ErrorBoundary>
      </React.StrictMode>
    )
    
    console.log('DEBUG: React render completed')
  } catch (error) {
    console.error('CRITICAL ERROR DURING RENDER:', error)
    rootElement.innerHTML = `
      <div style="color: red; padding: 20px; border: 2px solid red; margin: 20px;">
        <h2>Något gick fel vid laddning av appen</h2>
        <p>Error: ${error instanceof Error ? error.message : String(error)}</p>
        <button onclick="window.location.reload()">Ladda om sidan</button>
      </div>
    `
  }
} else {
  // If no root element found, add visible error
  console.error('No root element found')
  document.body.innerHTML = '<div style="background: red; color: white; padding: 20px; text-align: center;"><h1>CRITICAL ERROR: No root element found!</h1></div>'
}
