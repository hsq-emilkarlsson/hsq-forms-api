# HSQ Forms Container - B2B Feedback

This containerized form application provides a multilingual B2B feedback portal that integrates with the HSQ Forms API. The form supports Swedish (/se), English (/en), and German (/de) languages.

## Features
- **B2B-specific feedback form** with company information, contact details, and structured feedback categories
- **Multilingual support** with URL-based language routing (/se, /en, /de)
- **React Hook Form** for form handling and validation
- **Zod** for robust form validation
- **Tailwind CSS** for modern, responsive design
- **Docker containerization** for easy deployment
- **TypeScript** for type safety
- **Integration** with HSQ Forms API backend

## Getting Started

### Development
1. Install dependencies:
   ```bash
   npm install
   ```
2. Start the development server:
   ```bash
   npm run dev
   ```
3. Access the form:
   - English: http://localhost:5173/en
   - Swedish: http://localhost:5173/se  
   - German: http://localhost:5173/de

### Docker Development Workflow

#### Quick Start
```bash
# First time setup
docker-compose up --build

# Access your app at: http://localhost:3001
```

#### Daily Development (Recommended)
```bash
# For quick changes and updates
./dev-helper.sh quick

# For active development with live reload
./dev-helper.sh dev

# Check what's running
./dev-helper.sh status

# Stop everything
./dev-helper.sh stop
```

#### Manual Docker Commands
```bash
# Build and run
docker-compose up --build

# Rebuild after changes
docker-compose down && docker-compose up --build

# Clean rebuild (if something breaks)
docker-compose build --no-cache && docker-compose up
```

> **📖 For detailed development guide, see [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)**


## Form Fields

The B2B feedback form includes:

### Company Information
- Company Name (required)
- Business Type (dropdown: Technology, Manufacturing, Consulting, etc.)

### Contact Information  
- Contact Person (required)
- Email Address (required)
- Phone Number (optional)

### Feedback Details
- Feedback Category (Product, Service, Partnership, Support, Other)
- Priority Level (Low, Medium, High)
- Detailed Message (required, min 10 characters)
- Follow-up Request (checkbox)

## API Integration

The form submits data to the HSQ Forms API at:
```
POST /api/forms/submit
```

With payload:
```json
{
  "form_type": "b2b-feedback",
  "data": {
    "companyName": "...",
    "contactPerson": "...",
    // ... other form fields
  }
}
```

## Language Support

- **English (en)**: Default language
- **Swedish (se)**: Full translation including business terms
- **German (de)**: Complete German localization

Languages are automatically detected from the URL path and can be switched using the language selector in the header.

## Container Deployment

This form is designed to work with the HSQ Forms API container deployment system. Use the main project's deployment scripts:

```bash
# From the main HSQ Forms API directory
./scripts/deploy-container.sh local hsq-forms-container-b2b-feedback
```

### Multi-language Support
- Access `/se` for Swedish and `/en` for English.

### API Integration
- Configure the backend API URL in `.env`:
   ```env
   VITE_API_URL=http://localhost:8000/api
   ```
