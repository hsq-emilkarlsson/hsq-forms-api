#!/bin/bash

# HSQ Forms API - Container Deployment Script
# This script handles building, updating, and deploying the API container

set -e  # Exit on any error

echo "🚀 HSQ Forms API Container Deployment"
echo "======================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Function to build and deploy locally
deploy_local() {
    echo "📦 Building new image..."
    docker-compose build --no-cache api
    
    echo "🔄 Stopping current containers..."
    docker-compose down
    
    echo "🚀 Starting with new image..."
    docker-compose up -d
    
    echo "⏳ Waiting for services to be ready..."
    sleep 10
    
    echo "🔍 Checking health..."
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        echo "✅ API is healthy and running!"
        echo "📖 Swagger docs: http://localhost:8000/docs"
        echo "❤️  Health check: http://localhost:8000/health"
    else
        echo "❌ API health check failed"
        docker-compose logs api
        exit 1
    fi
}

# Function to tag and push to registry (for production)
deploy_registry() {
    local registry_url="$1"
    local version="$2"
    
    if [ -z "$registry_url" ] || [ -z "$version" ]; then
        echo "❌ Usage: ./deploy-container.sh registry <registry-url> <version>"
        echo "   Example: ./deploy-container.sh registry myregistry.azurecr.io v1.0.0"
        exit 1
    fi
    
    echo "🏷️  Tagging image for registry..."
    docker tag hsq-forms-api-api:latest $registry_url/hsq-forms-api:$version
    docker tag hsq-forms-api-api:latest $registry_url/hsq-forms-api:latest
    
    echo "📤 Pushing to registry..."
    docker push $registry_url/hsq-forms-api:$version
    docker push $registry_url/hsq-forms-api:latest
    
    echo "✅ Image pushed to registry!"
    echo "🚀 Use this in production:"
    echo "   docker run -p 8000:8000 --env-file .env $registry_url/hsq-forms-api:$version"
}

# Function to deploy from registry
deploy_from_registry() {
    local registry_url="$1"
    local version="${2:-latest}"
    
    if [ -z "$registry_url" ]; then
        echo "❌ Usage: ./deploy-container.sh pull <registry-url> [version]"
        echo "   Example: ./deploy-container.sh pull myregistry.azurecr.io v1.0.0"
        exit 1
    fi
    
    echo "📥 Pulling from registry..."
    docker pull $registry_url/hsq-forms-api:$version
    
    echo "🏷️  Tagging as local image..."
    docker tag $registry_url/hsq-forms-api:$version hsq-forms-api-api:latest
    
    echo "🔄 Restarting with new image..."
    docker-compose down
    docker-compose up -d
    
    echo "✅ Deployed from registry!"
}

# Function to show container status
show_status() {
    echo "📊 Container Status:"
    echo "==================="
    docker-compose ps
    echo ""
    
    echo "🔍 Recent logs:"
    echo "==============="
    docker-compose logs --tail=20 api
    echo ""
    
    echo "💾 Database status:"
    echo "=================="
    docker-compose exec postgres psql -U hsqforms -d hsq_forms -c "SELECT COUNT(*) as template_count FROM form_templates;"
    docker-compose exec postgres psql -U hsqforms -d hsq_forms -c "SELECT COUNT(*) as submission_count FROM form_submissions;"
}

# Main script logic
case "${1:-local}" in
    "local")
        deploy_local
        ;;
    "registry")
        deploy_registry "$2" "$3"
        ;;
    "pull")
        deploy_from_registry "$2" "$3"
        ;;
    "status")
        show_status
        ;;
    "help"|"-h"|"--help")
        echo "HSQ Forms API Deployment Script"
        echo ""
        echo "Usage:"
        echo "  ./deploy-container.sh [command] [options]"
        echo ""
        echo "Commands:"
        echo "  local                           - Build and deploy locally (default)"
        echo "  registry <url> <version>        - Tag and push to container registry"
        echo "  pull <url> [version]           - Pull and deploy from registry"
        echo "  status                         - Show container and database status"
        echo "  help                           - Show this help message"
        echo ""
        echo "Examples:"
        echo "  ./deploy-container.sh                                    # Local deployment"
        echo "  ./deploy-container.sh registry myregistry.azurecr.io v1.0.0  # Push to registry"
        echo "  ./deploy-container.sh pull myregistry.azurecr.io v1.0.0      # Deploy from registry"
        echo "  ./deploy-container.sh status                             # Check status"
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Use './deploy-container.sh help' for usage information."
        exit 1
        ;;
esac
