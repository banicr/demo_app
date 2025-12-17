# Prompts to Rebuild This Project

This document contains prompts to recreate this entire GitOps demo project from scratch. Follow these prompts in order to build the complete setup.

## Prerequisites Setup

### Prompt 1: Verify Environment
```
I want to create a GitOps demo with Flask, Docker, Kubernetes, and ArgoCD.
Check if I have the following installed:
- Git
- Docker
- kind (Kubernetes in Docker)
- kubectl
- Python 3.11+

If any are missing, provide installation commands for my OS.
```

## Building from Scratch

Use these prompts in exact order to recreate the entire project:

### Step 1: Create GitHub Repositories
```
Create two new GitHub repositories:
1. Repository name: demo_app
   - Description: GitOps demo - Flask application
   - Visibility: Public
   - Initialize with README: Yes

2. Repository name: demo_gitops
   - Description: GitOps demo - Kubernetes deployment manifests
   - Visibility: Public
   - Initialize with README: Yes

Clone both repositories to my local machine in the same parent directory.
Use GitHub username: banicr
Use email: bhavani.cr831@gmail.com
```

### Step 2: Create Flask Application Structure
```
In the demo_app repository, create a Flask web application with this structure:
- app/main.py - Flask app with two endpoints:
  - / (root) - Returns HTML page showing "Flask App Version: 2.0.0"
  - /healthz - Returns JSON {"status": "healthy"}
- tests/test_app.py - Pytest tests for both endpoints
- requirements.txt - Flask dependency
- requirements-test.txt - pytest dependency
- Dockerfile - Multi-stage build with Python 3.11, non-root user, port 5000
- .gitignore - Standard Python gitignore (venv, __pycache__, *.pyc, .pytest_cache)

Make it simple and production-ready.
```

### Step 3: Create GitHub Actions CI/CD Pipeline
```
Create .github/workflows/pipeline.yml in demo_app with 4 jobs:

Job 1 - Test:
- Run on: ubuntu-latest
- Steps: Checkout, setup Python 3.11, install dependencies, run pytest
- Must pass before next jobs

Job 2 - Build:
- Depends on test job
- Login to GitHub Container Registry (GHCR)
- Build Docker image
- Tag format: v2.0.0-{short-sha}-{run-number}
- Push to ghcr.io/banicr/demo-flask-app:{tag}
- Also tag as latest
- Output the tag for next jobs

Job 3 - E2E Test:
- Depends on build job
- Create temporary kind cluster
- Load the built Docker image into kind
- Apply Kubernetes manifests (deployment, service)
- Wait for pod to be ready
- Test the /healthz endpoint
- Delete the kind cluster
- Use image tag from build job

Job 4 - Update GitOps:
- Depends on e2e-test job
- Checkout demo_gitops repo using SSH deploy key
- Update helm/demo-flask-app/values.yaml:
  - image.tag: {new-tag}
  - env.appVersion: {new-tag}
- Commit with message: "Update image to {tag}"
- Push to main branch
- Use SSH key from secret: GITOPS_REPO_SSH_KEY

Keep it simple and well-commented.
```

### Step 4: Create Kubernetes Manifests for E2E Testing
```
In demo_app repository, create kubernetes-manifests/ directory for E2E testing:
- deployment.yaml:
  - 1 replica (for testing)
  - Container port 5000
  - Liveness probe on /healthz
  - Readiness probe on /healthz
  - Resource limits: 100m CPU, 128Mi memory
  - Security context: non-root user
  - Pull policy: Never (for kind)
  
- service.yaml:
  - Type: ClusterIP
  - Port 80 to targetPort 5000

Use namespace: default (for E2E testing)
```

