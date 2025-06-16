# HSQ B2C Returns Form

A React-based web application for handling consumer product returns, built with TypeScript, Vite, and Tailwind CSS. Designed for iframe embedding in Sitecore CMS.

## 🚀 Quick Start

```bash
# Build and start the container
docker-compose up --build

# App available at: http://localhost:3006
```

## ✨ Features

- **B2C Consumer Focus**: Personal information fields, optional order numbers
- **Multi-language Support**: English, Swedish, German
- **Sitecore Integration**: Full iframe embedding support with EFF compatibility
- **Responsive Design**: Mobile-first with Tailwind CSS
- **Form Validation**: Real-time validation with user-friendly error messages
- **API Integration**: Template-based submission to HSQ Forms API
- **Accessibility**: WCAG compliant with screen reader support

## 🌐 Sitecore Integration

The form is designed for iframe embedding in Sitecore CMS:

```html
<!-- Standard Embedding -->
<iframe src="http://localhost:3006" width="100%" height="800px"></iframe>

<!-- Compact Mode -->
<iframe src="http://localhost:3006?embed=true&compact=true" width="100%" height="600px"></iframe>
```

For complete integration instructions, see `SITECORE_INTEGRATION_GUIDE.md`.

## 📋 Form Fields

The B2C Returns form includes:

**Personal Information**:
- First Name, Last Name, Email, Phone
- Address, Postal Code, City

**Product Information**:
- Product Name, Serial Number, Purchase Date
- Order Number (optional for B2C customers)

**Return Details**:
- Issue Description, Return Reason, Product Condition
- Preferred Refund Method

## 🌍 Language Support

- **English (EN)**: Default language
- **Swedish (SV)**: Complete translation  
- **German (DE)**: Complete translation

Switch languages using the URL parameter: `?lang=sv` or `?lang=de`

## 🏗️ Project Structure

```
src/
├── components/
│   ├── B2CReturnsForm.tsx    # Main B2C returns form
│   └── LanguageSelector.tsx   # Language switcher
├── App.tsx                    # Main app with iframe detection
├── main.tsx                   # React entry point
├── index.css                  # Tailwind CSS + iframe optimization
└── i18n.js                    # Internationalization setup
```

## 🐳 Docker Configuration

- **Production Port**: 3006 (unique for B2C forms)
- **API Connection**: http://localhost:8000/api
- **Template ID**: Currently using B2B Support template
- **Build**: Optimized production bundle with nginx

## 🛠️ Tech Stack

- **React 18** with TypeScript
- **Vite 5** for build tooling
- **Tailwind CSS** for styling and responsive design
- **Zod** for form validation
- **i18next** for internationalization
- **Docker** for containerization

## 📞 Support

For integration questions or technical support, refer to the Sitecore Integration Guide included with this form.
