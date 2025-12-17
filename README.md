# Demo Flask App

[![CI/CD Pipeline](https://github.com/banicr/demo_app/actions/workflows/pipeline.yml/badge.svg)](https://github.com/banicr/demo_app/actions/workflows/pipeline.yml)

A simple Flask web application with automated CI/CD using GitHub Actions, Kubernetes, and ArgoCD.

## What It Does

1. You push code to this repo
2. GitHub Actions automatically:
   - Runs tests
   - Builds a Docker image
   - Tests the image
   - Updates [demo_gitops](https://github.com/banicr/demo_gitops) repo
3. ArgoCD deploys to Kubernetes

## Endpoints

- `/` - Main page with app version
- `/healthz` - Health check (returns `{"status": "ok"}`)

## Quick Start

### Prerequisites

- Python 3.11+ ([Install](https://www.python.org/downloads/))
- Docker (for container testing)
- kubectl & kind (for Kubernetes deployment)

### Run Locally

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the app
python -m app.main
# Visit http://localhost:5000
```



### Run with Docker

```bash
docker build -t demo-flask-app:local .
docker run -p 5000:5000 demo-flask-app:local
# Visit http://localhost:5000
```

## CI/CD Pipeline

The pipeline runs automatically when you push to `main`:

1. **Test** - Run pytest unit tests on Python code:
   - Health check endpoint (`/healthz`) returns `{"status": "ok"}`
   - Main page (`/`) returns HTML with app version
   - HTTP status codes and content types
   - Tests application logic without Docker/Kubernetes
2. **Build** - Build Docker image and push to GitHub Container Registry:
   - Image: `ghcr.io/banicr/demo-flask-app:{tag}`
   - Also tagged as `latest`
3. **E2E Test** - Test Docker image in real Kubernetes environment:
   - Create temporary kind cluster
   - Load Docker image into cluster
   - Deploy app with Kubernetes manifests
   - Verify app works in production-like conditions
   - Delete cluster after testing
4. **Update GitOps** - Updates `helm-chart/values.yaml` in demo_gitops repo:
   - `image.tag`: New image version
   - `appVersion`: Application version

Image tag format: `v2.0.0-{git-sha}-{run-number}`

## Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete setup instructions
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System diagrams and flow
- **[REBUILD_PROMPTS.md](REBUILD_PROMPTS.md)** - Recreate this project from scratch
- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** - Multi-service architecture and DevOps improvements

## Related Repositories

- **[demo_gitops](https://github.com/banicr/demo_gitops)** - Kubernetes deployment manifests
