# B2B Feedback Form - Production Deployment Guide

## 🚀 Quick Deploy

To deploy the B2B feedback form with checkbox functionality:

### Option 1: Using Docker Run
```bash
docker run -d \
  --name b2b-feedback-form \
  -p 3000:3000 \
  hsq-forms-container-b2b-feedback:checkbox-v1.2
```

### Option 2: Using Docker Compose
```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  b2b-feedback-form:
    image: hsq-forms-container-b2b-feedback:checkbox-v1.2
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - VITE_API_URL=${API_URL}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3
```

Deploy with:
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## 📋 Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `VITE_API_URL` | HSQ Forms API endpoint | `http://localhost:8000/api` | Yes |
| `NODE_ENV` | Environment mode | `development` | No |

## 🔧 Configuration

### API Integration
The form is configured to work with HSQ Forms API template ID: `e398f880-0e1c-4e2f-bd56-f0e38652a99f`

### Business Divisions
- `husqvarna` - Husqvarna products
- `construction` - Construction equipment  
- `gardena` - Garden tools and irrigation

### File Uploads
Supported file types: PDF, DOC, DOCX, JPG, PNG, GIF

## 🧪 Health Check

Verify deployment:
```bash
curl -f http://localhost:3000/
```

Expected: HTTP 200 response with form HTML

## 🌐 Browser Access

After deployment, access the form at:
- **URL**: http://your-domain:3000
- **Features**: Checkbox selection, file upload, multilingual support
- **Languages**: English (default), Swedish

## 📊 Monitoring

The container includes health checks and can be monitored using:
- Docker health status: `docker ps`
- Application logs: `docker logs b2b-feedback-form`
- Form submissions: Check HSQ Forms API logs

## 🔒 Security Notes

- Form validates all inputs client-side and server-side
- File uploads are validated for type and size
- CORS configured for API communication
- No sensitive data stored in container

## 📞 Support

For issues or questions:
1. Check container logs: `docker logs b2b-feedback-form`
2. Verify API connectivity to HSQ Forms API
3. Review form validation in browser developer tools

---

**Container Version**: checkbox-v1.2  
**Last Updated**: June 8, 2025  
**Status**: Production Ready ✅
