# Newsletter Form Example

## Quick Setup Commands
```bash
# 1. Copy contact form structure
cp -r apps/form-contact apps/form-newsletter

# 2. Update package.json
cd apps/form-newsletter
sed -i '' 's/"form-contact"/"form-newsletter"/g' package.json

# 3. Update vite.config.ts port
sed -i '' 's/3001/3003/g' vite.config.ts

# 4. Update form title in index.html
sed -i '' 's/Kontakta Oss/Prenumerera på Nyhetsbrev/g' index.html
```

## Newsletter Form Component (src/App.tsx)
```tsx
import { useState } from 'react'
import './App.css'

function App() {
  const [formData, setFormData] = useState({
    email: '',
    name: '',
    interests: [],
    frequency: 'weekly'
  })

  const handleSubmit = async (e) => {
    e.preventDefault()
    
    const response = await fetch('API_URL/submit', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        ...formData,
        form_type: 'newsletter',
        message: `Newsletter subscription: ${formData.interests.join(', ')}`
      })
    })
    
    if (response.ok) {
      alert('Prenumeration registrerad!')
      setFormData({ email: '', name: '', interests: [], frequency: 'weekly' })
    }
  }

  return (
    <div className="newsletter-form">
      <h1>Prenumerera på Vårt Nyhetsbrev</h1>
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label>E-post *</label>
          <input 
            type="email" 
            value={formData.email}
            onChange={(e) => setFormData({...formData, email: e.target.value})}
            required 
          />
        </div>
        
        <div className="form-group">
          <label>Namn</label>
          <input 
            type="text" 
            value={formData.name}
            onChange={(e) => setFormData({...formData, name: e.target.value})}
          />
        </div>

        <div className="form-group">
          <label>Frekvens</label>
          <select 
            value={formData.frequency}
            onChange={(e) => setFormData({...formData, frequency: e.target.value})}
          >
            <option value="daily">Daglig</option>
            <option value="weekly">Veckovis</option>
            <option value="monthly">Månadsvis</option>
          </select>
        </div>

        <button type="submit">Prenumerera</button>
      </form>
    </div>
  )
}

export default App
```

## Add to Docker Compose
```yaml
form-newsletter:
  build: ../apps/form-newsletter
  ports:
    - "3003:3000"
  environment:
    - REACT_APP_API_URL=http://localhost:8000
```

## Deployment Time
- **Local testing**: 2 minutes
- **Azure deployment**: 5 minutes (just the new form)
- **Total effort**: ~20 minutes for a complete new form

## Benefits of This Architecture
✅ **Modular**: Each form is independent
✅ **Scalable**: Add unlimited forms easily  
✅ **Maintainable**: Changes to one form don't affect others
✅ **Cost-effective**: Small container apps, pay per use
✅ **Fast deployments**: Only rebuild what changed
