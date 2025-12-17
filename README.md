# Demo Flask App

[![CI/CD Pipeline](https://github.com/banicr/demo_app/actions/workflows/ci.yml/badge.svg)](https://github.com/banicr/demo_app/actions/workflows/ci.yml)

Simple Flask app with automated CI/CD pipeline.

## Quick Start

```bash
# Clone both repos (same directory)
git clone https://github.com/banicr/demo_app.git
git clone https://github.com/banicr/demo_gitops.git

# Deploy locally
cd demo_app
make deploy

# Access app
make port-forward
# Open http://localhost:8080
```

## Endpoints

- `/` - Main page with app info
- `/healthz` - Health check
- `/healthz/live` - Liveness probe
- `/healthz/ready` - Readiness probe

## CI/CD Pipeline

**What happens on `git push`:**

1. **Lint** - flake8 + pylint
2. **Test** - pytest with coverage
3. **Build** - Docker image → GitHub Container Registry
4. **E2E Test** - Deploy to temporary Kind cluster with Helm
5. **Update GitOps** - Update demo_gitops/values.yaml with new image tag

**Result:** New image built and GitOps repo updated (~2-3 minutes)
- Select "Read and write permissions" → Save

### 2. Create GITOPS_PAT Secret

1. Create token: https://github.com/settings/tokens/new (check `repo` scope)
2. Add secret: https://github.com/banicr/demo_app/settings/secrets/actions
   - Name: `GITOPS_PAT`
   - Value: Your token

✅ Done! Pipeline runs automatically on every push.

## Commands

```bash
make deploy          # Deploy to local Kind cluster
make port-forward    # Access app at http://localhost:8080
make k8s-status      # Check deployment status
make k8s-logs        # View application logs
make clean           # Delete cluster
```

## Documentation

- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup instructions
- [demo_gitops](https://github.com/banicr/demo_gitops) - Helm charts
