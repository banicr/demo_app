.PHONY: help test lint build run clean install dev deploy port-forward k8s-status k8s-logs argocd-ui argocd-password k8s-cleanup

CLUSTER_NAME ?= gitops-demo

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z/_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

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

clean: ## Clean up generated files and delete Kind cluster
	@echo "🧹 Cleaning Python artifacts..."
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache .coverage htmlcov coverage.xml
	@echo "🗑️  Deleting Kind cluster: $(CLUSTER_NAME)"
	@kind delete cluster --name $(CLUSTER_NAME) 2>/dev/null || echo "No cluster found"
	@echo "✅ Cleanup complete"

docker-clean: ## Remove Docker images
	docker rmi demo-flask-app:latest || true

all: clean install lint test build ## Run all checks and build

# ============================================================================
# Kubernetes / GitOps Commands
# ============================================================================

run/deploy: ## Deploy app to local Kind cluster with ArgoCD
	@echo "🚀 Setting up local GitOps environment..."
	@bash scripts/setup-local-cluster.sh $(CLUSTER_NAME)

port-forward: ## Port-forward to access the app locally (http://localhost:8080)
	@echo "🔌 Port-forwarding to demo-flask-app service..."
	@echo "Access app at: http://localhost:8080"
	kubectl port-forward -n demo-app svc/demo-flask-app 8080:80

argocd-ui: ## Port-forward to ArgoCD UI (https://localhost:8081)
	@echo "🔌 Port-forwarding to ArgoCD server..."
	@echo "Access ArgoCD at: https://localhost:8081"
	@echo "Username: admin"
	@echo "Password: Run 'make argocd-password' to get password"
	kubectl port-forward -n argocd svc/argocd-server 8081:443

argocd-password: ## Get ArgoCD admin password
	@echo "ArgoCD admin password:"
	@kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
	@echo ""

k8s-status: ## Check status of all resources
	@echo "📊 Cluster Status:"
	@echo "================="
	@kubectl cluster-info --context kind-$(CLUSTER_NAME) 2>/dev/null || echo "Cluster not running"
	@echo ""
	@echo "📦 Application Pods:"
	@kubectl get pods -n demo-app 2>/dev/null || echo "No pods in demo-app namespace"
	@echo ""
	@echo "🔄 ArgoCD Application Status:"
	@kubectl get application -n argocd demo-flask-app 2>/dev/null || echo "ArgoCD application not found"

k8s-logs: ## View application logs
	@echo "📜 Application Logs:"
	@kubectl logs -n demo-app -l app.kubernetes.io/name=demo-flask-app --tail=100 -f

k8s-cleanup: ## Delete the Kind cluster and cleanup
	@echo "🗑️  Cleaning up cluster: $(CLUSTER_NAME)"
	kind delete cluster --name $(CLUSTER_NAME)
	@echo "✅ Cluster deleted successfully"
