# Setup Guide

## Prerequisites

- Docker Desktop (running)
- kind, kubectl, helm

**Install (macOS):**
```bash
brew install kind kubectl helm
```

## Setup**1. Clone repos (same directory):**
```bash
git clone https://github.com/banicr/demo_app.git
git clone https://github.com/banicr/demo_gitops.git
```

**2. Deploy:**
```bash
cd demo_app
make deploy
```

**3. Access app:**
```bash
make port-forward
```
Open http://localhost:8080

## Development

**Make changes:**
```bash
# Edit app/main.py
git add . && git commit -m "Update" && git push
```

**Pipeline runs automatically:**
1. Lint + Test
2. Build Docker image
3. E2E test in Kind cluster
4. Update GitOps repo

**Check status:**
```bash
make k8s-status    # Pod status
make k8s-logs      # App logs
```

## Cleanup

```bash
make clean
```

## Useful Commands

```bash
make deploy          # Deploy to local cluster
make port-forward    # Access at http://localhost:8080
make argocd-ui       # Access ArgoCD UI
make argocd-password # Get ArgoCD password
make k8s-status      # Check status
make k8s-logs        # View logs
make clean           # Delete cluster
```
