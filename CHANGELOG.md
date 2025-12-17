# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive health check endpoints (`/healthz/live`, `/healthz/ready`)
- System resource monitoring (memory, disk usage) in readiness probe
- NetworkPolicy for network segmentation
- PodDisruptionBudget for high availability
- Graceful shutdown configuration (45s termination grace period)
- Trivy vulnerability scanning in CI/CD pipeline
- Test coverage reporting with Codecov integration
- Error handlers for 404 and 500 responses
- Pull request workflow trigger
- Dependabot configuration for automated dependency updates
- Makefile for common development commands
- Automated rollback mechanism (optional, requires cluster access)
- `app/__init__.py` for proper Python package structure

### Changed
- Pinned all GitHub Actions to specific commit SHAs for supply chain security
- Replaced `sed` with `yq` for YAML manipulation
- Updated E2E tests to use production Helm chart instead of inline YAML
- Separated liveness and readiness probes
- Increased resource limits (512Mi memory, 1000m CPU)
- Fixed pylint to fail on errors (removed `|| true`)
- Added concurrency control to prevent race conditions in GitOps updates
- Added timeout protection to all CI/CD jobs
- Enabled ServiceAccount creation in Helm chart
- Updated branch strategy to only build on main and pull requests
- Docker images only pushed on main branch, not on PRs
- Removed develop branch from triggers to prevent unused builds

### Fixed
- Race condition in concurrent GitOps updates
- Runaway jobs consuming unlimited GitHub Actions minutes
- Credentials file already protected in .gitignore
- Trailing comment cleanup in main.py

### Security
- All GitHub Actions pinned to specific SHA commits
- Container image vulnerability scanning with Trivy
- Network policies implemented for zero-trust networking
- ServiceAccount enabled for least-privilege principle
- Graceful shutdown prevents request drops during pod termination

## [1.0.0] - 2025-12-17

### Added
- Initial release
- Flask application with health check endpoint
- GitHub Actions CI/CD pipeline
- ArgoCD GitOps integration
- Helm chart for Kubernetes deployment
- Docker containerization with multi-stage build
- Unit tests with pytest
- Code quality checks (flake8, pylint)
- E2E testing with Kind cluster
- Comprehensive documentation

[Unreleased]: https://github.com/banicr/demo_app/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/banicr/demo_app/releases/tag/v1.0.0
