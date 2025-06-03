import { useState } from 'react';
import './App.css';
import FileUpload, { type FileUploadResult } from './FileUpload';

interface AppProps {
  lang: string;
  translations: any;
}

// Interface för formulärdata
interface FormData {
  name: string;
  email: string;
  message: string;
  form_type?: string;
  metadata?: Record<string, unknown>;
}

// Interface för API-svar
interface ApiResponse {
  status: 'success' | 'error';
  message: string;
  submission_id?: string;
  errors?: string[];
}

function App({ lang, translations }: AppProps) {
  const [formData, setFormData] = useState<FormData>({
    name: '',
    email: '',
    message: '',
    form_type: 'contact', // Ändrat från 'feedback' till 'contact' för att matcha backend
    metadata: {
      source: 'web',
      page: window.location.pathname,
    }
  });

  const [status, setStatus] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<string[]>([]);
  const [submissionId, setSubmissionId] = useState<string | null>(null);
  const [showFileUpload, setShowFileUpload] = useState(true); // Alltid visa filuppladdning
  const [uploadResults, setUploadResults] = useState<FileUploadResult[]>([]);
  const [uploadedFiles, setUploadedFiles] = useState<FileUploadResult[]>([]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleFilesUploaded = (files: FileUploadResult[]) => {
    setUploadResults(files);
    const successfulUploads = files.filter(f => f.success);
    if (successfulUploads.length > 0) {
      setUploadedFiles(prev => [...prev, ...successfulUploads]);
      setStatus(`${successfulUploads.length} fil(er) har laddats upp.`);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrors([]);

    // Frontendvalidering
    const newErrors: string[] = [];
    if (!formData.name.trim()) {
      newErrors.push(translations.validation.name);
    }
    // Enkel e-postvalidering
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!formData.email.trim() || !emailRegex.test(formData.email)) {
      newErrors.push(translations.validation.email);
    }
    if (!formData.message || formData.message.trim().length < 10) {
      newErrors.push(translations.validation.message);
    }
    if (newErrors.length > 0) {
      setErrors(newErrors);
      setStatus(translations.error);
      setIsSubmitting(false);
      return;
    }

    try {
      // API-URL för utveckling och produktion
      const isProd = import.meta.env.PROD;
      const apiUrl = isProd
        ? import.meta.env.VITE_API_URL || 'https://hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io/submit'
        : 'http://localhost:8000/submit';
      // Inkludera eventuella uppladdade file_ids och säkerställ form_type alltid är 'contact'
      const formDataWithFiles = {
        ...formData,
        form_type: 'contact',
        files: uploadedFiles.map(file => file.file_id).filter(Boolean)
      };

      const res = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formDataWithFiles),
      });

      const result = await res.json() as ApiResponse;
      
      if (result.status === 'success') {
        setStatus(translations.success);
        setSubmissionId(result.submission_id || null);
        setShowFileUpload(true);
        // Rensa formuläret vid lyckad sändning
        setFormData({
          name: '',
          email: '',
          message: '',
          form_type: 'contact'
        });
      } else {
        // Förbättrad felhantering: visa backend-meddelande och logga allt
        console.error('API error response:', result);
        setStatus(result.message || translations.error);
        setErrors(result.errors && result.errors.length > 0 ? result.errors : [result.message || translations.error]);
      }
    } catch (err) {
      console.error('Fel vid skickning:', err);
      setStatus('Ett fel uppstod vid kommunikation med servern.');
      setErrors(['Kontrollera din internetanslutning och försök igen.']);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="husqvarna-bg">
      <div className="form-container husqvarna-form">
        <div className="logo-wrapper">
          <img
            src="https://portal.husqvarnagroup.com/static/b2b/assets/with-name.4d5589ae.svg"
            alt="Husqvarna logo"
            className="husqvarna-logo"
          />
        </div>
        <header className="app-header">
          <h1>{translations.title}</h1>
          <p>{translations.subtitle}</p>
        </header>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="name">{translations.name}</label>
            <input
              type="text"
              id="name"
              name="name"
              value={formData.name}
              onChange={handleChange}
              required
              disabled={isSubmitting}
              minLength={2}
              placeholder={translations.name}
            />
          </div>
          <div className="form-group">
            <label htmlFor="email">{translations.email}</label>
            <input
              type="email"
              id="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              required
              disabled={isSubmitting}
              placeholder="namn@exempel.se"
              pattern="^[^\s@]+@[^\s@]+\.[^\s@]+$"
              autoComplete="email"
            />
          </div>
          <div className="form-group">
            <label htmlFor="message">{translations.message}</label>
            <textarea
              id="message"
              name="message"
              value={formData.message}
              onChange={handleChange}
              required
              disabled={isSubmitting}
              rows={5}
              minLength={10}
              placeholder={translations.messagePlaceholder}
            />
          </div>
          {showFileUpload && (
            <div className="file-upload-section">
              <h2>{translations.attachFiles}</h2>
              <p>{translations.attachFilesDesc}</p>
              <FileUpload
                submissionId={submissionId || undefined}
                onFilesUploaded={handleFilesUploaded}
                maxFiles={5}
                maxSizePerFile={10 * 1024 * 1024}
                temporaryUploads={true}
              />
              {uploadResults.length > 0 && (
                <div className="upload-results">
                  <h3>Uppladdningsresultat:</h3>
                  <ul>
                    {uploadResults.map((result, index) => (
                      <li key={index} className={result.success ? 'success' : 'error'}>
                        {result.original_filename}: {result.message}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
              {uploadedFiles.length > 0 && (
                <div className="uploaded-files">
                  <h3>Uppladdade filer:</h3>
                  <ul>
                    {uploadedFiles.map((file, index) => (
                      <li key={index}>{file.original_filename}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          )}
          <button 
            type="submit" 
            disabled={isSubmitting} 
            className="submit-button"
            style={{ 
              backgroundColor: '#002F6C', 
              color: '#fff',
              padding: '12px 20px', 
              width: '100%',
              fontSize: '1rem', 
              fontWeight: 600,
              borderRadius: '6px',
              minHeight: '48px',
              border: 'none',
              marginTop: '24px'
            }} // Fullständiga inline-styles för att säkerställa korrekt rendering
          >
            {isSubmitting ? translations.submitting : translations.submit}
          </button>
        </form>
        {status && (
          <div className={`status-message ${errors.length > 0 ? 'error' : 'success'}`}>
            <p>{status}</p>
            {errors.length > 0 && (
              <ul className="error-list">
                {errors.map((error, index) => (
                  <li key={index}>{error}</li>
                ))}
              </ul>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;