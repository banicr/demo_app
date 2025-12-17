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

## Setup GitHub Secret

Add this secret to enable CI/CD (`Settings > Secrets and variables > Actions`):

**GITOPS_REPO_SSH_KEY** - SSH key with write access to demo_gitops

Steps to create:
```bash
# 1. Generate SSH key
ssh-keygen -t ed25519 -C "github-actions" -f gitops_deploy_key

# 2. Add PUBLIC key to demo_gitops repo
# Settings > Deploy keys > Add deploy key > ✓ Allow write access

# 3. Add PRIVATE key to demo_app repo
# Settings > Secrets and variables > Actions > New repository secret
# Name: GITOPS_REPO_SSH_KEY
# Secret: (paste entire private key content)
```

## Deploy to Kubernetes

### Setup Cluster

```bash
# Run setup script (creates cluster + ArgoCD + deploys app)
cd scripts
./setup-local-cluster.sh
```

The script automatically:
- Creates kind cluster
- Installs ArgoCD
- Deploys the app via ArgoCD
- Verifies deployment

### Access the App

```bash
# Port forward to access the app
kubectl port-forward -n demo-app svc/demo-flask-app 9090:80
# Visit http://localhost:9090
```

### Access ArgoCD UI

```bash
# Port forward ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Visit https://localhost:8080
# Username: admin
```

## How It Works

```
Push code → GitHub Actions (Test → Build → E2E → Update GitOps) 
         → demo_gitops updated → ArgoCD syncs → Kubernetes deploys
```

Test the flow:
1. Make a change in `app/main.py`
2. Push to main: `git commit -am "Update" && git push`
3. Watch GitHub Actions: https://github.com/banicr/demo_app/actions
4. Watch ArgoCD sync: `kubectl get application demo-flask-app -n argocd -w`
5. Check new version: `curl http://localhost:9090`

## Troubleshooting

**Pipeline fails?**
- Check: https://github.com/banicr/demo_app/actions
- Fix tests and push again

**ArgoCD not syncing?**
```bash
# Check status
kubectl get application demo-flask-app -n argocd

# Force sync
kubectl patch application demo-flask-app -n argocd \
  --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'
```

**App not working?**
```bash
# Check pods
kubectl get pods -n demo-app

# Check logs
kubectl logs -n demo-app -l app=demo-flask-app
```

## Clean Up

```bash
# Delete everything
kind delete cluster --name dev-gitops-cluster
```

## Related Repos

- [demo_gitops](https://github.com/banicr/demo_gitops) - Kubernetes deployment manifests

## Resources

- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [Kind Docs](https://kind.sigs.k8s.io/)
- [Flask Docs](https://flask.palletsprojects.com/)
