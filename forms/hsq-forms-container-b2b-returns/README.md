# HSQ B2B Returns Form

A production-ready React application for handling B2B product returns, built with TypeScript, Vite, and Tailwind CSS.

## 🚀 Production Deployment

```bash
# Start the container
docker-compose up -d

# App available at: http://localhost:3002
```

## ✨ Features

- **Multi-language Support**: English, Swedish, German
- **Form Validation**: Real-time validation with Zod and React Hook Form
- **Responsive Design**: Mobile-first with Tailwind CSS
- **Product Returns Specific**: Order numbers, serial numbers, return reasons
- **API Integration**: Connects to HSQ Forms API at localhost:8000
- **Dockerized**: Ready for production deployment

## 🔧 Configuration

### Environment Variables
```bash
# .env file
VITE_API_BASE_URL=http://localhost:8000
VITE_APP_TITLE=HSQ B2B Returns Form
```

## 📊 Container Management

### Basic Commands

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f

# Restart container
docker-compose restart

# Stop container
docker-compose down
```

### Health Verification

```bash
# Check if form is accessible
curl -I http://localhost:3002

# Should return: HTTP/1.1 200 OK
```

## 📋 Form Fields

The B2B Returns form includes:

- **Company Information**: Name, contact person, email, phone
- **Product Details**: Model, serial number, purchase date
- **Return Information**: Order number, return reason, condition
- **Processing**: Refund method, urgency level, additional notes

## 🌍 Language Support

- **English (EN)**: Default language
- **Swedish (SE)**: Complete translation
- **German (DE)**: Complete translation

Switch languages using the language selector in the top-right corner.

## 🏗️ Project Structure

```
src/
├── components/
│   ├── B2BReturnsForm.tsx    # Main returns form
│   └── LanguageSelector.tsx   # Language switcher
├── App.tsx                    # Main app with routing
├── main.tsx                   # React entry point
├── index.css                  # Tailwind CSS styles
└── i18n.js                    # Internationalization
```

## 🐳 Docker Configuration

- **Production Mode**: Port 3002, serves static files with `serve`
- **Development Mode**: Port 3002, live reload with Vite
- **API Connection**: http://localhost:8000

## 📚 Integration

### Sitecore CMS Integration

```html
<!-- Basic iframe embedding -->
<iframe src="http://localhost:3002" width="100%" height="800px"></iframe>

<!-- With URL parameters -->
<iframe src="http://localhost:3002?lang=sv&embed=true" width="100%" height="600px"></iframe>
```

### API Integration

The form submits to the HSQ Forms API using template-based submissions:

- **Template ID**: Auto-configured for B2B Returns
- **Submission Endpoint**: `POST /api/templates/{template_id}/submit`
- **File Upload Support**: Multi-file attachment capability

## 🔗 Related

This container is part of the HSQ Forms API system:
- **Main API**: `/../../` (HSQ Forms API)
- **Feedback Form**: `../hsq-forms-container-b2b-feedback/`

## 🛠️ Tech Stack

- **React 18** with TypeScript
- **Vite 5** for build tooling
- **Tailwind CSS** for styling
- **React Hook Form** + **Zod** for form handling
- **i18next** for internationalization
- **Docker** for containerization
