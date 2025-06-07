#!/bin/bash
# Test script for validating the restructured application

echo "=========================================="
echo "   HSQ Forms API - Validation Tests"
echo "=========================================="

# Check project structure
echo "🔍 Validating project structure..."

# Check if the new structure exists
if [ ! -d "src/forms_api" ]; then
    echo "❌ New structure not found: src/forms_api"
    exit 1
else
    echo "✅ Found new structure: src/forms_api"
fi

# Check essential files
for file in "src/forms_api/app.py" "src/forms_api/schemas.py" "src/forms_api/models.py" "src/forms_api/db.py" "main.py"
do
    if [ ! -f "$file" ]; then
        echo "❌ Essential file missing: $file"
        exit 1
    else
        echo "✅ Found essential file: $file"
    fi
done

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Start the application with Docker Compose
echo "📦 Starting application with Docker Compose..."
docker-compose down -v --remove-orphans
docker-compose up -d --build

# Wait for the application to start
echo "⏳ Waiting for application to start..."
sleep 10

# Check if the application is running
echo "🔍 Testing API health..."
HEALTH_CHECK=$(curl -s http://localhost:8001/)
if [[ $HEALTH_CHECK == *"HSQ Forms API is running"* ]]; then
    echo "✅ API is running correctly"
else
    echo "❌ API health check failed"
    echo "$HEALTH_CHECK"
    docker-compose logs
    docker-compose down
    exit 1
fi

# Test the API endpoints
echo "🔍 Testing API endpoints..."

# Test legacy form submission endpoint
echo "- Testing legacy form submission..."
LEGACY_ENDPOINT=$(curl -s -o /dev/null -w "%{http_code}" -X GET http://localhost:8001/submit)
if [ "$LEGACY_ENDPOINT" == "405" ] || [ "$LEGACY_ENDPOINT" == "200" ]; then
    echo "✅ Legacy endpoint is responding"
else
    echo "❌ Legacy endpoint is not responding correctly: $LEGACY_ENDPOINT"
    docker-compose logs
    docker-compose down
    exit 1
fi

# Test forms API endpoint
echo "- Testing forms API..."
FORMS_ENDPOINT=$(curl -s -o /dev/null -w "%{http_code}" -X GET http://localhost:8001/api/forms)
if [ "$FORMS_ENDPOINT" == "404" ] || [ "$FORMS_ENDPOINT" == "405" ] || [ "$FORMS_ENDPOINT" == "200" ]; then
    echo "✅ Forms API endpoint is responding"
else
    echo "❌ Forms API endpoint is not responding correctly: $FORMS_ENDPOINT"
    docker-compose logs
    docker-compose down
    exit 1
fi

# Run the test script
echo "🧪 Running test script..."
python tests/test_api.py

# Check the exit code
if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    docker-compose logs
    docker-compose down
    exit 1
else
    echo "✅ Tests passed successfully"
fi

# Run pytest tests
echo "🧪 Running pytest tests..."
pytest -xvs tests/test_pytest_api.py

# Check the exit code
if [ $? -ne 0 ]; then
    echo "❌ Pytest tests failed"
    docker-compose logs
    docker-compose down
    exit 1
else
    echo "✅ Pytest tests passed successfully"
fi

# Shut down the application
echo "🛑 Shutting down application..."
docker-compose down

echo "=========================================="
echo "🎉 All validation tests passed!"
echo "The restructured application is working correctly."
echo "=========================================="
echo ""
echo "You can now safely run ./scripts/cleanup_old_structure.sh to remove the old code structure."
