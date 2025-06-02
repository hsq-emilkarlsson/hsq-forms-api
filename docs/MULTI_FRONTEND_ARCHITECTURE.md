# Multi-Frontend Architecture Plan

## Arkitektur-översikt

```
Backend API (FastAPI)
├── Port: 8000
├── Database: PostgreSQL
└── CORS: Stöder flera frontend-portar

Frontend Applications:
├── Contact Form (5173) - Befintlig
├── Newsletter Form (3001) - Planerad
├── Job Application Form (3002) - Planerad
├── Admin Dashboard (3003) - Planerad
└── Shared Components Package - Planerad
```

## Deployment-strategier

### Option A: Separata Container Apps (Rekommenderad för produktion)
```
Azure Container Apps:
├── hsq-api-backend (API)
├── hsq-contact-form (React)
├── hsq-newsletter-form (React)
├── hsq-admin-dashboard (React)
└── hsq-shared-components (NPM Package)
```

### Option B: Mono-deployment med flera builds
```
Single Container App:
├── Backend API (/api/*)
├── Contact Form (/contact/*)
├── Newsletter Form (/newsletter/*)
└── Admin Dashboard (/admin/*)
```

## Nästa steg

1. **Skapa Newsletter Form**
   ```bash
   cd apps/
   npx create-vite@latest newsletter-form --template react-ts
   ```

2. **Skapa Shared Components Package**
   ```bash
   cd packages/
   mkdir shared-components
   npm init -y
   ```

3. **Uppdatera Docker Compose för utveckling**
   - Lägg till newsletter-form service
   - Lägg till admin-dashboard service
   - Konfigurera nätverk mellan services

4. **Deployment**
   - Skapa Azure Container Apps för varje frontend
   - Konfigurera Azure Database for PostgreSQL
   - Sätt upp CDN för statiska assets

## Fördelar med denna arkitektur

✅ **Skalbarhet**: Varje frontend kan utvecklas oberoende
✅ **Performance**: Separata builds och deployments
✅ **Team-struktur**: Olika team kan äga olika formulär
✅ **Maintenance**: Enkelt att underhålla och uppdatera
✅ **Teknologi-flexibilitet**: Kan använda olika frontend-tech per app

## Nackdelar att vara medveten om

⚠️ **Komplexitet**: Fler services att hantera
⚠️ **Kostnad**: Fler container apps i produktion
⚠️ **Koordination**: Behöver koordinera API-ändringar
⚠️ **Shared State**: Behöver hantera delad state mellan appar
