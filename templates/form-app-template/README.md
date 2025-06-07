# HSQ Form App Template

A React application with TypeScript designed to build forms that communicate with the HSQ Forms API. This project is configured for an excellent development experience with Docker and is ready to be deployed as an Azure Static Web App.

## Features

- **React** with **TypeScript** for type-safe coding
- **React Hook Form** for simple and efficient form handling
- **Zod** for form data validation
- **i18next** for multilingual support
- **Docker** for consistent development environment
- **Vite** for fast development and building
- **Azure Static Web Apps configuration** for easy deployment
- **Axios** for API communication
- **Tailwind CSS** for beautiful and responsive design
- **ESLint** and **Prettier** for code quality

## Multilingual Support

This template includes built-in multilingual support:

- Language-based routing (`/en/form`, `/sv/form`)
- Localized UI components
- Automatic language detection
- Language selector component
- Integration with the Forms API's language endpoints

## Form Components

This template includes three main form components that you can use out-of-the-box:

1. **ContactForm** - A basic contact form with name, email, phone, and message fields
2. **ContactFormWithFile** - A contact form that also supports file uploads
3. **DynamicForm** - A configurable form component that renders fields based on a configuration object

All form components support multilingual content and automatically adapt to the selected language.

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- Docker and Docker Compose (for containerized development)
- Azure CLI (for deployment)

### Installation

#### Option 1: Local Development

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create a `.env.local` file based on `.env.example`:
   ```bash
   cp .env.example .env.local
   ```

3. Update the API URL in `.env.local` to the address where HSQ Forms API is running.

4. Start the development server:
   ```bash
   npm run dev
   ```

#### Option 2: Docker Development

1. Build and start the container:
   ```bash
   docker-compose up
   ```

2. The application will be available at `http://localhost:3000`.

### Configuration

Configure the API connection by editing `.env.local`:

```
VITE_API_URL=http://localhost:8000/api
VITE_API_KEY=your-api-key-here
```

#### Azure Configuration

For Azure integration, add the following to your `.env.local`:

```
VITE_AZURE_ENABLED=true
VITE_AZURE_STORAGE_URL=https://your-storage-account.blob.core.windows.net
```

## Project Structure

```
form-app-template/
├── .github/workflows/     # GitHub Actions workflows for CI/CD
├── public/                # Static files
├── src/                   # Source code
│   ├── api/               # API connections and services
│   ├── components/        # Reusable components
│   ├── contexts/          # React Contexts (e.g. FormContext)
│   ├── hooks/             # Custom hooks
│   ├── pages/             # Page components
│   ├── types/             # TypeScript definitions
│   ├── utils/             # Utility functions
│   ├── App.tsx            # Main application component
│   └── main.tsx           # Application entry point
├── .eslintrc.js           # ESLint configuration
├── .prettierrc            # Prettier configuration
├── Dockerfile             # Docker configuration for development
├── docker-compose.yml     # Docker Compose configuration
├── index.html             # HTML entry point
├── package.json           # Project dependencies
├── staticwebapp.config.json # Azure Static Web App configuration
├── tailwind.config.js     # Tailwind CSS configuration
├── tsconfig.json          # TypeScript configuration
└── vite.config.ts         # Vite configuration
```

## Kommunicera med HSQ Forms API

### Development Environment

During development, the application points to the API URL specified in `.env.local`. To avoid CORS issues, the development server uses a proxy configuration that automatically forwards API calls.

### Production Environment

In Azure Static Web Apps, the API connection is configured through `staticwebapp.config.json`. This allows the application to communicate with the HSQ Forms API deployed in the same resource group.

## Deployment to Azure Static Web Apps

### Using GitHub Actions

1. Push the code to a GitHub repository
2. In the Azure Portal, create a new Azure Static Web App and link to your repository
3. The GitHub Actions workflow will automatically build and deploy your app

### Manual Deployment

1. Build the application:
   ```bash
   npm run build
   ```

2. Deploy to Azure Static Web Apps with Azure CLI:
   ```bash
   az staticwebapp create --name "your-form-app" --resource-group "your-resource-group" --source "." --location "West Europe" --api-location "api"
   ```

See [AZURE_DEPLOYMENT.md](AZURE_DEPLOYMENT.md) for detailed deployment instructions.

## Documentation

This template includes comprehensive documentation:

- [DOCS.md](DOCS.md) - Documentation index
- [CUSTOMIZATION.md](CUSTOMIZATION.md) - How to customize forms
- [INTEGRATION.md](INTEGRATION.md) - API integration details
- [AZURE_DEPLOYMENT.md](AZURE_DEPLOYMENT.md) - Azure deployment guide

## Customizing Forms

1. Open `src/components/ContactForm.tsx` to see an example form
2. Modify or create new form components for your specific needs
3. Update the validation schema in `src/utils/validation.ts`
4. Customize the form's appearance with Tailwind CSS classes

## Enhanced Features

### Azure Integration
The template includes full integration with Azure services:
- **Application Insights** for analytics and monitoring
- **Azure Blob Storage** integration for file uploads
- **Environment-specific configurations** for development, staging, and production

### Advanced Form Handling
- **Form Context API** for state management across components
- **Error handling with retry mechanism** for robust API communication
- **Accessibility compliance** with ARIA attributes and keyboard navigation

### Security Features
- **Enhanced Content Security Policy** following security best practices
- **Proper CORS configuration** for secure API communication
- **Modern security headers** to protect against common web vulnerabilities

### Testing Framework
- **Jest** and **React Testing Library** for component and API tests
- **Mock Service Worker** for API mocking in tests
- **Example test suite** for ContactForm component

## Additional Resources

- [React Hook Form documentation](https://react-hook-form.com/)
- [Zod documentation](https://github.com/colinhacks/zod)
- [Azure Static Web Apps documentation](https://docs.microsoft.com/azure/static-web-apps/)
- [Web Content Accessibility Guidelines (WCAG)](https://www.w3.org/WAI/standards-guidelines/wcag/)
