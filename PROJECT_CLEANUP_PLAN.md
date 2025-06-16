# 🧹 HSQ Forms API - Comprehensive Project Cleanup Plan

**Date:** June 15, 2025  
**Objective:** Clean up entire project before deployment

## 📋 Cleanup Categories

### 🗑️ Files to Remove

#### 1. Root Level Development/Test Files
- `api-debug-test.html` - Debug testing page
- `test-direct-api.html` - Direct API testing 
- `test-frontend-logic.html` - Frontend logic testing
- `debug-esb.sh` - ESB debugging script
- `e2e-test.sh` - End-to-end testing script
- `manual-test.sh` - Manual testing script
- `quick-test-commands.sh` - Quick test commands
- `test-caseorigin-update.sh` - Case origin testing
- `test-esb-integration.sh` - ESB integration testing
- `test-full-container-solution.sh` - Full container testing
- `test-husqvarna-api.sh` - Husqvarna API testing

#### 2. Development Status Documentation
- `B2B_SUPPORT_FORM_TEST_PLAN.md` - Test plan (keep in docs/)
- `B2B_SUPPORT_IMPLEMENTATION_SUMMARY.md` - Implementation summary
- `COMMIT_MESSAGE.md` - Temporary commit message
- `CONTAINER_SOLUTION_COMPLETE.md` - Development completion
- `CUSTOMER_VALIDATION_FIXED.md` - Fix documentation
- `DOCKER_SETUP_COMPLETE.md` - Setup completion
- `ESB_CASEORIGIN_UPDATE_COMPLETE.md` - ESB update completion
- `ESB_UPDATE_SUMMARY.md` - ESB update summary
- `GITHUB_PUSH_COMPLETE.md` - GitHub push completion
- `MISSION_ACCOMPLISHED.md` - Mission completion
- `OFFLINE_VALIDATION_DEBUG.md` - Debug documentation
- `OFFLINE_VALIDATION_SOLUTION.md` - Solution documentation
- `PROJECT_CLEANUP_COMPLETE.md` - Previous cleanup documentation
- `TESTING_STATUS_UPDATE.md` - Testing status
- `TEXT_UPDATE_COMPLETE.md` - Text update completion

#### 3. Container Development Files (per container)

**B2B Feedback:**
- Keep: Production-ready (already cleaned)

**B2B Returns:**
- `test-functional.js` - Functional testing
- `test-browser-automation.js` - Browser automation
- `dev-helper.sh` - Development helper
- `FUNCTIONAL_TESTING_REPORT.md` - Testing report
- `TESTING_REPORT.md` - Testing report
- `RESTORATION_COMPLETE.md` - Restoration documentation
- `DEVELOPMENT_GUIDE.md` - Development guide
- `QUICK_REFERENCE.md` - Quick reference
- `DEPLOYMENT.md` - Empty deployment file
- `scripts/` directory - Development scripts

**B2B Support:**
- `test-api-integration.js` - API integration testing
- `test-ui.js` - UI testing
- `test-form-integration.js` - Form integration testing
- `test-browser-automation.js` - Browser automation
- `test-functional.js` - Functional testing
- `dev-helper.sh` - Development helper
- `quick-start.sh` - Quick start script
- `container.sh` - Container script
- `IMPLEMENTATION_COMPLETE.md` - Implementation documentation
- `INTEGRATION_COMPLETE.md` - Integration documentation
- `SETUP_COMPLETE.md` - Setup documentation
- `HUSQVARNA_API_INTEGRATION.md` - API integration docs
- `DEVELOPMENT_GUIDE.md` - Development guide
- `CUSTOMER_CODE_ROUTING.md` - Customer code documentation
- `DOCKER_DESKTOP_GUIDE.md` - Docker guide
- `RESTORATION_COMPLETE.md` - Restoration documentation
- `QUICK_REFERENCE.md` - Quick reference
- `CONTAINER_README.md` - Container documentation
- `DEPLOYMENT_COMPLETE.md` - Deployment documentation
- `scripts/` directory - Development scripts

**B2C Returns:**
- Already cleaned ✅

### 🏗️ Cleanup Tasks

#### 1. Remove Development/Test Files
- Delete all test scripts and HTML files
- Remove development documentation
- Clean up temporary status files

#### 2. Container Cleanup
- Apply B2C cleanup approach to other containers
- Keep only production-necessary files
- Remove all test/development scripts

#### 3. Python Cache Cleanup
- Remove all `__pycache__/` directories
- Remove `.pyc`, `.pyo`, `.pyd` files
- Clean pytest cache

#### 4. Build Artifacts Cleanup
- Remove `node_modules/` from all containers
- Remove `dist/` directories
- Clean Docker build cache

### ✅ Files to Keep

#### Essential Configuration
- `package.json`, `Dockerfile`, `docker-compose.yml`
- `.env` files and configuration
- `tsconfig.json`, `vite.config.ts`, `tailwind.config.js`

#### Production Documentation
- `README.md` (updated for production)
- `docs/` directory (official documentation)
- Integration guides for Sitecore

#### Core Application Files
- `src/` directories with React applications
- `main.py` and API source code
- Database migrations and schema

#### Infrastructure
- `infra/` directory with Bicep templates
- `azure.yaml` for deployment
- `Makefile` for build automation

## 🎯 Expected Results

### Space Savings
- **Before**: ~50GB with all development files, caches, and artifacts
- **After**: ~5GB with only production-essential files
- **Reduction**: ~90% space savings

### Organization Benefits
- Clean project structure
- Faster builds and deployments
- Clear separation of production vs development
- Reduced confusion for new developers

### Deployment Readiness
- Only production-necessary files
- Optimized Docker images
- Clear documentation focus
- Ready for Azure deployment

## 🚀 Next Steps

1. Execute cleanup plan systematically
2. Update remaining documentation for production focus
3. Test containers after cleanup
4. Create final deployment documentation
5. Verify Azure deployment readiness
