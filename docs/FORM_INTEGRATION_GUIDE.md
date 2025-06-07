# HSQ Forms API - Integrationsguide

## Översikt
HSQ Forms API är ett enkelt backend-system som tar emot formulärdata och filer från olika frontend-applikationer och sparar dem i en PostgreSQL-databas.

API:et har två olika API-strukturer:
1. **Legacy API**: Enkla endpoints som `/submit` och `/files/upload/{submission_id}`
2. **Flexibla formulär API**: Endpoints som börjar med `/api/forms/...`

## API Endpoints

### 1. Skicka Formulärdata
**POST** `/submit`

#### Request Body (JSON):
```json
{
  "form_type": "contact",  // Typ av formulär (obligatorisk)
  "name": "John Doe",      // Namn (obligatorisk)
  "email": "john@example.com",  // E-post (obligatorisk)
  "message": "Mitt meddelande här",  // Meddelande (obligatorisk)
  "metadata": {            // Extra data (valfri)
    "company": "Acme Corp",
    "phone": "+46701234567",
    "subject": "Supportärende"
  }
}
```

#### Response:
```json
{
  "status": "success",
  "message": "Formuläret har sparats!",
  "submission_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

### 2. Ladda upp Filer
**POST** `/files/upload/{submission_id}`

#### Request (multipart/form-data):
- `files`: En eller flera filer (submission_id finns i URL:en)

#### Response:
```json
{
  "status": "success",
  "message": "2 filer uppladdade",
  "uploaded_files": [
    {
      "id": "file123",
      "original_filename": "dokument.pdf",
      "file_size": 1024000,
      "content_type": "application/pdf",
      "upload_status": "uploaded"
    }
  ]
}
```

## Komplett Formulärintegration

### 1. HTML Formulär med JavaScript

```html
<!DOCTYPE html>
<html>
<head>
    <title>Kontaktformulär</title>
</head>
<body>
    <form id="contactForm">
        <input type="text" id="name" placeholder="Namn" required>
        <input type="email" id="email" placeholder="E-post" required>
        <textarea id="message" placeholder="Meddelande" required></textarea>
        
        <!-- Filuppladdning -->
        <input type="file" id="files" multiple accept=".pdf,.doc,.docx,.jpg,.png">
        
        <!-- Extra fält -->
        <input type="text" id="company" placeholder="Företag">
        <input type="tel" id="phone" placeholder="Telefon">
        
        <button type="submit">Skicka</button>
    </form>

    <script>
        const API_BASE = 'http://localhost:8001'; // Ändra för produktion

        document.getElementById('contactForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            try {
                // 1. Skicka formulärdata först
                const formData = {
                    form_type: 'contact',
                    name: document.getElementById('name').value,
                    email: document.getElementById('email').value,
                    message: document.getElementById('message').value,
                    metadata: {
                        company: document.getElementById('company').value,
                        phone: document.getElementById('phone').value
                    }
                };

                const submitResponse = await fetch(`${API_BASE}/submit`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(formData)
                });

                const submitResult = await submitResponse.json();
                
                if (!submitResponse.ok) {
                    throw new Error(submitResult.detail || 'Fel vid skickning av formulär');
                }

                // 2. Ladda upp filer om det finns några
                const fileInput = document.getElementById('files');
                if (fileInput.files.length > 0) {
                    const fileFormData = new FormData();
                    
                    for (let file of fileInput.files) {
                        fileFormData.append('files', file);
                    }

                    const fileResponse = await fetch(`${API_BASE}/files/upload/${submitResult.submission_id}`, {
                        method: 'POST',
                        body: fileFormData
                    });

                    const fileResult = await fileResponse.json();
                    
                    if (!fileResponse.ok) {
                        console.warn('Filuppladdning misslyckades:', fileResult.detail);
                    }
                }

                alert('Formulär skickat!');
                document.getElementById('contactForm').reset();
                
            } catch (error) {
                console.error('Fel:', error);
                alert('Ett fel uppstod: ' + error.message);
            }
        });
    </script>
