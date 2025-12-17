# Setup Guide for New Users

Simple guide to get this GitOps demo running on your local machine.

## Prerequisites

You need:
- **Docker** - Container runtime
- **kind** - Kubernetes in Docker
- **kubectl** - Kubernetes CLI  
- **Python 3.11+** - For local testing
- **Git** - Version control

### Quick Install (macOS)
```bash
brew install docker kind kubectl
open -a Docker  # Start Docker Desktop
```

### Quick Install (Linux)
```bash
# Docker
curl -fsSL https://get.docker.com | sh

# kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/
```

## Getting Started

### 1. Clone Repositories
```bash
mkdir -p ~/projects/gitops-demo && cd ~/projects/gitops-demo
git clone https://github.com/banicr/demo_app.git
git clone https://github.com/banicr/demo_gitops.git
```

### 2. Test Locally (Optional)
```bash
cd demo_app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt -r requirements-test.txt
pytest -v
python app/main.py  # Visit http://127.0.0.1:5000
deactivate
```

### 3. Deploy to Kubernetes
```bash
cd scripts
./setup-local-cluster.sh
```

Wait for script to complete. It creates a kind cluster, installs ArgoCD, and deploys the app.

### 4. Access the Application
```bash
# New terminal
kubectl port-forward -n demo-app svc/demo-flask-app 8080:80
```
Visit: http://localhost:8080

### 5. Access ArgoCD Dashboard
```bash
# Another terminal
kubectl port-forward -n argocd svc/argocd-server 8081:443
```
Visit: https://localhost:8081
- Username: `admin`
- Password: From setup script or run:
  ```bash
  kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
  ```

## Making Changes

### Update the Application
```bash
# Edit app/main.py - change version "2.0.0" to "2.1.0"
git add app/main.py
git commit -m "Bump version"
git push origin main
```

**What Happens**:
1. GitHub Actions runs (5 min) → builds image → updates demo_gitops
2. ArgoCD detects change (within 3 min) → deploys new version
3. Refresh http://localhost:8080 to see new version

**Monitor**:
- Pipeline: https://github.com/banicr/demo_app/actions
- ArgoCD: https://localhost:8081
- Pods: `kubectl get pods -n demo-app -w`

## Useful Commands

```bash
# Check application
kubectl get pods -n demo-app
kubectl logs -n demo-app -l app=demo-flask-app

# Check ArgoCD sync status
kubectl get applications -n argocd

# Force ArgoCD sync (don't wait 3 min)
kubectl patch application demo-flask-app -n argocd --type merge -p '{"operation": {"sync": {}}}'

# Restart app
kubectl rollout restart deployment demo-flask-app -n demo-app
```

## Troubleshooting

**Tests failing?**
```bash
cd demo_app
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt -r requirements-test.txt
pytest -v
```

**ArgoCD not syncing?**
```bash
kubectl get application demo-flask-app -n argocd
kubectl patch application demo-flask-app -n argocd --type merge -p '{"operation": {"sync": {}}}'
```

**Can't access app?**
```bash
kubectl get pods -n demo-app  # Check pods are running
kubectl logs -n demo-app -l app=demo-flask-app  # Check logs
kubectl port-forward -n demo-app svc/demo-flask-app 8080:80  # Port forward
```

**Cluster issues?**
```bash
kind delete cluster --name dev-gitops-cluster
cd demo_app/scripts && ./setup-local-cluster.sh
```

## Cleanup

```bash
# Delete everything
kind delete cluster --name dev-gitops-cluster
cd demo_app && rm -rf venv

# Or start fresh
kind delete cluster --name dev-gitops-cluster
cd demo_app/scripts && ./setup-local-cluster.sh
```

## Quick Reference

**URLs**:
- App: http://localhost:8080
- ArgoCD: https://localhost:8081 (admin / see setup script output)
- Pipeline: https://github.com/banicr/demo_app/actions

**Key Files**:
- App code: `demo_app/app/main.py`
- CI/CD: `demo_app/.github/workflows/pipeline.yml`
- Helm config: `demo_gitops/helm/demo-flask-app/values.yaml`
- ArgoCD app: `demo_gitops/argocd-application.yaml`

**Learn More**: See [ARCHITECTURE.md](ARCHITECTURE.md) for diagrams and detailed flow.
