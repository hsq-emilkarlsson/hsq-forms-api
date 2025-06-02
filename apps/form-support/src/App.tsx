import { useState } from 'react';
import './App.css';
import FileUpload, { type FileUploadResult } from './FileUpload';

// Interface för support-formulärdata
interface SupportFormData {
  name: string;
  email: string;
  subject: string;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  category: 'technical' | 'billing' | 'product' | 'warranty' | 'other';
  product_model?: string;
  serial_number?: string;
  message: string;
  form_type: string;
  metadata?: Record<string, unknown>;
}

// Interface för API-svar
interface ApiResponse {
  status: 'success' | 'error';
  message: string;
  submission_id?: string;
  errors?: string[];
}

function App() {
  const [formData, setFormData] = useState<SupportFormData>({
    name: '',
    email: '',
    subject: '',
    priority: 'medium',
    category: 'technical',
    product_model: '',
    serial_number: '',
    message: '',
    form_type: 'support_ticket',
    metadata: {
      source: 'support_web',
      page: window.location.pathname,
      timestamp: new Date().toISOString(),
    }
  });

  const [status, setStatus] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<string[]>([]);
  const [submissionId, setSubmissionId] = useState<string | null>(null);
  const [showFileUpload, setShowFileUpload] = useState(false);
  const [uploadResults, setUploadResults] = useState<FileUploadResult[]>([]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleFilesUploaded = (files: FileUploadResult[]) => {
    setUploadResults(files);
    const successfulUploads = files.filter(f => f.success);
    if (successfulUploads.length > 0) {
      setStatus(prevStatus => 
        prevStatus + ` ${successfulUploads.length} fil(er) har laddats upp.`
      );
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrors([]);

    try {
      // API-URL för utveckling och produktion
      const isProd = import.meta.env.PROD;
      const apiUrl = isProd
        ? 'https://hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io/submit'
        : 'http://localhost:8000/submit';

      const res = await fetch(apiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          ...formData,
          metadata: {
            ...formData.metadata,
            priority: formData.priority,
            category: formData.category,
            product_model: formData.product_model,
            serial_number: formData.serial_number,
            subject: formData.subject,
          }
        }),
      });

      const result = await res.json() as ApiResponse;
      
      if (result.status === 'success') {
        setStatus('Ditt support-ärende har skickats! Vi återkommer inom 24 timmar.');
        setSubmissionId(result.submission_id || null);
        setShowFileUpload(true);
        // Rensa formuläret vid lyckad sändning
        setFormData({
          name: '',
          email: '',
          subject: '',
          priority: 'medium',
          category: 'technical',
          product_model: '',
          serial_number: '',
          message: '',
          form_type: 'support_ticket',
          metadata: {
            source: 'support_web',
            page: window.location.pathname,
            timestamp: new Date().toISOString(),
          }
        });
      } else {
        setStatus('Ett fel uppstod vid skickning av ärendet.');
        setErrors(result.errors || ['Okänt fel']);
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
    <div className="form-container">
      <h1>🛠️ Support & Teknisk Hjälp</h1>
      <p>Behöver du hjälp med din Husqvarna-produkt? Fyll i formuläret nedan så hjälper vi dig.</p>
      
      <form onSubmit={handleSubmit}>
        <div className="form-row">
          <div className="form-group">
            <label htmlFor="name">Namn *</label>
            <input 
              type="text" 
              id="name"
              name="name" 
              value={formData.name} 
              onChange={handleChange} 
              required 
              disabled={isSubmitting}
              placeholder="Ditt för- och efternamn"
            />
          </div>
          
          <div className="form-group">
            <label htmlFor="email">E-post *</label>
            <input 
              type="email" 
              id="email"
              name="email" 
              value={formData.email} 
              onChange={handleChange} 
              required 
              disabled={isSubmitting}
              placeholder="din.epost@example.com"
            />
          </div>
        </div>

        <div className="form-group">
          <label htmlFor="subject">Ämne *</label>
          <input 
            type="text" 
            id="subject"
            name="subject" 
            value={formData.subject} 
            onChange={handleChange} 
            required 
            disabled={isSubmitting}
            placeholder="Kort beskrivning av problemet"
          />
        </div>

        <div className="form-row">
          <div className="form-group">
            <label htmlFor="category">Kategori *</label>
            <select 
              id="category"
              name="category" 
              value={formData.category} 
              onChange={handleChange} 
              required 
              disabled={isSubmitting}
            >
              <option value="technical">🔧 Tekniskt problem</option>
              <option value="product">📦 Produktfråga</option>
              <option value="warranty">🛡️ Garanti & reklamation</option>
              <option value="billing">💳 Fakturering</option>
              <option value="other">❓ Annat</option>
            </select>
          </div>

          <div className="form-group">
            <label htmlFor="priority">Prioritet</label>
            <select 
              id="priority"
              name="priority" 
              value={formData.priority} 
              onChange={handleChange} 
              disabled={isSubmitting}
            >
              <option value="low">🟢 Låg - Allmän fråga</option>
              <option value="medium">🟡 Medium - Behöver hjälp</option>
              <option value="high">🟠 Hög - Brådskande</option>
              <option value="urgent">🔴 Akut - Stoppar arbetet</option>
            </select>
          </div>
        </div>

        <div className="form-row">
          <div className="form-group">
            <label htmlFor="product_model">Produktmodell</label>
            <input 
              type="text" 
              id="product_model"
              name="product_model" 
              value={formData.product_model} 
              onChange={handleChange} 
              disabled={isSubmitting}
              placeholder="t.ex. Automower 450X, Chainsaw 572XP"
            />
          </div>

          <div className="form-group">
            <label htmlFor="serial_number">Serienummer</label>
            <input 
              type="text" 
              id="serial_number"
              name="serial_number" 
              value={formData.serial_number} 
              onChange={handleChange} 
              disabled={isSubmitting}
              placeholder="Finns på produktens märkning"
            />
          </div>
        </div>
        
        <div className="form-group">
          <label htmlFor="message">Detaljerad beskrivning *</label>
          <textarea 
            id="message"
            name="message" 
            value={formData.message} 
            onChange={handleChange} 
            required 
            disabled={isSubmitting}
            rows={6}
            placeholder="Beskriv ditt problem så detaljerat som möjligt. Inkludera felmeddelanden, när problemet uppstår, och vad du redan har försökt..."
          />
        </div>
        
        <button type="submit" disabled={isSubmitting} className="submit-button">
          {isSubmitting ? '📤 Skickar ärende...' : '🚀 Skicka support-ärende'}
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

      {showFileUpload && submissionId && (
        <div className="file-upload-section">
          <h2>Bifoga filer (valfritt)</h2>
          <p>Du kan bifoga filer som skärmdumpar, felloggar eller andra dokument som kan hjälpa oss att lösa ditt problem snabbare.</p>
          <FileUpload
            submissionId={submissionId}
            onFilesUploaded={handleFilesUploaded}
            maxFiles={5}
            maxSizePerFile={10 * 1024 * 1024} // 10MB
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
        </div>
      )}

      <div className="help-section">
        <h3>💡 Innan du skickar ärendet</h3>
        <ul>
          <li>🔍 Kolla vår <a href="#" target="_blank">kunskapsbas</a> för vanliga lösningar</li>
          <li>📱 Ladda ner vår <a href="#" target="_blank">Husqvarna Connect-app</a> för snabb hjälp</li>
          <li>📞 Ring kundservice: <strong>0771-19 19 30</strong> (vardagar 8-17)</li>
        </ul>
      </div>
    </div>
  );
}

export default App;