### Step 5: Create Helm Chart in GitOps Repository
```
In demo_gitops repository, create a Helm chart at helm/demo-flask-app/:

Chart.yaml:
- name: demo-flask-app
- version: 1.0.0
- appVersion: "2.0.0"

values.yaml:
- image.repository: ghcr.io/banicr/demo-flask-app
- image.tag: v2.0.0-initial-0
- image.pullPolicy: Always
- replicaCount: 2
- service.type: ClusterIP
- service.port: 80
- resources.limits: cpu 100m, memory 128Mi
- resources.requests: cpu 50m, memory 64Mi
- env.appVersion: v2.0.0-initial-0

templates/:
- deployment.yaml - Use values from values.yaml, add probes, security context
- service.yaml - ClusterIP service
- serviceaccount.yaml - Dedicated service account
- _helpers.tpl - Standard Helm helpers

Make it production-ready with proper labels and annotations.
```

### Step 6: Create ArgoCD Application Manifest
```
In demo_gitops repository, create argocd-application.yaml:
- Application name: demo-flask-app
- Project: default
- Source:
  - repoURL: https://github.com/banicr/demo_gitops
  - targetRevision: main
  - path: helm/demo-flask-app
- Destination:
  - server: https://kubernetes.default.svc
  - namespace: demo-app
- syncPolicy:
  - automated: true
  - prune: true
  - selfHeal: true
  - syncOptions: CreateNamespace=true

Include comments explaining each section.
```

### Step 7: Create Local Setup Script
```
In demo_app/scripts/, create setup-local-cluster.sh bash script that:

1. Checks if kind is installed
2. Creates kind cluster named "gitops-demo" if not exists
3. Installs ArgoCD in argocd namespace using official manifests
4. Waits for ArgoCD server to be ready
5. Gets ArgoCD initial admin password
6. Creates demo-app namespace
7. Applies argocd-application.yaml from demo_gitops repo
   - Assumes demo_gitops is at ../../demo_gitops/
8. Waits for application to be healthy
9. Prints success messages with instructions:
   - How to access the app (port-forward)
   - How to access ArgoCD dashboard
   - ArgoCD admin password

Make it robust with error checking and clear output messages.
```

### Step 8: Set Up GitHub Secrets
```
Guide me to set up the GITOPS_REPO_SSH_KEY secret in demo_app repository:
1. Generate SSH key pair
2. Add public key as deploy key in demo_gitops repo (with write access)
3. Add private key as secret in demo_app repo
4. Name it: GITOPS_REPO_SSH_KEY

Provide exact commands for macOS.
```

### Step 9: Create Documentation
```
Create these documentation files in demo_app repository:

README.md:
- Project overview (simple explanation of GitOps demo)
- Quick start (3-4 simple steps)
- Architecture overview (brief)
- How it works (CI/CD stages explained simply)
- Local testing instructions
- Access instructions
- Link to other documentation files

ARCHITECTURE.md:
- System architecture diagram (ASCII art)
- CI/CD pipeline flow diagram
- GitOps deployment flow diagram
- Repository structures
- Technology stack
- Key concepts (GitOps principles, zero-downtime)

SETUP_GUIDE.md:
- Prerequisites with installation commands
- Step-by-step setup for new users
- How to test locally
- How to make changes and see them deploy
- Troubleshooting common issues
- Cleanup instructions

REBUILD_PROMPTS.md:
- All the prompts needed to recreate this project
- Organized by phase
- Include tips and best practices

Keep all documentation simple, clear, and beginner-friendly.
```

### Step 10: Test the Complete Setup
```
Test the entire setup end-to-end:
1. Run setup-local-cluster.sh
2. Verify ArgoCD dashboard is accessible
3. Verify application is deployed and healthy
4. Make a code change (update version in main.py)
5. Push to GitHub
6. Watch GitHub Actions pipeline
7. Verify demo_gitops values.yaml gets updated
8. Watch ArgoCD sync the change
9. Verify new version is running

Guide me through testing and troubleshooting any issues.
```

## Advanced Configuration Prompts

### Customize Flask Application
```
Modify the Flask application to:
- Add a new endpoint /info that returns JSON with:
  - app_name: "Demo Flask App"
  - version: (from environment variable)
  - timestamp: current UTC time
- Add tests for the new endpoint
- Update documentation
```