</body>
</html>
```

### 2. React Komponent

```jsx
import React, { useState } from 'react';

const ContactForm = () => {
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        message: '',
        company: '',
        phone: ''
    });
    const [files, setFiles] = useState([]);
    const [loading, setLoading] = useState(false);
    
    const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8001';
    
    const handleFileChange = (e) => {
        setFiles([...e.target.files]);
    };
    
    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        
        try {
            // 1. Skicka formulärdata
            const submitData = {
                form_type: 'contact',
                name: formData.name,
                email: formData.email,
                message: formData.message,
                metadata: {
                    company: formData.company,
                    phone: formData.phone
                }
            };
            
            const submitResponse = await fetch(`${API_BASE}/submit`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(submitData)
            });
            
            const submitResult = await submitResponse.json();
            
            if (!submitResponse.ok) {
                throw new Error(submitResult.detail || 'Fel vid skickning av formulär');
            }

            // 2. Ladda upp filer
            if (files.length > 0) {
                const fileFormData = new FormData();
                fileFormData.append('submission_id', submitResult.submission_id);
                
                files.forEach(file => {
                    fileFormData.append('files', file);
                });

                const fileResponse = await fetch(`${API_BASE}/files/upload/${submitResult.submission_id}`, {
                    method: 'POST',
                    body: fileFormData
                });

                if (!fileResponse.ok) {
                    console.warn('Filuppladdning misslyckades');
                }
            }

            alert('Formulär skickat!');
            setFormData({ name: '', email: '', message: '', company: '', phone: '' });
            setFiles([]);

        } catch (error) {
            console.error('Fel:', error);
            alert('Ett fel uppstod: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <form onSubmit={handleSubmit}>
            <input
                type="text"
                placeholder="Namn"
                value={formData.name}
                onChange={(e) => setFormData({...formData, name: e.target.value})}
                required
            />
            <input
                type="email"
                placeholder="E-post"
                value={formData.email}
                onChange={(e) => setFormData({...formData, email: e.target.value})}
                required
            />
            <textarea
                placeholder="Meddelande"
                value={formData.message}
                onChange={(e) => setFormData({...formData, message: e.target.value})}
                required
            />
            <input
                type="text"
                placeholder="Företag"
                value={formData.company}
                onChange={(e) => setFormData({...formData, company: e.target.value})}
            />
            <input
                type="tel"
                placeholder="Telefon"
                value={formData.phone}
                onChange={(e) => setFormData({...formData, phone: e.target.value})}
            />
            <input
                type="file"
                multiple
                accept=".pdf,.doc,.docx,.jpg,.png"
                onChange={handleFileChange}
            />
            <button type="submit" disabled={loading}>
                {loading ? 'Skickar...' : 'Skicka'}
            </button>
        </form>
    );
};

export default ContactForm;
```

### 3. Vue.js Komponent

```vue
<template>
  <form @submit.prevent="handleSubmit">
    <input 
      type="text" 
      placeholder="Namn" 
      v-model="formData.name" 
      required
    />
    <input 
      type="email" 
      placeholder="E-post" 
      v-model="formData.email" 
      required
    />
    <textarea 
      placeholder="Meddelande" 
      v-model="formData.message" 
      required
    ></textarea>
    <input 
      type="text" 
      placeholder="Företag" 
      v-model="formData.company"
    />
    <input 
      type="tel" 
      placeholder="Telefon" 
      v-model="formData.phone"
    />
    <input 
      type="file" 
      @change="handleFileChange" 
      multiple 
      accept=".pdf,.doc,.docx,.jpg,.png"
    />
    <button type="submit" :disabled="loading">
      {{ loading ? 'Skickar...' : 'Skicka' }}
    </button>
  </form>
</template>

