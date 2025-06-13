# React Form Template

This template is designed for creating dynamic forms with React, supporting multi-language functionality, validation, and integration with a backend API. It is containerized for easy deployment in both development and production environments.

## Features
- React Hook Form for form handling.
- Zod for validation.
- `react-i18next` for multi-language support.
- Dockerized setup for seamless development and production.

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

### Docker
1. Build the Docker image:
   ```bash
   docker build -t react-form-template .
   ```
2. Run the container:
   ```bash
   docker-compose up
   ```

### Multi-language Support
- Access `/se` for Swedish and `/en` for English.

### API Integration
- Configure the backend API URL in `.env`:
   ```env
   VITE_API_URL=http://localhost:8000/api
   ```
