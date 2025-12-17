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

## One-Time Setup

### 1. Enable Workflow Permissions (ONE-TIME)

**Repository Settings → Actions → General → Workflow permissions:**
- Select "Read and write permissions"
- Check "Allow GitHub Actions to create and approve pull requests"
- Save

### 2. Create GITOPS_PAT Secret (ONE-TIME)

**Get Token:** https://github.com/settings/tokens/new
- Name: `GitOps Updates`
- Scope: Check `repo`
- Generate and copy token

**Add Secret:** https://github.com/banicr/demo_app/settings/secrets/actions
- Click "New repository secret"
- Name: `GITOPS_PAT`
- Value: Paste token
- Save

✅ Done! Pipeline will work automatically on every push.

## Troubleshooting

**Error: `permission_denied: write_package`**
- Cause: Missing workflow permissions (see step 1 above)
- Fix: Enable "Read and write permissions" in Actions settings

**Error: `GITOPS_PAT secret is not set`**
- Cause: Missing or incorrectly named secret (see step 2 above)
- Fix: Add secret named exactly `GITOPS_PAT` with `repo` scope

## Related Repositories

- **[demo-gitops-repo

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Complete setup instructions
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System diagrams and flow
- **[REBUILD_PROMPTS.md](REBUILD_PROMPTS.md)** - Recreate this project from scratch
- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** - Multi-service architecture and DevOps improvements

## Related Repositories

- **[demo_gitops](https://github.com/banicr/demo-gitops-repo)** - Kubernetes deployment manifests