<script>
export default {
  name: 'ContactForm',
  data() {
    return {
      formData: {
        name: '',
        email: '',
        message: '',
        company: '',
        phone: ''
      },
      files: [],
      loading: false,
      apiBase: process.env.VUE_APP_API_URL || 'http://localhost:8001'
    }
  },
  methods: {
    handleFileChange(event) {
      this.files = Array.from(event.target.files);
    },
    async handleSubmit() {
      this.loading = true;
      
      try {
        // 1. Skicka formulärdata
        const submitData = {
          form_type: 'contact',
          name: this.formData.name,
          email: this.formData.email,
          message: this.formData.message,
          metadata: {
            company: this.formData.company,
            phone: this.formData.phone
          }
        };

        const submitResponse = await fetch(`${this.apiBase}/submit`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(submitData)
        });

        const submitResult = await submitResponse.json();

        if (!submitResponse.ok) {
          throw new Error(submitResult.detail || 'Något gick fel');
        }

        // 2. Ladda upp filer
        if (this.files.length > 0) {
          const fileFormData = new FormData();
          
          this.files.forEach(file => {
            fileFormData.append('files', file);
          });

          const fileResponse = await fetch(`${this.apiBase}/files/upload/${submitResult.submission_id}`, {
            method: 'POST',
            body: fileFormData
          });

          if (!fileResponse.ok) {
            console.warn('Filuppladdning misslyckades');
          }
        }

        alert('Formulär skickat!');
        this.formData = { name: '', email: '', message: '', company: '', phone: '' };
        this.files = [];
        
      } catch (error) {
        console.error('Fel:', error);
        alert('Ett fel uppstod: ' + error.message);
      } finally {
        this.loading = false;
      }
    }
  }
}
</script>
```

## Filhantering - Viktiga punkter

### Tillåtna filtyper
API:et stöder följande filtyper:
- Dokument: `.pdf`, `.doc`, `.docx`, `.txt`
- Bilder: `.jpg`, `.jpeg`, `.png`, `.gif`
- Kalkylblad: `.xls`, `.xlsx`

### Filstorlek
- Max 10MB per fil
- Max 5 filer per formulär

### Säkerhet
- Alla filer skannas för säkerhetsrisker
- Filnamn rensas från farliga tecken
- Filer sparas med säkra, slumpmässiga filnamn

## Miljövariabler för Frontend

### Development
```env
REACT_APP_API_URL=http://localhost:8001
VUE_APP_API_URL=http://localhost:8001
```

### Production
```env
REACT_APP_API_URL=https://your-api.azurewebsites.net
VUE_APP_API_URL=https://your-api.azurewebsites.net
```

## CORS Konfiguration

API:et är konfigurerat för att acceptera requests från:
- `http://localhost:3000` (React dev server)
- `http://localhost:5173` (Vite dev server)
- `http://localhost:8080` (Vue dev server)

För produktion, lägg till din domän i `ALLOWED_ORIGINS` miljövariabeln.

## Felsökning

### Vanliga fel

1. **CORS-fel**: Kontrollera att din frontend-URL är tillåten
2. **Filuppladdning misslyckas**: Kontrollera filstorlek och typ
3. **404 på endpoints**: Kontrollera att API:et körs på rätt port

### Debug-tips
- Kontrollera nätverkstrafik i webbläsarens utvecklarverktyg
- Titta på API-loggar för detaljerade felmeddelanden
- Testa endpoints med Postman eller curl först

## Exempel på olika formulärtyper

### Legacy-formulär

Du kan använda olika `form_type` värden för att kategorisera formulär:
- `contact` - Kontaktformulär
- `support` - Supportärenden  
- `feedback` - Feedback/recensioner
- `application` - Ansökningar
- `newsletter` - Nyhetsbrev

Alla sparas i samma databas men kan filtreras och hanteras separat.

## Flexibla formulärmallar

API:et stöder nu dynamiska formulärmallar som kan skapas och anpassas efter behov. Denna API använder ett annat endpoint-prefix (`/api/forms`) och erbjuder mer avancerade funktioner.

