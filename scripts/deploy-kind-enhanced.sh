#!/bin/bash

# IOD V3 Backend - Enhanced Kind Deployment Script
# Comprehensive deployment automation with error handling and validation

set -e

# Configuration
CLUSTER_NAME="iodv3-cluster"
REGISTRY_NAME="iodv3-registry"
REGISTRY_PORT="5002"
NAMESPACE="iodv3-dev"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Kind is installed
    if ! command -v kind &> /dev/null; then
        log_error "Kind is not installed. Please install Kind first:"
        echo "  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64"
        echo "  chmod +x ./kind"
        echo "  sudo mv ./kind /usr/local/bin/kind"
        exit 1
    fi

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi

    log_success "All prerequisites satisfied"
}

# Function to setup local registry
setup_registry() {
    log_info "Setting up local Docker registry..."
    ./scripts/setup-registry.sh setup
}

# Function to create Kind cluster
create_cluster() {
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        log_warning "Kind cluster '${CLUSTER_NAME}' already exists"
        kubectl cluster-info --context kind-${CLUSTER_NAME}
    else
        log_info "Creating Kind cluster with multi-node configuration..."
        kind create cluster --config=k8s/kind-config.yaml --name=${CLUSTER_NAME}
        
        # Connect registry to cluster network if it exists
        if docker ps --format '{{.Names}}' | grep -q "^${REGISTRY_NAME}$"; then
            docker network connect "kind" "${REGISTRY_NAME}" || true
        fi
        
        log_success "Kind cluster '${CLUSTER_NAME}' created successfully"
    fi
}

# Function to build and tag images for local registry
build_images() {
    log_info "Building Docker images..."
    
    # Build gateway image
    log_info "Building API Gateway image..."
    docker build -t iodv3/api-gateway:dev -f gateway/Dockerfile .
    docker tag iodv3/api-gateway:dev localhost:${REGISTRY_PORT}/iodv3/api-gateway:dev
    
    # Build accounts service image
    log_info "Building Accounts Service image..."
    docker build -t iodv3/accounts-service:dev -f services/accounts/Dockerfile .
    docker tag iodv3/accounts-service:dev localhost:${REGISTRY_PORT}/iodv3/accounts-service:dev
    
    # Build blog service image
    log_info "Building Blog Service image..."
    docker build -t iodv3/blog-service:dev -f services/blog/Dockerfile .
    docker tag iodv3/blog-service:dev localhost:${REGISTRY_PORT}/iodv3/blog-service:dev
    
    log_success "All images built successfully"
}

# Function to push images to local registry
push_images() {
    log_info "Pushing images to local registry..."
    
    docker push localhost:${REGISTRY_PORT}/iodv3/api-gateway:dev
    docker push localhost:${REGISTRY_PORT}/iodv3/accounts-service:dev
    docker push localhost:${REGISTRY_PORT}/iodv3/blog-service:dev
    
    log_success "All images pushed to local registry"
}

# Function to load images into Kind cluster
load_images() {
    log_info "Loading images into Kind cluster..."
    
    kind load docker-image iodv3/api-gateway:dev --name=${CLUSTER_NAME}
    kind load docker-image iodv3/accounts-service:dev --name=${CLUSTER_NAME}
    kind load docker-image iodv3/blog-service:dev --name=${CLUSTER_NAME}
    
    log_success "All images loaded into Kind cluster"
}

# Function to deploy applications
deploy_applications() {
    log_info "Deploying applications to Kubernetes..."
    
    # Create namespace if it doesn't exist
    log_info "Creating namespace..."
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy applications
    log_info "Applying Kubernetes manifests..."
    kubectl apply -f k8s/dev/
    
    log_info "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment --all -n ${NAMESPACE}
    
    log_success "All applications deployed successfully"
}

# Function to initialize databases
init_databases() {
    log_info "Initializing databases..."
    
    # Wait for PostgreSQL to be ready
    log_info "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=ready --timeout=120s pod -l app=postgres -n ${NAMESPACE}
    
    # Initialize databases
    log_info "Creating application databases..."
    kubectl exec -n ${NAMESPACE} deployment/postgres -- psql -U postgres -c "CREATE DATABASE accounts_db;" || true
    kubectl exec -n ${NAMESPACE} deployment/postgres -- psql -U postgres -c "CREATE DATABASE blog_db;" || true
    
    log_success "Databases initialized"
}

