.PHONY: help test lint build run clean install dev

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install production dependencies
	pip install -r requirements.txt

dev: ## Install development dependencies
	pip install -r requirements.txt
	pip install -r requirements-test.txt
	pip install flake8 pylint black

test: ## Run unit tests with coverage
	pytest tests/ -v --cov=app --cov-report=term --cov-report=html

test-fast: ## Run tests without coverage
	pytest tests/ -v

lint: ## Run linters
	@echo "Running flake8..."
	flake8 app/ tests/ --max-line-length=100 --exclude=__pycache__,.venv
	@echo "Running pylint..."
	pylint app/ --disable=C0111,R0903 --max-line-length=100 --fail-under=8.0

format: ## Format code with black
	black app/ tests/ --line-length=100

build: ## Build Docker image
	docker build -t demo-flask-app:latest .

run: ## Run the application locally
	python -m flask --app app.main run --host=0.0.0.0 --port=5000

run-docker: ## Run the application in Docker
	docker run -p 5000:5000 -e APP_VERSION=dev demo-flask-app:latest

clean: ## Clean up generated files
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache .coverage htmlcov coverage.xml

docker-clean: ## Remove Docker images
	docker rmi demo-flask-app:latest || true

all: clean install lint test build ## Run all checks and build
