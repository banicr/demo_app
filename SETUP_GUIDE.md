# Setup Guide

Get this Flask app running locally with Kubernetes + ArgoCD in 5 minutes.

## What You Need

- **Docker Desktop** - Running
- **kind** - Local Kubernetes
- **kubectl** - Kubernetes CLI

**Install (macOS):**
```bash
brew install kind kubectl
```

**Install (Linux):**
```bash
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
```Quick Start

**1. Clone repos:**
```bash
mkdir -p ~/gitops && cd ~/gitops
git clone https://github.com/banicr/demo_app.git
git clone https://github.com/banicr/demo_gitops.git
```

**2. Run setup:**
```bash
cd demo_app/scripts
./setup-local-cluster.sh
```

This creates a Kubernetes cluster, installs ArgoCD, and deploys the app (~3 minutes).

**3. Access the app:**
```bash
kubectl port-forward -n demo-app svc/demo-flask-app 8080:80
```
Open: http://localhost:8080

**4. Access ArgoCD (optional):**
```bash
kubectl port-forward -n argocd svc/argocd-server 8081:443
```
Open: https://localhost:8081
- Username: `admin`
- Password: Run `cat argocd-credentials.txt` in the scripts folderdd app/main.py
git commit -m "Bump version"
git push origin main
```

**What Happens**:
1. GitHub Actions runs (5 min) → builds image → updates demo_gitops
2. ArgoCD detects change (within 3 min) → deploys new version
3. Refresh http://localhost:8080 to see new version

**Monitor**:
- PHow It Works

**Make a code change:**
```bash
cd demo_app
# Edit app/main.py
git add . && git commit -m "Update app" && git push
```

**What happens automatically:**
1. GitHub Actions builds Docker image (~3 min)
2. Pipeline validates & updates demo_gitops repo
3. ArgoCD deploys to Kubernetes (~1 min)
4. Refresh http://localhost:8080 to see changes

**Monitor progress:**
- Pipeline: https://github.com/banicr/demo_app/actions
- ArgoCD: https://localhost:8081
- Pods: `kubectl get pods -n demo-appflask-app -n demo-app
```

## Troubleshooting

**Pods not running?**
```bash
kubectl get pods -n demo-app
kubectl logs -n demo-app -l app.kubernetes.io/name=demo-flask-app
```

**Can't access app?**
```bash
kubectl port-forward -n demo-app svc/demo-flask-app 8080:80
```

**ArgoCD not syncing?**
```bash
kubectl get application -n argocd demo-flask-app
```

**Start over:**
```bash
kind delete cluster --name gitops-demo
cd demo_app/scripts && ./setup-local-cluster.sh
```

## Cleanup

```bash
kind delete cluster --name gitops-demo
```

That's it! Everything deleted.

## Quick Reference

- **App:** http://localhost:8080  
- **ArgoCD:** https://localhost:8081 (credentials in `argocd-credentials.txt`)
- **Pipeline:** https://github.com/banicr/demo_app/actions
- **Cluster:** `gitops-demo`
