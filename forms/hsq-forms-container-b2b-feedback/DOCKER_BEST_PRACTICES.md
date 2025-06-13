# Docker Container Management Best Practices
## HSQ Forms - B2B Feedback Container

### 📋 Overview
This document establishes best practices for managing Docker containers in the HSQ Forms project, specifically for the B2B Feedback form container.

## 🏷️ Container Naming Convention

### Standard Container Name
```bash
hsq-forms-container-b2b-feedback
```

### Image Tagging Strategy
- **`production`** - Stable, tested version ready for production deployment
- **`latest`** - Most recent stable build (same as production)
- **`v[MAJOR].[MINOR].[PATCH]`** - Semantic versioning for specific releases
- **`dev-[feature]`** - Development builds for specific features

### Current Tags
```bash
hsq-forms-container-b2b-feedback:production  # Stable production version
hsq-forms-container-b2b-feedback:latest      # Latest stable build
hsq-forms-container-b2b-feedback:checkbox-v1.2  # Specific version
```

## 🔄 Container Lifecycle Management

### 1. Development Workflow
```bash
# Build development image
docker build -t hsq-forms-container-b2b-feedback:dev-[feature-name] .

# Test locally
docker run -d --name hsq-b2b-dev-test -p 3001:3000 hsq-forms-container-b2b-feedback:dev-[feature-name]

# Run tests
npm test

# Clean up after testing
docker stop hsq-b2b-dev-test
docker rm hsq-b2b-dev-test
docker rmi hsq-forms-container-b2b-feedback:dev-[feature-name]
```

### 2. Production Deployment
```bash
# Build production image with version tag
docker build -t hsq-forms-container-b2b-feedback:v1.2.0 .

# Tag as production ready
docker tag hsq-forms-container-b2b-feedback:v1.2.0 hsq-forms-container-b2b-feedback:production
docker tag hsq-forms-container-b2b-feedback:v1.2.0 hsq-forms-container-b2b-feedback:latest

# Deploy with health checks
docker run -d \
  --name hsq-forms-container-b2b-feedback \
  -p 3001:3000 \
  --health-cmd="curl -f http://localhost:3000 || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  --restart=unless-stopped \
  hsq-forms-container-b2b-feedback:production
```

### 3. Updates and Rollbacks
```bash
# Stop current container
docker stop hsq-forms-container-b2b-feedback

# Backup current version (optional)
docker tag hsq-forms-container-b2b-feedback:production hsq-forms-container-b2b-feedback:backup-$(date +%Y%m%d)

# Deploy new version
docker run -d \
  --name hsq-forms-container-b2b-feedback \
  -p 3001:3000 \
  --health-cmd="curl -f http://localhost:3000 || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  --restart=unless-stopped \
  hsq-forms-container-b2b-feedback:production

# Remove old container
docker rm hsq-forms-container-b2b-feedback-old
```

### 4. Rollback Strategy
```bash
# Stop problematic container
docker stop hsq-forms-container-b2b-feedback
docker rm hsq-forms-container-b2b-feedback

# Rollback to previous version
docker run -d \
  --name hsq-forms-container-b2b-feedback \
  -p 3001:3000 \
  --health-cmd="curl -f http://localhost:3000 || exit 1" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  --restart=unless-stopped \
  hsq-forms-container-b2b-feedback:backup-[DATE]
```

## 🧹 Regular Cleanup Tasks

### Weekly Cleanup Script
```bash
#!/bin/bash
# cleanup.sh - Weekly Docker cleanup

echo "🧹 Starting Docker cleanup..."

# Remove stopped containers
docker container prune -f

# Remove unused images (keep last 3 versions)
docker image prune -f

# Remove unused volumes
docker volume prune -f

# Remove unused networks
docker network prune -f

echo "✅ Cleanup complete!"
```

### Monthly Deep Clean
```bash
#!/bin/bash
# deep-clean.sh - Monthly deep cleanup

echo "🔍 Deep cleaning Docker resources..."

# Show current disk usage
docker system df

# Remove all unused resources (careful!)
docker system prune -a --volumes -f

# Rebuild production image to ensure it's fresh
docker build -t hsq-forms-container-b2b-feedback:production .

echo "✅ Deep clean complete!"
```

## 📊 Monitoring and Health Checks

### Health Check Configuration
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000 || exit 1
```

### Monitoring Commands
```bash
# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# View container logs
docker logs -f hsq-forms-container-b2b-feedback

# Check resource usage
docker stats hsq-forms-container-b2b-feedback

# Inspect container configuration
docker inspect hsq-forms-container-b2b-feedback
```

## 🔒 Security Best Practices

### 1. Image Security
- Always use specific version tags, avoid `latest` in production
- Regularly update base images
- Use multi-stage builds to minimize image size
- Run security scans on images

### 2. Runtime Security
```bash
# Run with limited privileges
docker run -d \
  --name hsq-forms-container-b2b-feedback \
  --user 1001:1001 \
  --read-only \
  --tmpfs /tmp \
  -p 3001:3000 \
  hsq-forms-container-b2b-feedback:production
```

### 3. Network Security
- Use custom networks instead of default bridge
- Limit port exposure
- Implement proper firewall rules

## 📝 Environment Management

### Development Environment
```bash
# .env.development
NODE_ENV=development
API_URL=http://localhost:8000
DEBUG=true
```

### Production Environment
```bash
# .env.production
NODE_ENV=production
API_URL=https://api.hsqforms.com
DEBUG=false
```

## 🚀 Deployment Automation

### Docker Compose for Full Stack
```yaml
version: '3.8'
services:
  b2b-feedback-form:
    image: hsq-forms-container-b2b-feedback:production
    container_name: hsq-forms-container-b2b-feedback
    ports:
      - "3001:3000"
    environment:
      - NODE_ENV=production
      - API_URL=http://forms-api:8000
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped
    depends_on:
      - forms-api
    networks:
      - hsq-network

  forms-api:
    image: hsq-forms-api:latest
    container_name: hsq-forms-api-api-1
    ports:
      - "8000:8000"
    networks:
      - hsq-network

networks:
  hsq-network:
    driver: bridge
```

## 📋 Quick Reference Commands

### Essential Commands
```bash
# Build and tag
docker build -t hsq-forms-container-b2b-feedback:production .

# Run with all best practices
docker run -d --name hsq-forms-container-b2b-feedback \
  -p 3001:3000 \
  --health-cmd="curl -f http://localhost:3000 || exit 1" \
  --health-interval=30s --health-timeout=10s --health-retries=3 \
  --restart=unless-stopped \
  hsq-forms-container-b2b-feedback:production

# Monitor
docker logs -f hsq-forms-container-b2b-feedback
docker stats hsq-forms-container-b2b-feedback

# Stop and cleanup
docker stop hsq-forms-container-b2b-feedback
docker rm hsq-forms-container-b2b-feedback

# Cleanup unused resources
docker system prune -f
```

## ✅ Current Status

### Active Container
- **Name**: `hsq-forms-container-b2b-feedback`
- **Image**: `hsq-forms-container-b2b-feedback:production`
- **Port**: `3001:3000`
- **Health**: Monitored with curl checks
- **Status**: ✅ Running and healthy

### Cleaned Up
- ✅ Removed old development containers
- ✅ Removed unused images
- ✅ Standardized naming convention
- ✅ Implemented proper tagging strategy

---
*Last updated: $(date)*
*Managed by: HSQ Forms Development Team*
