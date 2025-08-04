#!/bin/bash

# Environment-based Deployment Script
# This script handles building and deploying to different environments

set -e  # Exit on any error

# Default values
ENVIRONMENT="dev"
VERSION="latest"
PUSH_TO_REGISTRY=false

# Show usage information
show_usage() {
  echo "HSQ Forms API Deployment Script"
  echo ""
  echo "Usage:"
  echo "  ./deploy.sh [options]"
  echo ""
  echo "Options:"
  echo "  -e, --env <environment>     Target environment: dev or prod (default: dev)"
  echo "  -v, --version <version>     Version tag for image (default: latest)"
  echo "  -p, --push                  Push to container registry"
  echo "  -h, --help                  Show this help message"
  echo ""
  echo "Examples:"
  echo "  ./deploy.sh                            # Local dev deployment"
  echo "  ./deploy.sh -e prod                    # Local prod deployment"
  echo "  ./deploy.sh -e dev -p -v 1.0.0         # Push dev image with tag 1.0.0"
  echo "  ./deploy.sh -e prod -p -v 1.0.0        # Push prod image with tag 1.0.0"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -e|--env)
      ENVIRONMENT="$2"
      shift
      shift
      ;;
    -v|--version)
      VERSION="$2"
      shift
      shift
      ;;
    -p|--push)
      PUSH_TO_REGISTRY=true
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
done

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "Error: Environment must be either 'dev' or 'prod'"
  exit 1
fi

# Set variables based on environment
if [[ "$ENVIRONMENT" == "dev" ]]; then
  COMPOSE_FILE="docker-compose.dev.yml"
  REGISTRY="hsqformsdevacr.azurecr.io"
  IMAGE_NAME="hsq-forms-api-dev"
else
  COMPOSE_FILE="docker-compose.prod.yml"
  REGISTRY="hsqformsprodacr.azurecr.io"
  IMAGE_NAME="hsq-forms-api"
fi

echo "🚀 HSQ Forms API Deployment"
echo "============================="
echo "Environment: $ENVIRONMENT"
echo "Version:     $VERSION"
echo "Registry:    $REGISTRY"
echo "Image:       $IMAGE_NAME"
echo "============================="

# Build and start containers
echo "📦 Building images..."
VERSION=$VERSION docker-compose -f $COMPOSE_FILE build

if [[ "$PUSH_TO_REGISTRY" == true ]]; then
  echo "🔐 Logging in to Azure Container Registry..."
  az acr login --name $(echo $REGISTRY | cut -d '.' -f 1)
  
  echo "📤 Pushing image to registry..."
  docker push $REGISTRY/$IMAGE_NAME:$VERSION
  
  echo "✅ Image pushed successfully to $REGISTRY/$IMAGE_NAME:$VERSION"
else
  echo "🚀 Starting local containers..."
  VERSION=$VERSION docker-compose -f $COMPOSE_FILE up -d
  
  echo "⏳ Waiting for services to be ready..."
  sleep 5
  
  echo "📊 Container status:"
  docker-compose -f $COMPOSE_FILE ps
  
  if [[ "$ENVIRONMENT" == "dev" ]]; then
    echo "📖 API documentation: http://localhost:8000/docs"
  fi
  
  echo "✅ Deployment completed successfully!"
fi
