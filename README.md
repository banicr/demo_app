# Demo Flask App - Application Repository

[![CI/CD Pipeline](https://github.com/banicr/demo-app-repo/actions/workflows/pipeline.yml/badge.svg)](https://github.com/banicr/demo-app-repo/actions/workflows/pipeline.yml)

A production-ready Python Flask web application demonstrating complete CI/CD and GitOps workflows with GitHub Actions, Kubernetes (kind), and ArgoCD.

## Overview

This repository contains a Flask application that implements a fully automated GitOps-based CI/CD pipeline:

1. **Developer pushes code** to `app-repo` (this repository)
2. **GitHub Actions pipeline** executes four stages:
   - **Test**: Unit tests with pytest validate code functionality
   - **Build**: Multi-platform Docker image (amd64/arm64) built and pushed to GHCR
   - **E2E Test**: Ephemeral kind cluster validates image works correctly
   - **GitOps Update**: Helm values updated in gitops-repo (only if E2E passes)
3. **ArgoCD** detects the change and automatically syncs to the target Kubernetes cluster
4. **Application** is deployed with zero-downtime rolling update

### Application Features

- **Health Check Endpoint**: `/healthz` returns JSON `{"status": "ok"}` with HTTP 200
- **Version Display**: Root endpoint `/` shows a styled HTML page with current app version
- **Production Ready**: Uses gunicorn with 2 workers and 4 threads per worker
- **Kubernetes Native**: Includes liveness and readiness probes on `/healthz`
- **Secure**: Runs as non-root user (uid 1000) with minimal privileges
- **Multi-stage Docker Build**: Optimized image size using Python slim base

## Repository Structure

```
app-repo/
├── app/
│   ├── __init__.py
│   └── main.py                      # Flask application code
├── tests/
│   ├── __init__.py
│   └── test_app.py                  # Unit tests with pytest
├── scripts/
│   └── setup-local-cluster.sh       # Complete local environment setup (kind + ArgoCD + app)
├── .github/
│   └── workflows/
│       └── ci.yml                   # Main CI/CD pipeline (4 stages)
├── Dockerfile                       # Production container image
├── requirements.txt                 # Application dependencies
├── requirements-test.txt            # Test dependencies (pytest, coverage)
├── pytest.ini                       # Pytest configuration
├── .gitignore
└── README.md                        # This file
```

## Prerequisites

### Required Tools

- **Docker**: Container runtime ([Install](https://docs.docker.com/get-docker/))
- **kubectl**: Kubernetes CLI ([Install](https://kubernetes.io/docs/tasks/tools/))
- **kind**: Kubernetes in Docker ([Install](https://kind.sigs.k8s.io/docs/user/quick-start/#installation))
- **Git**: Version control
- **Python 3.11+**: For local development (optional)

### Required Accounts

- **GitHub Account**: For repository hosting and CI/CD
- **Docker Hub Account**: For container registry ([Sign up](https://hub.docker.com/signup))

### Local Development (Optional)

If you want to run the app locally without Docker:

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

## Local Development

### Running the App Locally

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the Flask app**:
   ```bash
   python -m app.main
   # Or use Flask CLI:
   # export FLASK_APP=app.main
   # flask run
   ```

3. **Access the application**:
   - Main page: http://localhost:5000
   - Health check: http://localhost:5000/healthz

4. **Set custom version** (optional):
   ```bash
   export APP_VERSION="v2.0.0-dev"
   python -m app.main
   ```

### Running Tests

```bash
# Install test dependencies
pip install -r requirements-test.txt

# Run all tests
pytest

# Run with verbose output
pytest -v

# Run specific test file
pytest tests/test_app.py

# Run with coverage
pytest --cov=app tests/
```

### Building Docker Image Manually

1. **Build the image**:
   ```bash
   docker build -t demo-flask-app:local .
   ```

2. **Run the container**:
   ```bash
   docker run -d -p 5000:5000 \
     -e APP_VERSION="v1.0.0-local" \
     --name flask-app \
     demo-flask-app:local
   ```

3. **Test the endpoints**:
   ```bash
   # Health check
   curl http://localhost:5000/healthz
   # Expected: {"status":"ok"}
   
   # Main page
   curl http://localhost:5000
   # Expected: HTML page with version info
   ```

4. **View logs**:
   ```bash
   docker logs flask-app
   ```

5. **Stop and remove**:
   ```bash
   docker stop flask-app
   docker rm flask-app
   ```

## CI/CD Pipeline Design

### Pipeline Architecture

The complete CI/CD pipeline is defined in `.github/workflows/pipeline.yml` and implements a 4-stage automated workflow:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        GitHub Actions Pipeline                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Stage 1: Code Quality & Testing                                     │
│  ┌──────────┐     ┌──────────┐                                      │
│  │   Lint   │     │   Test   │  (Python 3.10, 3.11, 3.12)           │
│  │ flake8,  │────▶│  pytest  │                                      │
│  │  black   │     │ coverage │                                      │
│  └──────────┘     └────┬─────┘                                      │
│                        │                                             │
│  Stage 2: Build & Push Docker Image                                 │
│                        │                                             │
│                   ┌────▼─────┐                                       │
│                   │  Build   │  Image tag: v2.0.0-{sha}-{run}       │
│                   │  Docker  │  Push to GHCR                        │
│                   │  Image   │  Tag: latest                         │
│                   └────┬─────┘                                       │
│                        │                                             │
│  Stage 3: E2E Testing in Ephemeral Kind Cluster                     │
│                        │                                             │
│                   ┌────▼─────┐                                       │
│                   │   E2E    │  1. Create kind cluster              │
│                   │   Test   │  2. Load Docker image                │
│                   │          │  3. Deploy app                       │
│                   │          │  4. Run smoke tests                  │
│                   │          │  5. Cleanup cluster                  │
│                   └────┬─────┘                                       │
│                        │                                             │
│  Stage 4: GitOps Repository Update                                  │
│                        │                                             │
│                   ┌────▼────────┐                                    │
│                   │   Update    │  1. Clone gitops-repo              │
│                   │   GitOps    │  2. Update kustomization.yaml     │
│                   │   Repo      │  3. Update deployment.yaml        │
│                   │             │  4. Commit & push changes         │
│                   └─────────────┘                                    │
│                                                                       │
└───────────────────────────────────────┬───────────────────────────────┘
                                        │
                                        ▼
                              ┌──────────────────┐
                              │     ArgoCD       │
                              │  (Auto-syncs     │
                              │   to Cluster)    │
                              └─────────┬────────┘
                                        │
                                        ▼
                              ┌──────────────────┐
                              │   Kubernetes     │
                              │    Cluster       │
                              │  (Production)    │
                              └──────────────────┘
```

### Pipeline Stages Explained

#### Stage 1: Code Quality & Testing

**Purpose**: Ensure code quality and correctness before building artifacts

**Jobs**:
- **`lint`**: Runs flake8 and black to check code style
- **`test`**: Executes pytest across Python 3.10, 3.11, and 3.12
  - Generates code coverage reports
  - Uploads coverage HTML report as artifact
  - Pipeline fails if tests fail

**Triggers**: Push to `main` or pull requests

#### Stage 2: Build & Push Docker Image

**Purpose**: Create versioned, immutable container image

**Job**: `build`

**Steps**:
1. Generate semantic version tag: `v2.0.0-{short-sha}-{run-number}`
2. Build multi-layer optimized Docker image
3. Push to GitHub Container Registry (GHCR) with two tags:
   - Versioned: `ghcr.io/banicr/demo-flask-app:v2.0.0-abc1234-42`
   - Latest: `ghcr.io/banicr/demo-flask-app:latest`
4. Pass image tag to downstream jobs

**Triggers**: After successful lint and test

#### Stage 3: E2E Testing in Ephemeral Kind Cluster

**Purpose**: Validate the Docker image in a real Kubernetes environment

**Job**: `e2e-test`

**Steps**:
1. Install kind and kubectl
2. Create temporary kind cluster: `e2e-test-{run-id}`
3. Login to GHCR and pull the built image
4. Load image into kind cluster
5. Deploy application:
   - Create `demo-app` namespace
   - Deploy with correct image and environment variables
   - Set `imagePullPolicy: IfNotPresent`
   - Wait for deployment to be ready
6. Run smoke tests:
   - Health check: `GET /healthz` returns `{"status":"ok"}`
   - Root endpoint: `GET /` contains "Demo Flask App"
   - Version display: Response includes image tag
   - HTTP status: Returns 200 OK
7. Capture pod logs if tests fail
8. Delete kind cluster (always runs)

**Triggers**: Only on push to `main` (skipped for PRs), after successful build

**Skip Option**: Can be skipped with workflow_dispatch input `skip_e2e: true`

#### Stage 4: GitOps Repository Update

**Purpose**: Update deployment manifests to trigger ArgoCD sync

**Job**: `update-gitops`

**Steps**:
1. Validate `GITOPS_REPO_SSH_KEY` secret exists
2. Setup SSH authentication
3. Clone `demo-gitops-repo` 
4. Update `k8s/base/kustomization.yaml`:
   ```yaml
   images:
   - name: ghcr.io/banicr/demo-flask-app
     newTag: v2.0.0-abc1234-42  # Updated
   ```
5. Update `k8s/base/deployment.yaml`:
   ```yaml
   env:
   - name: APP_VERSION
     value: "v2.0.0-abc1234-42"  # Updated
   ```
6. Commit with detailed message including:
   - Image tag
   - Source commit SHA
   - GitHub Actions run link
7. Push to `main` branch
8. ArgoCD detects change and auto-syncs

**Triggers**: After successful E2E test (or if E2E skipped), only on push to `main`

### Pipeline Execution Flow

**For Pull Requests**:
```
PR opened → Lint → Test → Build → (stops here, no deployment)
```

**For Push to Main**:
```
Push to main → Lint → Test → Build → E2E Test → Update GitOps → ArgoCD syncs
```

**Manual Trigger**:
```
workflow_dispatch → Same as push, with option to skip E2E
```

### Required GitHub Secrets

Configure these secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):

#### Docker Hub Credentials

```
# No Docker Hub secrets needed - GHCR uses GITHUB_TOKEN automatically
# GITHUB_TOKEN is automatically provided by GitHub Actions
```

**How to create Docker Hub token**:
1. Log in to [Docker Hub](https://hub.docker.com)
2. Go to Account Settings > Security > Access Tokens
3. Click "New Access Token"
4. Name: `github-actions-ci`
5. Permissions: Read & Write
6. Copy the token (you won't see it again!)

#### GitOps Repository Access

**Option A: SSH Key (Recommended)**

```
GITOPS_REPO_SSH_KEY=<your-ssh-private-key>
```

**How to create SSH deploy key**:
1. Generate SSH key pair:
   ```bash
   ssh-keygen -t ed25519 -C "github-actions@demo-flask-app" -f gitops_deploy_key
   ```
2. Add **public key** (`gitops_deploy_key.pub`) to `gitops-repo`:
   - Go to `gitops-repo` > Settings > Deploy keys
   - Click "Add deploy key"
   - Title: `CI Pipeline`
   - Key: paste public key content
   - ✓ Allow write access
3. Add **private key** (`gitops_deploy_key`) to `app-repo` secrets:
   - Name: `GITOPS_REPO_SSH_KEY`
   - Value: entire private key content including `-----BEGIN OPENSSH PRIVATE KEY-----`

**Option B: Personal Access Token (Alternative)**

```
GITOPS_REPO_TOKEN=<your-github-pat>
```

**How to create PAT**:
1. GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)
2. Generate new token
3. Scopes: `repo` (full control)
4. Copy token and add to `app-repo` secrets

**Note**: If using PAT, update `pipeline.yml`:
```yaml
# Replace this line:
ssh-key: ${{ secrets.GITOPS_REPO_SSH_KEY }}
# With:
token: ${{ secrets.GITOPS_REPO_TOKEN }}
```

### Pipeline Configuration

Update these values in `.github/workflows/pipeline.yml`:

```yaml
env:
  DOCKER_IMAGE: ghcr.io/banicr/demo-flask-app
  GITOPS_REPO: git@github.com:YOUR_ORG/gitops-repo.git  # Update this
  GITOPS_REPO_BRANCH: main
```

And in the `update-gitops` job:

```yaml
- name: Checkout GitOps repo
  uses: actions/checkout@v4
  with:
    repository: YOUR_ORG/gitops-repo  # Update this
```

## Cluster Setup

### Automated Setup Script

We provide a script that automates the entire cluster setup:

```bash
# Run the comprehensive setup script
cd scripts
./setup-local-cluster.sh
```

**The script will**:
1. Verify prerequisites (docker, kubectl, kind)
2. Create a kind cluster named `dev-gitops-cluster`
3. Install ArgoCD in the `argocd` namespace
4. Create the `demo-app` namespace
5. Display the ArgoCD admin password
6. Provide instructions for accessing the UI

### Manual Setup (Alternative)

If you prefer manual steps:

```bash
# Create kind cluster
kind create cluster --name dev-gitops-cluster

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Create app namespace
kubectl create namespace demo-app

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

### Accessing ArgoCD UI

1. **Port forward the ArgoCD server**:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

2. **Open browser** to https://localhost:8080
   - Username: `admin`
   - Password: (from setup script output or retrieve with):
     ```bash
     kubectl -n argocd get secret argocd-initial-admin-secret \
       -o jsonpath="{.data.password}" | base64 -d; echo
     ```

3. **Accept self-signed certificate warning** in browser

### Deploying the Application

1. **Clone the gitops-repo** (or have it ready)
2. **Update the ArgoCD Application manifest** in `gitops-repo/argocd-application.yaml`:
   - Replace `YOUR_ORG` with your GitHub organization/username
3. **Apply the ArgoCD Application**:
   ```bash
   kubectl apply -f gitops-repo/argocd-application.yaml
   ```

4. **Watch ArgoCD sync**:
   ```bash
   # In ArgoCD UI, or:
   kubectl get applications -n argocd
   kubectl describe application demo-flask-app -n argocd
   ```

5. **Verify deployment**:
   ```bash
   kubectl get pods -n demo-app
   kubectl get svc -n demo-app
   ```

## End-to-End Flow

### Complete Deployment Flow

```
┌─────────────────┐
│ Developer       │
│ pushes code     │
│ to app-repo     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ GitHub Actions Pipeline                 │
├─────────────────────────────────────────┤
│ 1. Run tests (pytest)                   │
│ 2. Build Docker image                   │
│ 3. Push to Docker Hub                   │
│ 4. Update gitops-repo with new tag      │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ GitOps Repo Updated                     │
│ (new image tag in kustomization.yaml)   │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ ArgoCD Detects Change                   │
│ (polls Git every 3 minutes by default)  │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ ArgoCD Syncs to Cluster                 │
│ (creates/updates Deployment)            │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ Kubernetes Rolling Update               │
│ (zero-downtime deployment)              │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│ New Version Running!                    │
│ (accessible via Service)                │
└─────────────────────────────────────────┘
```

### Testing the Complete Flow

1. **Initial Setup**:
   ```bash
   # Set up cluster and ArgoCD
   cd scripts
   ./setup-local-cluster.sh
   
   # Apply ArgoCD application (from gitops-repo)
   kubectl apply -f gitops-repo/argocd-application.yaml
   ```

2. **Verify Initial Deployment**:
   ```bash
   # Wait for sync
   kubectl wait --for=condition=Ready pods -l app=demo-flask-app -n demo-app --timeout=120s
   
   # Port forward to access the app
   kubectl port-forward -n demo-app svc/demo-flask-app 9090:80 &
   
   # Test health endpoint
   curl http://localhost:9090/healthz
   # Expected: {"status":"ok"}
   
   # View the web page
   curl http://localhost:9090
   # Or open in browser: http://localhost:9090
   ```

3. **Make a Change**:
   ```bash
   # Edit app/main.py - change the HTML text or add a feature
   # For example, modify the version display or add a new message
   
   # Commit and push to main branch
   git add app/main.py
   git commit -m "Update app UI with new message"
   git push origin main
   ```

4. **Watch the Pipeline**:
   ```bash
   # In GitHub:
   # - Go to Actions tab in app-repo
   # - Watch the pipeline run (build, test, update gitops)
   
   # Or use GitHub CLI:
   gh run watch
   ```

5. **Observe ArgoCD Sync**:
   ```bash
   # In ArgoCD UI (https://localhost:8080):
   # - Open the demo-flask-app application
   # - Watch it detect the change and sync
   
   # Or via CLI:
   watch kubectl get application demo-flask-app -n argocd
   
   # Watch pods rolling update:
   watch kubectl get pods -n demo-app
   ```

6. **Verify New Version**:
   ```bash
   # The app should still be accessible on localhost:9090
   # Refresh the browser or curl again
   curl http://localhost:9090
   
   # You should see the updated version/content
   ```

7. **Check Image Tag**:
   ```bash
   # See what image is running
   kubectl get deployment demo-flask-app -n demo-app -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
   
   # Should show: ghcr.io/banicr/demo-flask-app:{sha}
   ```

### Troubleshooting

#### Pipeline Fails

```bash
# Check GitHub Actions logs
# Go to: https://github.com/YOUR_ORG/app-repo/actions

# Common issues:
# - Tests failing: Fix code and push again
# - GHCR auth: Ensure GITHUB_TOKEN has packages:write permission
# - GitOps repo access: Check SSH key or PAT permissions
```

#### ArgoCD Not Syncing

```bash
# Check ArgoCD application status
kubectl describe application demo-flask-app -n argocd

# Manual sync
kubectl patch application demo-flask-app -n argocd \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
```

#### Pods Not Ready

```bash
# Check pod status
kubectl get pods -n demo-app
kubectl describe pod <pod-name> -n demo-app

# Check logs
kubectl logs -n demo-app -l app=demo-flask-app

# Common issues:
# - Image pull errors: Check Docker Hub credentials
# - Probe failures: Check /healthz endpoint
# - Resource limits: Check resource requests/limits
```

#### Can't Access Application

```bash
# Verify service exists
kubectl get svc -n demo-app

# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://demo-flask-app.demo-app.svc.cluster.local/healthz

# Check port forward
# Make sure port-forward is running:
kubectl port-forward -n demo-app svc/demo-flask-app 9090:80
```

## Clean Up

### Delete Everything

```bash
# Delete kind cluster (removes everything)
kind delete cluster --name dev-gitops-cluster

# Or keep cluster but remove app:
kubectl delete -f gitops-repo/argocd-application.yaml
kubectl delete namespace demo-app
```

### Remove Docker Images

```bash
# Local images
docker rmi demo-flask-app:local
docker rmi ghcr.io/banicr/demo-flask-app:latest

# Docker Hub: Delete via web UI or API
```

## AI Usage in This Project

This project was bootstrapped and developed with significant assistance from AI (GitHub Copilot / Claude). Below is a summary of how AI was utilized:

### AI-Generated Components

1. **Repository Structure**: The entire directory layout for both `app-repo` and `gitops-repo` was designed by AI based on GitOps best practices.

2. **Flask Application**: The `app/main.py` file, including the health check endpoint, HTML template, and environment variable handling, was generated by AI.

3. **Docker Configuration**: The `Dockerfile` with multi-stage build considerations, security hardening (non-root user), and health checks was created by AI.

4. **Unit Tests**: The `tests/test_app.py` file with pytest fixtures and comprehensive test cases was AI-generated.

5. **CI/CD Pipeline**: The complete GitHub Actions workflow (`.github/workflows/pipeline.yml`) including:
   - Build and test stages
   - Docker image building and pushing
   - GitOps repository updates
   - Commented smoke test example

6. **Kubernetes Manifests**: All Kubernetes resources in `gitops-repo/k8s/`:
   - Deployment with probes and security contexts
   - Service definition
   - Kustomization configuration
   - ArgoCD Application manifest

7. **Setup Automation**: The `scripts/setup-local-cluster.sh` bash script for complete local environment setup including cluster provisioning, ArgoCD installation, and application deployment.

8. **Documentation**: Both README files with comprehensive setup instructions, troubleshooting guides, and architectural explanations.

### Iteration Process

The development followed this AI-assisted workflow:

1. **Initial Prompt**: Provided detailed requirements specifying technology choices, repository structure, and expected outcomes.

2. **Code Generation**: AI generated all source files, manifests, and configuration in one iteration.

3. **Refinement Areas** (where manual iteration would occur):
   - Adjusting image registry URLs to actual Docker Hub usernames
   - Configuring GitHub secrets with real credentials
   - Fine-tuning resource limits based on actual workload
   - Customizing ArgoCD sync policies for specific needs
   - Adding custom application features beyond the demo

### Manual Adaptation Required

For production use, you would manually:

1. **Security Hardening**:
   - Use image vulnerability scanning
   - Implement proper secrets management (Sealed Secrets, External Secrets Operator)
   - Add network policies
   - Configure RBAC more restrictively

2. **Observability**:
   - Add Prometheus metrics
   - Configure logging aggregation
   - Set up distributed tracing
   - Create dashboards and alerts

3. **Reliability**:
   - Configure Horizontal Pod Autoscaler
   - Set up PodDisruptionBudgets
   - Implement backup strategies
   - Add disaster recovery procedures

4. **Multi-Environment**:
   - Create overlays for dev/staging/prod
   - Implement environment-specific configurations
   - Set up promotion workflows

### Benefits of AI Assistance

- **Speed**: Complete project scaffolding in minutes vs. hours
- **Best Practices**: AI incorporated GitOps patterns, security practices, and Kubernetes conventions
- **Completeness**: Generated comprehensive documentation and error handling
- **Consistency**: Maintained consistent code style and naming conventions
- **Learning**: Provided educational comments explaining design decisions

### Limitations & Considerations

- AI-generated code requires review for security vulnerabilities
- Configuration values (URLs, usernames) need manual updates
- Production-grade features require domain expertise to implement
- Testing in real scenarios is essential before production use

---

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize Documentation](https://kustomize.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Flask Documentation](https://flask.palletsprojects.com/)

## License

MIT License - Feel free to use this for learning and demonstrations.

---

**Questions or Issues?** Check the troubleshooting section or open an issue in the repository.
# CI/CD Test
# Demo change
# GitOps test - Wed Dec 10 20:41:12 IST 2025
