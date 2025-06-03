# 🏗️ Frontend Separation Plan

## Why Separate Frontend Applications?

### ❌ Problems with Monorepo Approach
- Mysterious `index.js` files appearing and causing deployment conflicts
- Complex build processes with multiple entry points
- Frontend deployment issues affecting backend stability
- Difficult debugging when multiple apps interfere with each other

### ✅ Benefits of Separated Repositories

#### 🔒 **Isolation**
- Each frontend app has its own repository
- No cross-contamination of build files
- Independent deployment pipelines
- Easier to debug and maintain

#### 🚀 **Deployment**
- Frontend: Azure Static Web Apps (perfect for React/SPA)
- Backend: Azure Container Apps (perfect for FastAPI APIs)
- Independent release cycles
- Reduced deployment complexity

#### 🧹 **Cleaner Code**
- Each repo has single responsibility
- Simpler project structure
- Focused dependencies
- Better team collaboration

## New Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SEPARATED ARCHITECTURE                    │
└─────────────────────────────────────────────────────────────┘

🏢 BACKEND (this repo)
├── hsq-form-platform/
│   ├── apps/app/                    # FastAPI backend
│   ├── infra/                       # Azure infrastructure  
│   └── docker/                      # Backend containers
│   
📱 FRONTEND REPOS (separate)
├── hsq-feedback-form/               # React feedback form
│   ├── src/                         # React app
│   ├── .github/workflows/           # Azure SWA deployment
│   └── public/
│
├── hsq-support-form/                # React support form  
│   ├── src/                         # React app
│   ├── .github/workflows/           # Azure SWA deployment
│   └── public/
│
└── hsq-contact-form/                # React contact form
    ├── src/                         # React app
    ├── .github/workflows/           # Azure SWA deployment
    └── public/
```

## Implementation Plan

### Phase 1: Backend Cleanup ✅ (DONE)
- [x] Remove all frontend apps from this repo
- [x] Remove frontend deployment workflows  
- [x] Update README to reflect backend-only focus
- [x] Commit cleaned backend repository

### Phase 2: Create New Frontend Repositories
1. **Create hsq-feedback-form repo**
   - Clone existing form code
   - Set up clean React + Vite project
   - Configure Azure Static Web Apps deployment
   - Test deployment independently

2. **Create hsq-support-form repo**
   - Similar setup as feedback form
   - Independent deployment pipeline

3. **Create hsq-contact-form repo** (if needed)
   - Additional form types as needed

### Phase 3: Connect Frontend to Backend
```typescript
// In each frontend app
const API_BASE_URL = 'https://hsq-forms-api.agreeableglacier-1e56cfbb.westeurope.azurecontainerapps.io';

// API calls
const response = await fetch(`${API_BASE_URL}/api/forms/submit`, {
  method: 'POST',
  headers: { 
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*'
  },
  body: JSON.stringify(formData)
});
```

### Phase 4: CORS Configuration
Update backend to allow frontend domains:
```python
# In FastAPI backend
from fastapi.middleware.cors import CORSMiddleware

origins = [
    "https://feedback.yourdomain.com",
    "https://support.yourdomain.com", 
    "https://contact.yourdomain.com"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Next Steps

1. **Commit this cleanup** ✅
2. **Create first frontend repo** (hsq-feedback-form)
3. **Set up Azure Static Web Apps**
4. **Test end-to-end connection**
5. **Replicate for other forms**

## Benefits Achieved
- ✅ No more `index.js` conflicts
- ✅ Simpler debugging
- ✅ Independent deployments  
- ✅ Better scalability
- ✅ Cleaner code organization
- ✅ Faster development cycles
