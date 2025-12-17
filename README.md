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
- `/healthz` - Legacy health check (→ readiness)
- `/healthz/live` - Liveness probe (process check)
- `/healthz/ready` - Readiness probe (full health check)

## CI/CD Pipeline

Image tag: `{short-sha}-{run-number}` (e.g., `a1b2c3d-42`)

**Pipeline Stages:**

1. **Lint** - flake8 + pylint (fails on errors, --fail-under=8.0)
2. **Test** - pytest with coverage (70% threshold, uploads to Codecov)
3. **Build** - Docker image + Trivy vulnerability scan
4. **E2E Test** - Deploy with Helm chart in kind cluster
5. **Update GitOps** - Update demo_gitops with yq (only on main)

**Security:** Actions pinned to SHA, Trivy scanning, concurrency control
**Speed:** ~5 minutes total
**PR Support:** Runs on PRs without pushing images
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