### Add More CI/CD Features
```
Enhance the GitHub Actions pipeline:
- Add code linting (flake8 or pylint)
- Add code coverage reporting
- Add security scanning (trivy for container images)
- Add Slack notifications on failure
- Add manual approval step before GitOps update
```

### Configure ArgoCD Notifications
```
Set up ArgoCD to send notifications:
- When sync starts
- When sync completes
- When sync fails
- When app becomes unhealthy
Send to Slack or email
```

### Add Monitoring
```
Add Prometheus monitoring to the Flask app:
- Add /metrics endpoint
- Track request count, response time
- Create ServiceMonitor for Prometheus
- Update Helm chart with monitoring configuration
```

## Troubleshooting Prompts

### Python Environment Issues
```
I'm getting "command not found: python" or "externally-managed-environment" error on macOS.
Help me set up a Python virtual environment and install dependencies properly.
```

### GitHub Actions Failures
```
My GitHub Actions pipeline is failing at the [test/build/e2e/update] stage with error:
[paste error message]

Help me debug and fix this issue.
```

### Docker Image Issues
```
I'm getting authentication errors when pushing to GHCR:
[paste error message]

Guide me to set up GitHub Container Registry permissions correctly.
```

### Kind Cluster Issues
```
The kind cluster is not starting or pods are not running with error:
[paste error message]

Help me troubleshoot and fix the cluster.
```

### ArgoCD Sync Issues
```
ArgoCD is not syncing changes or showing as OutOfSync:
- Application status: [status]
- Last sync: [timestamp]
- Error message: [if any]

Help me troubleshoot why ArgoCD isn't syncing.
```

### SSH Deploy Key Issues
```
The update-gitops job is failing with SSH authentication error:
[paste error message]

Help me set up the SSH deploy key correctly.
```

### Application Not Accessible
```
I can't access the application at localhost:8080 after port-forwarding.
Pods status: [paste kubectl get pods output]
Help me troubleshoot.
```

## Tips for Using These Prompts

1. **Be Specific**: Include exact paths, names, and URLs
2. **One Step at a Time**: Don't try to build everything in one prompt
3. **Iterate**: Start simple, then add complexity
4. **Test Between Steps**: Verify each component works before moving on
5. **Document Decisions**: Note why you chose certain approaches
6. **Keep it Simple**: Avoid over-engineering the solution

## Common Patterns

### When Creating New Features
```
Add [feature name] to the application that:
- Does [specific functionality]
- Includes tests
- Updates documentation
- Follows existing patterns
```

### When Fixing Issues
```
I'm encountering [specific error message].
The issue occurs when [describe scenario].
Current configuration: [relevant details]
```

### When Refactoring
```
Refactor [component name] to:
- Improve [specific aspect]
- Maintain existing functionality
- Keep tests passing
- Update documentation
```

## Complete Recreation Checklist

Follow this checklist to recreate the entire project from scratch:

### Phase 1: Repository Setup
- [ ] Verify prerequisites installed (Git, Docker, kind, kubectl, Python 3.11+)
- [ ] Create demo_app GitHub repository (public, with README)
- [ ] Create demo_gitops GitHub repository (public, with README)
- [ ] Clone both repositories to local machine (same parent directory)
- [ ] Configure Git with username: banicr and email: bhavani.cr831@gmail.com

### Phase 2: Application Development
- [ ] Create Flask app structure (app/main.py with / and /healthz endpoints)
- [ ] Create tests (tests/test_app.py with pytest)
- [ ] Create requirements.txt (Flask)
- [ ] Create requirements-test.txt (pytest)
- [ ] Create Dockerfile (Python 3.11, non-root, multi-stage)
- [ ] Create .gitignore (Python standard)
- [ ] Test locally: pytest passes, app runs on localhost:5000
- [ ] Commit and push to demo_app main branch

