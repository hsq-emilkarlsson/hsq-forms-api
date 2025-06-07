import React, { Suspense } from 'react';
import ReactDOM from 'react-dom/client';
import App from './App.tsx';
import './index.css';
import './i18n';  // Import i18n configuration before the app
import { FormProvider } from './contexts/FormContext';
import { setupAzureAnalytics } from './utils/azureIntegration';

// Initialize Azure services if enabled
setupAzureAnalytics({
  enableAutoRouteTracking: true,
});

// Loading component to show while i18n is initializing
const Loader = () => (
  <div className="flex items-center justify-center h-screen">
    <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
  </div>
);

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <Suspense fallback={<Loader />}>
      <FormProvider>
        <App />
      </FormProvider>
    </Suspense>
  </React.StrictMode>
);