### 1. Skapa formulärmall

**POST** `/api/forms/templates`

#### Request Body (JSON):
```json
{
  "title": "Kontaktformulär",
  "description": "Ett anpassat kontaktformulär",
  "project_id": "website-v2",
  "schema": {
    "fields": [
      {
        "name": "name",
        "label": "Namn",
        "type": "text",
        "required": true,
        "placeholder": "Ange ditt namn"
      },
      {
        "name": "email",
        "label": "E-post",
        "type": "email",
        "required": true,
        "placeholder": "Din e-postadress"
      },
      {
        "name": "message",
        "label": "Meddelande",
        "type": "textarea",
        "required": true,
        "placeholder": "Skriv ditt meddelande här"
      }
    ]
  },
  "settings": {
    "submit_button_text": "Skicka",
    "success_message": "Tack för ditt meddelande!"
  }
}
```

#### Response:
```json
{
  "id": "form_template_123",
  "title": "Kontaktformulär",
  "description": "Ett anpassat kontaktformulär",
  "project_id": "website-v2",
  "schema": { ... },
  "settings": { ... },
  "created_at": "2023-05-30T14:30:00Z",
  "updated_at": "2023-05-30T14:30:00Z",
  "is_active": true
}
```

### 2. Hämta Formulärschema

**GET** `/api/forms/templates/{template_id}/schema`

#### Response:
```json
{
  "title": "Kontaktformulär",
  "description": "Ett anpassat kontaktformulär",
  "schema": {
    "fields": [ ... ]
  },
  "settings": { ... }
}
```

### 3. Skicka Formulärdata för Flexibelt Formulär

**POST** `/api/forms/templates/{template_id}/submit`

#### Request Body (JSON):
```json
{
  "data": {
    "name": "John Doe",
    "email": "john@example.com",
    "message": "Mitt meddelande här"
  }
}
```

#### Response:
```json
{
  "status": "success",
  "message": "Formulär skickat framgångsrikt",
  "submission_id": "submission_789",
  "submitted_at": "2023-06-04T10:15:00Z"
}
```

## Integration med Azure Static Web Apps

För frontend-applikationer som körs på Azure Static Web Apps, följ dessa steg för att integrera med HSQ Forms API:

### 1. Konfigurera miljövariabler

I Azure Portal:
1. Navigera till din Static Web App
2. Gå till "Configuration" > "Application settings"
3. Lägg till:
   ```
   API_URL=https://your-hsq-forms-api.azurewebsites.net
   ```

### 2. Konfigurera CORS

Lägg till din Static Web App URL i `ALLOWED_ORIGINS` för HSQ Forms API (formatet är normalt `https://{app-name}.azurestaticapps.net`).

### 3. Exempel på frontend-konfiguration

```javascript
// api.js - Konfiguration för HSQ Forms API integration
const API_CONFIG = {
  baseUrl: process.env.API_URL || 'https://your-hsq-forms-api.azurewebsites.net',
  routes: {
    submit: '/submit',
    fileUpload: '/files/upload',
    formTemplates: '/api/forms/templates'
  }
};

export async function submitForm(formData) {
  try {
    const response = await fetch(`${API_CONFIG.baseUrl}${API_CONFIG.routes.submit}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(formData)
    });
    
    return await response.json();
  } catch (error) {
    console.error('Error submitting form:', error);
    throw error;
  }
}
```

### 4. GitHub Actions Workflow

```yaml
name: Azure Static Web Apps CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    types: [opened, synchronize, reopened, closed]
    branches:
      - main

jobs:
  build_and_deploy_job:
    if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
    runs-on: ubuntu-latest
    name: Build and Deploy
    steps:
      - uses: actions/checkout@v2
      - name: Build And Deploy
        id: builddeploy
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          app_location: "/" 
          output_location: "build" # för React, eller "dist" för Vue
          app_settings: |
            API_URL=${{ secrets.API_URL }}
```
