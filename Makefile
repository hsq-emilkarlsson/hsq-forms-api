.PHONY: setup setup-dev test test-cov format lint typecheck clean clean-all run-dev start-dev build-docker docker-compose docs migrate migrate-down migrate-create

# Development setup
setup:
	pip install -r requirements.txt

setup-dev: setup
	pip install -r requirements-dev.txt
	@echo "Creating necessary directories..."
	mkdir -p uploads/temp
	mkdir -p logs

# Testing
test:
	./scripts/run-tests.sh

test-cov:
	pytest --cov=src/forms_api --cov-report=html --cov-report=term

test-cov-xml:
	pytest --cov=src/forms_api --cov-report=xml

# Code quality
format:
	black src tests
	isort src tests

lint:
	flake8 src tests

typecheck:
	mypy src tests

check: format lint typecheck
	@echo "All code quality checks passed!"

# Running the application
start-dev:
	./scripts/start-dev.sh

run-dev:
	uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

# Cleaning
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.pyd" -delete
	find . -type f -name ".coverage" -delete
	find . -type d -name "htmlcov" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".coverage" -exec rm -rf {} +

clean-all: clean
	rm -rf .pytest_cache
	rm -rf .coverage
	rm -rf htmlcov
	rm -rf build
	rm -rf dist
	rm -rf logs/*.log
	@echo "Warning: This will remove all temporary uploads. Press Ctrl+C to cancel, or Enter to continue"
	@read _
	rm -rf uploads/temp/*

# Docker commands
build-docker:
	docker build -t hsq-forms-api .

docker-compose-up:
	docker-compose up

docker-compose-down:
	docker-compose down

# Database migrations
migrate:
	alembic upgrade head

migrate-down:
	alembic downgrade -1

migrate-create:
	@read -p "Enter migration name: " migration_name; \
	alembic revision --autogenerate -m "$$migration_name"

# Documentation
docs:
	@echo "Generating API documentation..."
	pdoc --html --output-dir docs/api src/forms_api

# Help
help:
	@echo "HSQ Forms API - Available commands:"
	@echo "make setup         - Install production dependencies"
	@echo "make setup-dev     - Install development dependencies"
	@echo "make test          - Run tests"
	@echo "make test-cov      - Run tests with coverage report"
	@echo "make format        - Format code with black and isort"
	@echo "make lint          - Run linting with flake8"
	@echo "make typecheck     - Run type checking with mypy"
	@echo "make check         - Run all code quality checks"
	@echo "make clean         - Clean temporary Python files"
	@echo "make clean-all     - Clean all generated files"
	@echo "make start-dev     - Start development server using script"
	@echo "make run-dev       - Start development server directly with uvicorn"
	@echo "make build-docker  - Build Docker image"
	@echo "make docker-compose-up   - Start with Docker Compose"
	@echo "make docker-compose-down - Stop Docker Compose services"
	@echo "make migrate       - Run database migrations"
	@echo "make migrate-down  - Revert last database migration"
	@echo "make migrate-create - Create new migration"
	@echo "make test       - Run tests"
	@echo "make test-cov   - Run tests with coverage"
	@echo "make format     - Format code with black and isort"
	@echo "make lint       - Run linting checks"
	@echo "make clean      - Remove Python artifacts"
	@echo "make run-dev    - Start development server with Docker Compose"
	@echo "make run-tests  - Run API tests"
