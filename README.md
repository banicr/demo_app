# Demo Flask App

[![CI/CD Pipeline](https://github.com/banicr/demo_app/actions/workflows/ci.yml/badge.svg)](https://github.com/banicr/demo_app/actions/workflows/ci.yml)

Flask app with automated CI/CD → GitHub Actions builds & tests → ArgoCD deploys to Kubernetes.

## How It Works

1. **Push code** → GitHub Actions runs
2. **Pipeline** (5 stages): Lint → Test → Build → E2E Test → Update GitOps
3. **ArgoCD** detects change → Deploys to Kubernetes (~3 min total)

## Quick Start

```bash
# Clone repos
git clone https://github.com/banicr/demo_app.git
git clone https://github.com/banicr/demo_gitops.git

# Setup cluster
cd demo_app/scripts && ./setup-local-cluster.sh

# Access app
kubectl port-forward -n demo-app svc/demo-flask-app 8080:80
# Open http://localhost:8080
```

**Endpoints:**
- `/` - Main page
- `/healthz` - Health check

## CI/CD Pipeline

Image tag: `{short-sha}-{run-number}` (e.g., `a1b2c3d-42`)

**Stage 1: Lint** - flake8 + pylint  
**Stage 2: Test** - pytest unit tests  
**SPipeline Stages

1. **Lint** - Code quality checks
2. **Test** - Run unit tests
3. **Build** - Create Docker image `ghcr.io/banicr/demo-flask-app:{sha}-{run}`
4. **E2E Test** - Deploy & test in temporary cluster
5. **Update GitOps** - Validate Helm & push to `demo_gitops`

Fast: ~3 minutes. Safe: Validates before deploy.
- Select "Read and write permissions"
- Save

This allows GitHub Actions to push Docker images to GHCR.

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

## Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Get started in 5 minutes
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - How it works
- **[REBUILD_PROMPTS.md](REBUILD_PROMPTS.md)** - Recreate this project from scratch
- **[demo_gitops](https://github.com/banicr/demo_gitops)** - Deployment manifests

---

**Summary:** Push code → GitHub Actions builds/tests → Updates GitOps repo → ArgoCD deploys. All automatic, all validated.
