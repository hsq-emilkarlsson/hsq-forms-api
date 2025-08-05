# HSQ Forms API - Production Dockerfile
# Multi-stage build for optimal image size and security

# Build stage
FROM python:3.11-slim as builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Build arguments
ARG ENVIRONMENT=production

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Add development dependencies if in dev environment
RUN if [ "$ENVIRONMENT" = "development" ] ; then \
        pip install pytest pytest-cov flake8 black ; \
    fi

# Production stage
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Build arguments
ARG ENVIRONMENT=production
ENV APP_ENVIRONMENT=${ENVIRONMENT}

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Create app user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy application code
COPY src/ src/
COPY alembic/ alembic/
COPY alembic.ini .
COPY main.py .

# Set Python path
ENV PYTHONPATH=/app

# Create necessary directories and set permissions
RUN mkdir -p logs tmp && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=5)" || exit 1

# Expose port
EXPOSE 8000

# Default command
CMD ["uvicorn", "src.forms_api.app:app", "--host", "0.0.0.0", "--port", "8000"]
