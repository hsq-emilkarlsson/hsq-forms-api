# HSQ Forms API Templates

This directory contains templates for creating applications that use the HSQ Forms API as a backend.

## Available Templates

- **form-app-template** - A React application with React Hook Form and TypeScript for creating forms that communicate with the HSQ Forms API. Features include:
  - Contact forms with validation
  - File upload handling
  - Azure Blob Storage integration
  - Multiple form components (basic, with files, dynamic)
  - Complete deployment configuration for Azure Static Web Apps

## Usage

To use a template, copy the entire folder to a new project:

```bash
cp -r templates/form-app-template /path/to/new-form-project
cd /path/to/new-form-project
```

Then follow the instructions in the template's own README.md file to get started.

## Azure Integration

The form-app-template includes full Azure integration with:

- Azure Static Web Apps deployment configuration
- GitHub Actions CI/CD workflow
- Azure Blob Storage integration for file uploads
- Comprehensive deployment documentation in AZURE_DEPLOYMENT.md

## Customization

Each template includes detailed documentation on how to customize it for your specific needs. See the following files in the form-app-template directory:

- CUSTOMIZATION.md - How to customize forms and styling
- INTEGRATION.md - How to integrate with the HSQ Forms API
- DOCS.md - Complete documentation index
