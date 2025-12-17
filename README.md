# Demo Flask App

[![CI/CD Pipeline](https://github.com/banicr/demo_app/actions/workflows/ci.yml/badge.svg)](https://github.com/banicr/demo_app/actions/workflows/ci.yml)

A Flask web application with automated CI/CD using GitHub Actions, Kubernetes, and ArgoCD.

## What It Does

1. **Push code** → GitHub Actions runs automatically
2. **Pipeline** (5 stages):
   - **Lint**: Code quality (flake8, pylint)
   - **Test**: Unit tests (pytest)
   - **Build**: Docker image → GitHub Container Registry
   - **E2E Test**: Test in kind cluster
   - **GitOps Update**: Update deployment config
3. **ArgoCD** detects change → deploys to Kubernetes

## Endpoints

- `/` - Main page with app version
- `/healthz` - Health check (returns `{"status": "ok"}`)

## Quick Start

### Run Locally

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
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

Image tag: `{short-sha}-{run-number}` (e.g., `a1b2c3d-42`)

**Stage 1: Lint** - flake8 + pylint  
**Stage 2: Test** - pytest unit tests  
**Stage 3: Build** - Docker image → `ghcr.io/banicr/demo-flask-app:{tag}`  
**Stage 4: E2E Test** - Deploy to kind cluster, test endpoints  
**Stage 5: Update GitOps** - Update `demo-gitops-repo` with new tag (main branch only)

## Setup Required

### 1. Enable GitHub Container Registry

Go to repository Settings → Actions → General → Workflow permissions:
- Select "Read and write permissions"
- Check "Allow GitHub Actions to create and approve pull requests"
- Click Save

### 2. Add GITOPS_PAT Secret

The pipeline needs this to update the GitOps repo:

1. GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `repo` scope
3. Go to this repository → Settings → Secrets and variables → Actions
4. New repository secret:
   - Name: `GITOPS_PAT`
   - Value: your token

## Troubleshooting

### Pipeline fails with "permission_denied: write_package"

This error occurs when GitHub Actions can't push to GitHub Container Registry (GHCR). To fix:

1. **Enable Workflow Permissions** (Most common fix):
   - Go to repository **Settings → Actions → General**
   - Scroll to "Workflow permissions"
   - Select **"Read and write permissions"**
   - Check **"Allow GitHub Actions to create and approve pull requests"**
   - Click **Save**

2. **Set Package Visibility** (If package already exists):
   - Go to your GitHub profile → **Packages**
   - Find `demo-flask-app` package
   - Package settings → **Connect repository** → Select `demo_app`
   - Ensure visibility matches your repository (Public/Private)

3. **Manual First Push** (If package doesn't exist):
   ```bash
   # Login to GHCR
   echo $GITHUB_TOKEN | docker login ghcr.io -u banicr --password-stdin
   
   # Build and push initial image
   docker build -t ghcr.io/banicr/demo-flask-app:initial .
   docker push ghcr.io/banicr/demo-flask-app:initial
   ```

After applying the fix, re-run the failed workflow.

### GITOPS_PAT error

- Ensure Personal Access Token has `repo` scope
- Verify secret name is exactly `GITOPS_PAT` (case-sensitive)
- Check token hasn't expired (regenerate if needed)

## Related Repositories

- **[demo-gitops-repo

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete setup instructions
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System diagrams and flow
- **[REBUILD_PROMPTS.md](REBUILD_PROMPTS.md)** - Recreate this project from scratch
- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** - Multi-service architecture and DevOps improvements

## Related Repositories

- **[demo_gitops](https://github.com/banicr/demo-gitops-repo)** - Kubernetes deployment manifests