# Function to validate deployment
validate_deployment() {
    log_info "Validating deployment..."
    
    # Check pod status
    log_info "Checking pod status..."
    kubectl get pods -n ${NAMESPACE}
    echo ""
    
    # Check service status
    log_info "Checking service status..."
    kubectl get services -n ${NAMESPACE}
    echo ""
    
    # Check if all pods are running
    if kubectl get pods -n ${NAMESPACE} --no-headers | grep -v Running | grep -v Completed; then
        log_warning "Some pods are not in Running state"
    else
        log_success "All pods are running successfully"
    fi
}

# Function to show access information
show_access_info() {
    echo ""
    log_success "🎉 IOD V3 Backend deployed successfully!"
    echo ""
    echo "📖 Access Information:"
    echo "  Cluster: ${CLUSTER_NAME}"
    echo "  Context: kind-${CLUSTER_NAME}"
    echo "  Namespace: ${NAMESPACE}"
    echo ""
    echo "🌐 Service URLs (NodePort):"
    echo "  API Gateway:     http://localhost:30000"
    echo "  Accounts Service: http://localhost:30001"
    echo "  Blog Service:    http://localhost:30002"
    echo ""
    echo "🧪 Quick Test Commands:"
    echo "  curl http://localhost:30000/health"
    echo "  curl http://localhost:30001/health"
    echo "  curl http://localhost:30002/health"
    echo ""
    echo "📋 Useful Commands:"
    echo "  kubectl get pods -n ${NAMESPACE}"
    echo "  kubectl logs -f deployment/gateway -n ${NAMESPACE}"
    echo "  kubectl logs -f deployment/accounts-service -n ${NAMESPACE}"
    echo "  kubectl logs -f deployment/blog-service -n ${NAMESPACE}"
    echo ""
    echo "🧹 Cleanup:"
    echo "  ./scripts/deploy-kind-enhanced.sh cleanup"
    echo "  # or"
    echo "  make kind-clean"
}

# Function to cleanup deployment
cleanup_deployment() {
    log_info "Cleaning up IOD V3 deployment..."
    
    # Delete Kind cluster
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        log_info "Deleting Kind cluster: ${CLUSTER_NAME}"
        kind delete cluster --name=${CLUSTER_NAME}
    else
        log_warning "Kind cluster ${CLUSTER_NAME} not found"
    fi
    
    # Cleanup registry
    log_info "Cleaning up local registry..."
    ./scripts/setup-registry.sh cleanup
    
    # Clean up Docker images
    log_info "Cleaning up Docker images..."
    docker image prune -f --filter label=io.x-k8s.kind.cluster=${CLUSTER_NAME} || true
    
    log_success "Cleanup completed successfully"
}

# Function to show cluster status
show_status() {
    echo "📊 IOD V3 Cluster Status:"
    echo ""
    
    # Check if cluster exists
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        log_success "Cluster '${CLUSTER_NAME}' is running"
        
        # Show cluster info
        kubectl cluster-info --context kind-${CLUSTER_NAME}
        echo ""
        
        # Show namespace resources
        if kubectl get namespace ${NAMESPACE} &> /dev/null; then
            echo "Resources in '${NAMESPACE}' namespace:"
            kubectl get all -n ${NAMESPACE}
        else
            log_warning "Namespace '${NAMESPACE}' not found"
        fi
    else
        log_warning "Cluster '${CLUSTER_NAME}' not found"
    fi
    
    echo ""
    # Check registry status
    ./scripts/setup-registry.sh status
}

# Main deployment function
main() {
    log_info "🚀 Starting IOD V3 Backend deployment with Kind..."
    
    check_prerequisites
    setup_registry
    create_cluster
    build_images
    load_images
    deploy_applications
    init_databases
    validate_deployment
    show_access_info
}

# Parse command line arguments
case "${1:-deploy}" in
    "deploy"|"")
        main
        ;;
    "cleanup"|"clean")
        cleanup_deployment
        ;;
    "status")
        show_status
        ;;
    "build-only")
        check_prerequisites
        build_images
        load_images
        log_success "Images built and loaded successfully"
        ;;
    "help"|"--help"|"-h")
        echo "Usage: $0 [deploy|cleanup|status|build-only|help]"
        echo "  deploy     - Deploy the full IOD V3 stack (default)"
        echo "  cleanup    - Remove Kind cluster, registry, and resources"
        echo "  status     - Show cluster and deployment status"
        echo "  build-only - Build and load images only"
        echo "  help       - Show this help message"
        ;;
    *)
        log_error "Invalid command. Use: deploy, cleanup, status, build-only, or help"
        exit 1
        ;;
esac
