#!/bin/bash

# Container Registry Deployment Script
# Handles pushing images to container registry and deploying from registry

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables
load_env() {
    local env_file=${1:-.env.production}
    if [ -f "$PROJECT_ROOT/$env_file" ]; then
        source "$PROJECT_ROOT/$env_file"
    fi
}

# Login to container registry
registry_login() {
    if [ -n "$REGISTRY_URL" ] && [ -n "$REGISTRY_USERNAME" ] && [ -n "$REGISTRY_PASSWORD" ]; then
        log "Logging into container registry: $REGISTRY_URL"
        echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY_URL" -u "$REGISTRY_USERNAME" --password-stdin
        success "Logged into registry successfully"
    else
        error "Registry credentials not configured"
        exit 1
    fi
}

# Build and tag image for registry
build_and_tag() {
    local version=${1:-latest}
    local image_name="hsq-forms-api"
    local registry_image="$REGISTRY_URL/$image_name:$version"
    
    log "Building image for registry: $registry_image"
    
    cd "$PROJECT_ROOT"
    
    # Build production image
    docker build -f Dockerfile.prod -t "$image_name:$version" .
    
    # Tag for registry
    docker tag "$image_name:$version" "$registry_image"
    
    # Also tag as latest if not already latest
    if [ "$version" != "latest" ]; then
        docker tag "$image_name:$version" "$REGISTRY_URL/$image_name:latest"
    fi
    
    success "Image built and tagged successfully"
    echo "Local image: $image_name:$version"
    echo "Registry image: $registry_image"
}

# Push image to registry
push_image() {
    local version=${1:-latest}
    local image_name="hsq-forms-api"
    local registry_image="$REGISTRY_URL/$image_name:$version"
    
    log "Pushing image to registry: $registry_image"
    
    docker push "$registry_image"
    
    # Push latest tag if version is not latest
    if [ "$version" != "latest" ]; then
        log "Pushing latest tag"
        docker push "$REGISTRY_URL/$image_name:latest"
    fi
    
    success "Image pushed successfully"
}

# Pull image from registry
pull_image() {
    local version=${1:-latest}
    local image_name="hsq-forms-api"
    local registry_image="$REGISTRY_URL/$image_name:$version"
    
    log "Pulling image from registry: $registry_image"
    
    docker pull "$registry_image"
    
    # Tag as local image
    docker tag "$registry_image" "$image_name:$version"
    
    success "Image pulled successfully"
}

# Deploy from registry
deploy_from_registry() {
    local version=${1:-latest}
    
    log "Deploying from registry version: $version"
    
    # Set environment variables for deployment
    export VERSION="$version"
    export IMAGE_SOURCE="registry"
    
    # Pull latest image
    pull_image "$version"
    
    # Use the production deployment script
    "$SCRIPT_DIR/deploy-production.sh" deploy "$version"
}

# Create deployment manifest for Kubernetes (optional)
create_k8s_manifest() {
    local version=${1:-latest}
    local manifest_file="$PROJECT_ROOT/k8s-deployment.yaml"
    
    log "Creating Kubernetes deployment manifest"
    
    cat > "$manifest_file" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hsq-forms-api
  labels:
    app: hsq-forms-api
    version: $version
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hsq-forms-api
  template:
    metadata:
      labels:
        app: hsq-forms-api
        version: $version
    spec:
      containers:
      - name: api
        image: $REGISTRY_URL/hsq-forms-api:$version
        ports:
        - containerPort: 8000
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: hsq-forms-secrets
              key: database-url
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: hsq-forms-secrets
              key: secret-key
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: hsq-forms-api-service
spec:
  selector:
    app: hsq-forms-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: LoadBalancer
EOF
    
    success "Kubernetes manifest created: $manifest_file"
}

# Show registry images
list_registry_images() {
    log "Available images in registry:"
    
    # This would need registry-specific commands
    # For Azure Container Registry:
    if command -v az &> /dev/null; then
        local registry_name=$(echo "$REGISTRY_URL" | cut -d'.' -f1)
        az acr repository list --name "$registry_name" --output table 2>/dev/null || echo "Azure CLI not available or not logged in"
        az acr repository show-tags --name "$registry_name" --repository hsq-forms-api --output table 2>/dev/null || echo "Repository not found"
    else
        echo "Registry listing requires specific CLI tools (e.g., 'az' for Azure)"
    fi
}

# Main function
main() {
    local command=${1:-help}
    local version=${2:-latest}
    
    cd "$PROJECT_ROOT"
    load_env
    
    case "$command" in
        "build")
            registry_login
            build_and_tag "$version"
            ;;
        "push")
            registry_login
            build_and_tag "$version"
            push_image "$version"
            ;;
        "pull")
            registry_login
            pull_image "$version"
            ;;
        "deploy")
            registry_login
            deploy_from_registry "$version"
            ;;
        "list")
            registry_login
            list_registry_images
            ;;
        "k8s")
            create_k8s_manifest "$version"
            ;;
        "full-deploy")
            log "Full deployment pipeline: build -> push -> deploy"
            registry_login
            build_and_tag "$version"
            push_image "$version"
            deploy_from_registry "$version"
            ;;
        *)
            echo "Container Registry Deployment Tool"
            echo
            echo "Usage: $0 {build|push|pull|deploy|list|k8s|full-deploy} [version]"
            echo
            echo "Commands:"
            echo "  build [version]      - Build and tag image for registry"
            echo "  push [version]       - Build and push image to registry"
            echo "  pull [version]       - Pull image from registry"
            echo "  deploy [version]     - Deploy from registry"
            echo "  list                 - List available images in registry"
            echo "  k8s [version]        - Create Kubernetes deployment manifest"
            echo "  full-deploy [version] - Complete build->push->deploy pipeline"
            echo
            echo "Examples:"
            echo "  $0 push v1.2.3       - Build and push version 1.2.3"
            echo "  $0 deploy v1.2.3     - Deploy version 1.2.3 from registry"
            echo "  $0 full-deploy v1.2.3 - Complete deployment pipeline"
            echo
            echo "Required environment variables:"
            echo "  REGISTRY_URL, REGISTRY_USERNAME, REGISTRY_PASSWORD"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
