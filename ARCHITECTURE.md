# Architecture

Simple overview of how code gets from your laptop to Kubernetes.

## Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         Developer                               │
│                      (writes code)                              │
└──────────────────────────┬──────────────────────────────────────┘
                           │ git push
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub: demo_app                             │
│                  (application source code)                      │
└──────────────────────────┬──────────────────────────────────────┘
                           │ triggers
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   GitHub Actions Pipeline                       │
├─────────────────────────────────────────────────────────────────┤
│  1. Lint        → flake8 + pylint (--fail-under=8.0)          │
│  2. Test        → pytest with 70% coverage                     │
│  3. Build       → Docker + Trivy scan                          │
│  4. E2E Test    → Deploy with Helm in kind cluster            │
│  5. Update      → Update demo_gitops                   │
└──────────────────────────┬──────────────────────────────────────┘
                           │ pushes image
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│              GitHub Container Registry (GHCR)                   │
│         ghcr.io/banicr/demo-flask-app:{tag}                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           │ commits changes
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   GitHub: demo_gitops                           │
│              (Kubernetes deployment manifests)                  │
│               helm/demo-flask-app/values.yaml                   │
└──────────────────────────┬──────────────────────────────────────┘
                           │ monitors (every 3 min)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                        ArgoCD                                   │
│                  (GitOps Controller)                            │
│              - Detects changes in Git                           │
│              - Applies to cluster                               │
└──────────────────────────┬──────────────────────────────────────┘
                           │ syncs
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                           │
│                      (kind cluster)                             │
├─────────────────────────────────────────────────────────────────┤
│  Namespace: demo-app                                            │
│    - Deployment (2 replicas)                                    │
│    - Service (ClusterIP)                                        │
│    - Pods running Flask app                                     │
└─────────────────────────────────────────────────────────────────┘
```

## CI/CD Pipeline Flow

```
┌─────────────┐
│  Git Push   │
│  to main    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Stage 1: Lint                                │
├─────────────────────────────────────────────────────────────────┤
│  • Run flake8 (style checks)                                    │
│  • Run pylint --fail-under=8.0 (quality checks)                │
│  • Timeout: 10 minutes                                          │
│  ❌ If fails → Stop pipeline                                    │
│  ✅ If passes → Continue                                        │
└──────┬──────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Stage 2: Test                                │
├─────────────────────────────────────────────────────────────────┤
│  • Run pytest with coverage (--cov-fail-under=70)               │
│  • Upload coverage to Codecov                                   │
│  • Test all endpoints (/healthz/live, /healthz/ready)          │
│  • Timeout: 10 minutes                                          │
│  ❌ If fails → Stop pipeline                                    │
│  ✅ If passes → Continue                                        │
└──────┬──────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Stage 3: Build                                │
├─────────────────────────────────────────────────────────────────┤
│  • Generate tag: {sha}-{run} (e.g., a1b2c3d-42)                │
│  • Build Docker image (multi-platform: amd64, arm64)            │
│  • Push to ghcr.io/banicr/demo-flask-app:{tag}                │
│  • Run Trivy vulnerability scan (CRITICAL, HIGH)                │
│  • Upload SARIF to GitHub Security                              │
│  • Tag as latest                                                │
│  • Timeout: 20 minutes                                          │
│  ❌ If vulnerabilities → Stop pipeline                          │
│  ✅ If clean → Continue                                         │
└──────┬──────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Stage 4: E2E Test                              │
├─────────────────────────────────────────────────────────────────┤
│  • Clone demo_gitops repo (to get Helm chart)                   │
│  • Create temporary kind cluster                                │
│  • Load Docker image into cluster                               │
│  • Deploy with Helm chart                  │
│  • Wait for pods to be ready                                    │
│  • Test /healthz/live endpoint                                  │
│  • Test /healthz/ready endpoint (with health checks)            │
│  • Test / root endpoint                                         │
│  • Delete cluster (cleanup)                                     │
│  • Timeout: 30 minutes                                          │
│  ❌ If fails → Stop pipeline                                    │
│  ✅ If passes → Continue                                        │
└──────┬──────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│               Stage 5: Update GitOps                            │
├─────────────────────────────────────────────────────────────────┤
│  • Clone demo_gitops repo (with GITOPS_PAT)                     │
│  • Install yq (YAML processor)                                  │
│  • Update helm/demo-flask-app/values.yaml              │
│    - .image.tag = new version                                   │
│    - .env.appVersion = new version                              │
│  • Run Helm lint --strict (validation)                          │
│  • Render and validate Helm templates                           │
│  • git pull --rebase (prevent race conditions)                  │
│  • Commit with metadata (image, SHA, pipeline URL)              │
│  • Push to main                                                 │
│  • Timeout: 10 minutes                                          │
│  • Only runs on: push to main (not PRs)                         │
└─────────────────────────────────────────────────────────────────┘
```

## GitOps Deployment Flow

```
┌─────────────────┐
│  demo_gitops    │
│  values.yaml    │
│  updated        │
└────────┬────────┘
         │
         │ (polls every 3 min)
         ▼
┌─────────────────┐
│     ArgoCD      │
│   detects       │
│   change        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    ArgoCD       │
│    compares     │
│   Git vs        │
│   Cluster       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    ArgoCD       │
│    applies      │
│    changes      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Kubernetes    │
│   creates new   │
│   ReplicaSet    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Rolling       │
│   Update        │
│   (zero down)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   New pods      │
│   running       │
│   Old pods      │
│   terminated    │
└─────────────────┘
```

## Repository Structure

### demo_app (Application Repository)

```
demo_app/
├── app/
│   ├── __init__.py
│   └── main.py              # Flask application
├── tests/
│   ├── __init__.py
│   └── test_app.py          # Unit tests
├── scripts/
│   └── setup-local-cluster.sh  # Setup script
├── .github/
│   └── workflows/
│       └── pipeline.yml     # CI/CD pipeline
├── Dockerfile               # Container image
├── requirements.txt         # Python dependencies
├── requirements-test.txt    # Test dependencies
└── README.md
```

### demo_gitops (Deployment Repository)

```
demo_gitops/
├── helm/
│   └── demo-flask-app/
│       ├── Chart.yaml       # Helm chart metadata
│       ├── values.yaml      # Configuration (updated by CI)
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           └── serviceaccount.yaml
├── argocd-application.yaml  # ArgoCD config
└── README.md
```

## Technology Stack

### Development
- **Language**: Python 3.11+
- **Framework**: Flask
- **Testing**: pytest
- **Container**: Docker

### CI/CD
- **Pipeline**: GitHub Actions
- **Container Registry**: GitHub Container Registry (GHCR)
- **Authentication**: SSH Deploy Keys

### Deployment
- **Kubernetes**: kind (Kubernetes in Docker)
- **GitOps**: ArgoCD
- **Package Manager**: Helm
- **Namespace**: demo-app

### Repositories
- **Application**: github.com/banicr/demo_app
- **Deployment**: github.com/banicr/demo_gitops

## Key Concepts

### GitOps Principles
1. **Declarative** - Everything defined as code
2. **Versioned** - All changes tracked in Git
3. **Immutable** - New versions, not modifications
4. **Automated** - ArgoCD handles deployment
5. **Auditable** - Git history shows all changes

### Zero-Downtime Deployment
1. ArgoCD creates new ReplicaSet
2. New pods start alongside old pods
3. Once new pods are ready, traffic shifts
4. Old pods are terminated
5. No service interruption

### Security
- Non-root containers
- Read-only root filesystem capability
- Security context with dropped capabilities
- Image pull from authenticated registry
- SSH key authentication for GitOps updates
