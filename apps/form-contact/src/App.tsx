import { useState } from 'react';
import './App.css';

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

function App() {
  const [formData, setFormData] = useState<FormData>({
    name: '',
    email: '',
    message: '',
    form_type: 'contact',
    metadata: {
      source: 'web',
      page: window.location.pathname,
    }
  });

  const [status, setStatus] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errors, setErrors] = useState<string[]>([]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
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
        body: JSON.stringify(formData),
      });

      const result = await res.json() as ApiResponse;
      
      if (result.status === 'success') {
        setStatus(result.message || 'Formuläret har skickats!');
        // Rensa formuläret vid lyckad sändning
        setFormData({
          name: '',
          email: '',
          message: '',
          form_type: 'contact',
          metadata: formData.metadata
        });
      } else {
        setStatus('Ett fel uppstod.');
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
      <h1>Kontakta oss</h1>
      
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label htmlFor="name">Namn:</label>
          <input 
            type="text" 
            id="name"
            name="name" 
            value={formData.name} 
            onChange={handleChange} 
            required 
            disabled={isSubmitting}
          />
        </div>
        
        <div className="form-group">
          <label htmlFor="email">E-post:</label>
          <input 
            type="email" 
            id="email"
            name="email" 
            value={formData.email} 
            onChange={handleChange} 
            required 
            disabled={isSubmitting}
          />
        </div>
        
        <div className="form-group">
          <label htmlFor="message">Meddelande:</label>
          <textarea 
            id="message"
            name="message" 
            value={formData.message} 
            onChange={handleChange} 
            required 
            disabled={isSubmitting}
            rows={5}
          />
        </div>
        
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Skickar...' : 'Skicka'}
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
  );
}

export default App;