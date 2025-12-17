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
│  1. Test        → Run pytest unit tests                        │
│  2. Build       → Build Docker image                           │
│  3. E2E Test    → Test in temporary kind cluster               │
│  4. Update      → Update demo_gitops repo                      │
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
│                    Stage 1: Test                                │
├─────────────────────────────────────────────────────────────────┤
│  • Run pytest unit tests                                        │
│  • Test /healthz endpoint                                       │
│  • Test / main page                                             │
│  • Validate HTTP responses                                      │
│  ❌ If fails → Stop pipeline                                    │
│  ✅ If passes → Continue                                        │
└──────┬──────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Stage 2: Build                                │
├─────────────────────────────────────────────────────────────────┤
│  • Generate tag: v2.0.0-{sha}-{run}                            │
│  • Build Docker image                                           │
│  • Push to ghcr.io/banicr/demo-flask-app:{tag}                │
│  • Tag as latest                                                │
│  • Pass tag to next stage                                       │
└──────┬──────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Stage 3: E2E Test                              │
├─────────────────────────────────────────────────────────────────┤
│  • Create temporary kind cluster                                │
│  • Load Docker image into cluster                               │
│  • Deploy app with manifests                                    │
│  • Wait for pods to be ready                                    │
│  • Test /healthz endpoint                                       │
│  • Verify app works                                             │
│  • Delete cluster                                               │
│  ❌ If fails → Stop pipeline                                    │
│  ✅ If passes → Continue                                        │
└──────┬──────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────┐
│               Stage 4: Update GitOps                            │
├─────────────────────────────────────────────────────────────────┤
│  • Clone demo_gitops repo                                       │
│  • Update helm/demo-flask-app/values.yaml:                     │
│    - image.tag: new version                                     │
│    - env.appVersion: new version                                │
│  • Run Helm lint --strict (pre-validation)                      │
│  • Render and validate Helm templates                           │
│  • If validation passes → Push directly to main                 │
│  • If validation fails → Pipeline fails (no push)               │
│  • ArgoCD detects change and deploys (~10-20 sec)               │
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
