FROM python:3.11-slim

# Build arguments
ARG ENVIRONMENT=development

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Add development dependencies if in dev environment
RUN if [ "$ENVIRONMENT" = "development" ] ; then \
        pip install pytest pytest-cov flake8 black ; \
    fi

COPY . .

# Make sure the right directory is in the Python path
ENV PYTHONPATH=/app

# Set environment variable for app configuration
ENV APP_ENVIRONMENT=${ENVIRONMENT}

# Expose the port the app runs on
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "src.forms_api.app:app", "--host", "0.0.0.0", "--port", "8000"]
