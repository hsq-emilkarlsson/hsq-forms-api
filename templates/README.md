# HSQ Forms API Templates

This directory contains templates for creating applications that use the HSQ Forms API as a backend.

## Available Templates

- **react-form-template** - A modern, containerized React application with:
  - React Hook Form and Zod validation
  - Multi-language support (Swedish, English, German)
  - Tailwind CSS for styling
  - Docker and docker-compose setup
  - Complete development and production configuration

## Usage

To create a new form, copy the template to the `forms/` directory:

```bash
# Create a new form based on the template
cp -r templates/react-form-template forms/your-new-form-name
cd forms/your-new-form-name

# Install dependencies and start development
npm install
npm run dev
```

For production deployment:

```bash
# Build and run with Docker
docker-compose up --build
```

## Project Structure

- `templates/` - Contains the base template for creating new forms
- `forms/` - Contains all deployed form applications
  - Each form is a separate containerized React application
  - Forms communicate with the HSQ Forms API backend

## Customization

Each form can be customized independently:

- Update `src/components/Form.tsx` for form fields and validation
- Modify translations in `src/i18n.js` for multi-language support
- Adjust styling in Tailwind CSS classes
- Configure API endpoints in `.env` file
