#!/bin/bash

# Production Deployment Script
# This script handles production deployments with blue-green strategy

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env.production"

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

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if environment file exists
check_env_file() {
    if [ ! -f "$PROJECT_ROOT/$ENV_FILE" ]; then
        error "Environment file $ENV_FILE not found!"
        warning "Copy .env.production.template to .env.production and configure it"
        exit 1
    fi
}

# Load environment variables
load_env() {
    log "Loading environment variables from $ENV_FILE"
    source "$PROJECT_ROOT/$ENV_FILE"
}

# Check if required environment variables are set
check_required_vars() {
    local required_vars=("SECRET_KEY" "DB_PASSWORD")
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            error "Required environment variable $var is not set!"
            exit 1
        fi
    done
}

# Build new image
build_image() {
    local version=${1:-latest}
    log "Building production image with version: $version"
    
    cd "$PROJECT_ROOT"
    docker build -f Dockerfile.prod -t "hsq-forms-api:$version" .
    
    if [ $? -eq 0 ]; then
        success "Image built successfully"
    else
        error "Failed to build image"
        exit 1
    fi
}

# Create backup of current deployment
backup_current() {
    if [ "$BACKUP_BEFORE_DEPLOY" = "true" ]; then
        log "Creating backup of current deployment"
        local backup_dir="$PROJECT_ROOT/backups/deployment-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        
        # Export current containers
        docker save hsq-forms-api:latest | gzip > "$backup_dir/hsq-forms-api-backup.tar.gz" 2>/dev/null || true
        
        # Save current environment
        cp "$PROJECT_ROOT/$ENV_FILE" "$backup_dir/" 2>/dev/null || true
        
        success "Backup created at $backup_dir"
    fi
}

# Deploy with blue-green strategy
deploy_blue_green() {
    local version=${1:-latest}
    log "Starting blue-green deployment for version: $version"
    
    # Set version in environment
    export VERSION="$version"
    
    # Stop current containers gracefully
    log "Stopping current containers"
    docker-compose -f "$COMPOSE_FILE" down --timeout 30
    
    # Start new containers
    log "Starting new containers with version $version"
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for health check
    wait_for_health
    
    # Clean up old images (keep last 3 versions)
    cleanup_old_images
    
    success "Deployment completed successfully!"
}

# Wait for application to be healthy
wait_for_health() {
    local max_attempts=${HEALTH_CHECK_TIMEOUT:-60}
    local attempt=0
    local health_url="http://localhost:${API_PORT:-8000}/health"
    
    log "Waiting for application to be healthy..."
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -f -s "$health_url" > /dev/null 2>&1; then
            success "Application is healthy!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 1
    done
    
    error "Application failed to become healthy within $max_attempts seconds"
    
    # Show container logs for debugging
    log "Container logs:"
    docker-compose -f "$COMPOSE_FILE" logs --tail=50 api
    
    exit 1
}

# Clean up old Docker images
cleanup_old_images() {
    log "Cleaning up old images (keeping last 3 versions)"
    
    # Remove dangling images
    docker image prune -f > /dev/null 2>&1 || true
    
    # Keep only last 3 versions of our app
    local images_to_remove=$(docker images hsq-forms-api --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | tail -n +2 | sort -k2 -r | tail -n +4 | awk '{print $1}')
    
    if [ -n "$images_to_remove" ]; then
        echo "$images_to_remove" | xargs -r docker rmi || true
        success "Old images cleaned up"
    fi
}

# Show deployment status
show_status() {
    log "Deployment Status:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo
    log "Application Health:"
    curl -s "http://localhost:${API_PORT:-8000}/health" | jq . 2>/dev/null || echo "Health check failed"
    
    echo
    log "Recent logs:"
    docker-compose -f "$COMPOSE_FILE" logs --tail=10 api
}

# Rollback to previous version
rollback() {
    local backup_dir="$1"
    
    if [ -z "$backup_dir" ]; then
        error "Backup directory not specified for rollback"
        exit 1
    fi
    
    if [ ! -d "$backup_dir" ]; then
        error "Backup directory $backup_dir not found"
        exit 1
    fi
    
    log "Rolling back to backup: $backup_dir"
    
    # Stop current containers
    docker-compose -f "$COMPOSE_FILE" down --timeout 30
    
    # Restore backup image
    if [ -f "$backup_dir/hsq-forms-api-backup.tar.gz" ]; then
        log "Restoring backup image"
        gunzip -c "$backup_dir/hsq-forms-api-backup.tar.gz" | docker load
    fi
    
    # Restore environment
    if [ -f "$backup_dir/$ENV_FILE" ]; then
        log "Restoring environment configuration"
        cp "$backup_dir/$ENV_FILE" "$PROJECT_ROOT/"
    fi
    
    # Start containers
    docker-compose -f "$COMPOSE_FILE" up -d
    
    wait_for_health
    
    success "Rollback completed successfully!"
}

# Main deployment function
main() {
    local command=${1:-deploy}
    local version=${2:-latest}
    
    cd "$PROJECT_ROOT"
    
    case "$command" in
        "deploy")
            log "Starting production deployment"
            check_env_file
            load_env
            check_required_vars
            build_image "$version"
            backup_current
            deploy_blue_green "$version"
            show_status
            ;;
        "status")
            show_status
            ;;
        "rollback")
            rollback "$version"
            ;;
        "build")
            build_image "$version"
            ;;
        *)
            echo "Usage: $0 {deploy|status|rollback|build} [version]"
            echo
            echo "Commands:"
            echo "  deploy [version]     - Deploy application (default: latest)"
            echo "  status              - Show deployment status"
            echo "  rollback <backup>   - Rollback to specific backup directory"
            echo "  build [version]     - Build image only (default: latest)"
            echo
            echo "Examples:"
            echo "  $0 deploy v1.2.3"
            echo "  $0 rollback /path/to/backup"
            echo "  $0 status"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
