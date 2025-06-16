# HSQ B2B Support Form

A production-ready React application for handling B2B support requests, built with TypeScript, Vite, and Tailwind CSS.

## 🚀 Production Deployment

```bash
# Start the container
docker-compose up -d

# App available at: http://localhost:3003
```

## ✨ Features

- **Multi-language Support**: English, Swedish, German
- **Form Validation**: Real-time validation with Zod and React Hook Form
- **Responsive Design**: Mobile-first with Tailwind CSS
- **Support Request Specific**: Customer validation, technical support, urgency levels
- **API Integration**: Connects to HSQ Forms API at localhost:8000
- **Production Ready**: Optimized Docker container

## 🔧 Configuration

### Environment Variables

```bash
# .env file
VITE_API_BASE_URL=http://localhost:8000
VITE_APP_TITLE=HSQ B2B Support Form
```

### Available Commands
```bash
./dev-helper.sh status   # Check container status
./dev-helper.sh quick    # Quick rebuild
./dev-helper.sh dev      # Development mode
./dev-helper.sh clean    # Clean rebuild
./dev-helper.sh stop     # Stop containers
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

## 📚 Documentation

- [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) - Detailed development workflow
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Quick commands reference

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
