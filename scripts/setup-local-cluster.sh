#!/bin/bash

################################################################################
# Local Kind Cluster & ArgoCD Setup Script
################################################################################
# This script sets up a complete local development environment with:
# - Kind cluster with proper port mappings
# - ArgoCD for GitOps deployment
# - Demo Flask application deployed via ArgoCD
#
# Usage: ./setup-local-cluster.sh [cluster-name]
# Default cluster name: gitops-demo
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="${1:-gitops-demo}"
ARGOCD_VERSION="stable"
GITOPS_REPO="https://github.com/banicr/demo_gitops.git"
APP_MANIFEST_PATH="../demo_gitops/argocd-application.yaml"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        echo ""
        case "$1" in
            kind)
                echo "Install kind: brew install kind"
                echo "Or visit: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
                ;;
            kubectl)
                echo "Install kubectl: brew install kubectl"
                echo "Or visit: https://kubernetes.io/docs/tasks/tools/"
                ;;
            docker)
                echo "Install Docker Desktop: https://www.docker.com/products/docker-desktop"
                ;;
        esac
        exit 1
    fi
}

wait_for_pods() {
    local namespace=$1
    local label=$2
    local timeout=${3:-300}
    
    print_info "Waiting for pods with label $label in namespace $namespace..."
    
    # First wait for pods to exist
    local count=0
    while [[ $count -lt 60 ]]; do
        if kubectl get pods -n "$namespace" -l "$label" 2>/dev/null | grep -q .; then
            break
        fi
        sleep 2
        ((count++))
    done
    
    # Then wait for pods to be ready
    if kubectl wait --for=condition=ready pod -l "$label" -n "$namespace" --timeout="${timeout}s" 2>&1 | grep -v "no matching resources found"; then
        print_success "Pods are ready"
        return 0
    else
        print_warning "Some pods may not be ready yet. Continuing..."
        return 0
    fi
}

################################################################################
# Main Setup Functions
################################################################################

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    check_command "docker"
    check_command "kind"
    check_command "kubectl"
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

cleanup_existing_cluster() {
    print_header "Checking for Existing Cluster"
    
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        print_warning "Cluster '${CLUSTER_NAME}' already exists"
        read -p "Do you want to delete it and start fresh? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deleting existing cluster..."
            kind delete cluster --name "${CLUSTER_NAME}"
            print_success "Cluster deleted"
        else
            print_info "Using existing cluster"
            return 1
        fi
    fi
    return 0
}

create_kind_cluster() {
    print_header "Creating Kind Cluster: ${CLUSTER_NAME}"
    
    print_info "Creating cluster with port mappings..."
    cat <<EOF | kind create cluster --name "${CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  # NodePort for application access
  - containerPort: 30080
    hostPort: 8000
    protocol: TCP
  # Additional port for future services
  - containerPort: 30443
    hostPort: 8443
    protocol: TCP
EOF
    
    print_success "Kind cluster '${CLUSTER_NAME}' created successfully"
    
    # Verify cluster
    kubectl cluster-info --context "kind-${CLUSTER_NAME}"
    print_success "Kubectl context set to: kind-${CLUSTER_NAME}"
}

install_argocd() {
    print_header "Installing ArgoCD"
    
    # Create namespace
    print_info "Creating argocd namespace..."
    kubectl create namespace argocd
    
    # Install ArgoCD
    print_info "Installing ArgoCD ${ARGOCD_VERSION}..."
    kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
    
    # Wait for ArgoCD pods to be ready
    print_info "Waiting for ArgoCD components to be ready (this may take 2-3 minutes)..."
    print_info "Pulling container images and initializing pods..."
    
    # Wait for server pod specifically
    wait_for_pods "argocd" "app.kubernetes.io/name=argocd-server" 300
    
    # Check status of all ArgoCD pods
    print_info "Checking all ArgoCD components..."
    kubectl get pods -n argocd
    
    print_success "ArgoCD installed successfully"
}

get_argocd_password() {
    print_header "ArgoCD Credentials"
    
    local password
    password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ArgoCD Login Credentials${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "  Username: ${YELLOW}admin${NC}"
    echo -e "  Password: ${YELLOW}${password}${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}\n"
    
    # Save to file for reference
    cat > argocd-credentials.txt <<EOF
ArgoCD Credentials
==================
Username: admin
Password: ${password}

Access ArgoCD UI:
-----------------
1. Port forward: kubectl port-forward svc/argocd-server -n argocd 8080:443
2. Open browser: https://localhost:8080
3. Accept self-signed certificate warning
4. Login with credentials above

Note: Keep this file secure and don't commit it to git!
EOF
    
    print_success "Credentials saved to: argocd-credentials.txt"
}



deploy_application() {
    print_header "Deploying Application with Helm"
    
    local helm_chart_path="../demo_gitops/helm/demo-flask-app"
    
    # Build and load image
    IMAGE_TAG="local-dev"
    print_info "Building image: demo-flask-app:${IMAGE_TAG}"
    docker build --build-arg APP_VERSION=${IMAGE_TAG} -t demo-flask-app:${IMAGE_TAG} .
    
    print_info "Loading image into cluster..."
    kind load docker-image demo-flask-app:${IMAGE_TAG} --name ${CLUSTER_NAME}
    
    # Create namespace
    kubectl create namespace demo-app --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null
    
    # Deploy with Helm
    print_info "Deploying with Helm..."
    helm upgrade --install demo-flask-app "$helm_chart_path" \
        --namespace demo-app \
        --set image.repository=demo-flask-app \
        --set image.tag=${IMAGE_TAG} \
        --set image.pullPolicy=Never \
        --set securityContext.readOnlyRootFilesystem=false
    
    print_success "Deployed! Checking status..."
    sleep 3
    kubectl get pods -n demo-app
}



print_next_steps() {
    print_header "Setup Complete! 🎉"
    
    echo -e "${GREEN}✅ Cluster: ${CLUSTER_NAME}${NC}"
    echo -e "${GREEN}✅ App deployed in namespace: demo-app${NC}"
    echo ""
    echo -e "${BLUE}Access app:${NC} make port-forward"
    echo -e "${BLUE}Cleanup:${NC} make clean"
}

################################################################################
# Main Execution
################################################################################

main() {
    echo -e "${BLUE}"
    cat <<'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        Local GitOps Environment Setup Script                 ║
║        Kind + ArgoCD + Demo Flask Application                ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_prerequisites
    
    if cleanup_existing_cluster; then
        create_kind_cluster
        install_argocd
        get_argocd_password
    else
        print_info "Skipping cluster creation, using existing cluster"
        # Verify ArgoCD is installed
        if ! kubectl get namespace argocd &> /dev/null; then
            print_warning "ArgoCD namespace not found in existing cluster"
            read -p "Do you want to install ArgoCD? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                install_argocd
                get_argocd_password
            fi
        else
            print_success "ArgoCD is already installed"
        fi
    fi
    
    deploy_application
    print_next_steps
}

# Run main function
main "$@"