### Phase 3: CI/CD Pipeline
- [ ] Create .github/workflows/pipeline.yml with 4 jobs
- [ ] Job 1: Test (pytest)
- [ ] Job 2: Build (Docker image to GHCR, tag: v2.0.0-{sha}-{run})
- [ ] Job 3: E2E Test (kind cluster, test deployment)
- [ ] Job 4: Update GitOps (modify demo_gitops values.yaml)
- [ ] Create kubernetes-manifests/ for E2E testing (deployment, service)
- [ ] Test pipeline: push code, watch GitHub Actions
- [ ] Verify GHCR package is created

### Phase 4: GitOps Repository
- [ ] Create helm/demo-flask-app/Chart.yaml
- [ ] Create helm/demo-flask-app/values.yaml (image config, replicas, resources)
- [ ] Create helm/demo-flask-app/templates/deployment.yaml
- [ ] Create helm/demo-flask-app/templates/service.yaml
- [ ] Create helm/demo-flask-app/templates/serviceaccount.yaml
- [ ] Create helm/demo-flask-app/templates/_helpers.tpl
- [ ] Create argocd-application.yaml (auto-sync, prune, self-heal)
- [ ] Commit and push to demo_gitops main branch

### Phase 5: Local Setup
- [ ] Create demo_app/scripts/setup-local-cluster.sh
- [ ] Script creates kind cluster: gitops-demo
- [ ] Script installs ArgoCD in argocd namespace
- [ ] Script waits for ArgoCD to be ready
- [ ] Script creates demo-app namespace
- [ ] Script applies argocd-application.yaml from demo_gitops
- [ ] Script shows access instructions and ArgoCD password
- [ ] Test script: ./setup-local-cluster.sh runs successfully
- [ ] Make script executable: chmod +x setup-local-cluster.sh

### Phase 6: SSH Deploy Key Configuration
- [ ] Generate SSH key pair: ssh-keygen -t ed25519 -C "github-actions"
- [ ] Add public key to demo_gitops as deploy key (Settings → Deploy keys, with write access)
- [ ] Add private key to demo_app as secret: GITOPS_REPO_SSH_KEY (Settings → Secrets → Actions)
- [ ] Test: Trigger GitHub Actions, verify update-gitops job succeeds

### Phase 7: Documentation
- [ ] Create demo_app/README.md (overview, quick start, how it works)
- [ ] Create demo_app/ARCHITECTURE.md (diagrams, flow charts, tech stack)
- [ ] Create demo_app/SETUP_GUIDE.md (step-by-step for new users)
- [ ] Create demo_app/REBUILD_PROMPTS.md (prompts to recreate project)
- [ ] Update demo_gitops/README.md (simple explanation)
- [ ] Verify all links work
- [ ] Verify all code examples are correct

### Phase 8: End-to-End Testing
- [ ] Start fresh: delete kind cluster if exists
- [ ] Run: cd demo_app/scripts && ./setup-local-cluster.sh
- [ ] Verify: ArgoCD dashboard accessible (port 8081)
- [ ] Verify: Application accessible (port 8080)
- [ ] Verify: ArgoCD shows app as "Healthy" and "Synced"
- [ ] Make code change: update version in app/main.py
- [ ] Commit and push to demo_app
- [ ] Watch: GitHub Actions pipeline (4 stages pass)
- [ ] Watch: demo_gitops values.yaml gets updated
- [ ] Watch: ArgoCD detects change and syncs (within 3 min)
- [ ] Verify: New version running in cluster
- [ ] Test rollback: manually revert values.yaml, watch ArgoCD sync

### Phase 9: Final Verification
- [ ] Clone both repos to fresh directory
- [ ] Follow SETUP_GUIDE.md from scratch
- [ ] Verify everything works for a new user
- [ ] Fix any issues found
- [ ] Update documentation as needed
- [ ] Commit and push all final changes

### Phase 10: Optional Enhancements
- [ ] Add code linting to CI pipeline
- [ ] Add security scanning (trivy)
- [ ] Add monitoring (Prometheus metrics)
- [ ] Add ArgoCD notifications
- [ ] Add multiple environments (dev, staging, prod)
- [ ] Add manual approval gates
- [ ] Update documentation with new features
