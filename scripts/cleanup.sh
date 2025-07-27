#!/bin/bash

# IOD V3 Backend - Comprehensive Cleanup Script
# This script provides complete cleanup for all deployment types and resources

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default cluster name
CLUSTER_NAME="iodv3-cluster"

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to cleanup Kind cluster
cleanup_kind_cluster() {
    log_info "Cleaning up Kind cluster..."
    
    if command_exists kind; then
        # Check for IOD V3 related clusters
        CLUSTERS=$(kind get clusters | grep -E "(iodv3|fastapi)")
        if [ -n "$CLUSTERS" ]; then
            echo "$CLUSTERS" | while read -r cluster_name; do
                log_info "Deleting Kind cluster: $cluster_name"
                
                # This automatically deletes:
                # - All cluster nodes (control-plane + workers)
                # - All Kubernetes resources in the cluster
                # - All pods, services, ingresses, etc.
                # - All persistent volumes
                # - All network configurations
                kind delete cluster --name="$cluster_name"
                log_success "Kind cluster '$cluster_name' deleted successfully (including all nodes and resources)"
            done
        else
            log_warning "No IOD V3 related Kind clusters found"
        fi
    else
        log_warning "Kind not installed, skipping cluster cleanup"
    fi
}

# Function to cleanup Docker registry
cleanup_docker_registry() {
    log_info "Cleaning up local Docker registry..."
    
    if command_exists docker; then
        # Check if registry container exists
        if docker ps -a | grep -q "kind-registry"; then
            log_info "Stopping and removing kind-registry container"
            docker stop kind-registry >/dev/null 2>&1 || true
            docker rm kind-registry >/dev/null 2>&1 || true
            log_success "Docker registry container removed"
        else
            log_warning "Docker registry container 'kind-registry' not found"
        fi
        
        # Check for registry on port 5002
        if docker ps -a | grep -q "5002:5000"; then
            log_info "Stopping registry on port 5002"
            docker stop $(docker ps -a --format "table {{.Names}}" | grep -v NAMES | xargs docker ps -a --format "table {{.Names}}\t{{.Ports}}" | grep 5002 | cut -f1) >/dev/null 2>&1 || true
        fi
    else
        log_warning "Docker not available, skipping registry cleanup"
    fi
}

# Function to cleanup Docker images
cleanup_docker_images() {
    log_info "Cleaning up Docker images..."
    
    if command_exists docker; then
        # Remove IOD V3 specific images
        log_info "Removing IOD V3 images..."
        docker images | grep -E "(iodv3|localhost:5002)" | awk '{print $3}' | xargs docker rmi -f >/dev/null 2>&1 || true
        
        # Clean up dangling images
        log_info "Removing dangling images..."
        docker image prune -f >/dev/null 2>&1 || true
        
        log_success "Docker images cleaned up"
    else
        log_warning "Docker not available, skipping image cleanup"
    fi
}

# Function to cleanup host entries
cleanup_host_entries() {
    log_info "Cleaning up host entries..."
    
    if [ -f /etc/hosts ]; then
        # Backup hosts file
        sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S)
        
        # Remove IOD V3 specific entries
        if grep -q "iodv3.local" /etc/hosts; then
            log_info "Removing IOD V3 host entries from /etc/hosts"
            sudo sed -i '/iodv3\.local/d' /etc/hosts
            log_success "Host entries removed from /etc/hosts"
        else
            log_warning "No IOD V3 host entries found in /etc/hosts"
        fi
    else
        log_warning "/etc/hosts file not found"
    fi
}

# Function to cleanup Kubernetes resources (if using different cluster)
cleanup_k8s_resources() {
    log_info "Cleaning up Kubernetes resources..."
    
    if command_exists kubectl; then
        # Check if cluster is accessible
        if kubectl cluster-info >/dev/null 2>&1; then
            # Delete IOD V3 namespace (this removes all resources in the namespace)
            if kubectl get namespace iodv3-dev >/dev/null 2>&1; then
                log_info "Deleting namespace: iodv3-dev (includes all pods, services, ingresses, PVCs)"
                kubectl delete namespace iodv3-dev --timeout=120s
                log_success "Namespace iodv3-dev deleted with all resources"
            else
                log_warning "Namespace iodv3-dev not found"
            fi
            
            # Clean up ingress controller if installed
            if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
                log_info "Deleting ingress-nginx namespace (includes controller, admission webhook)"
                kubectl delete namespace ingress-nginx --timeout=120s
                log_success "Ingress controller and all components cleaned up"
            else
                log_warning "Ingress controller not found"
            fi
            
            # Clean up any remaining cluster-wide resources
            log_info "Cleaning up cluster-wide resources..."
            
            # Remove ingress classes
            kubectl delete ingressclass nginx --ignore-not-found=true >/dev/null 2>&1 || true
            
            # Remove cluster roles and bindings
            kubectl delete clusterrole ingress-nginx ingress-nginx-admission --ignore-not-found=true >/dev/null 2>&1 || true
            kubectl delete clusterrolebinding ingress-nginx ingress-nginx-admission --ignore-not-found=true >/dev/null 2>&1 || true
            
            # Remove validation webhook configurations
            kubectl delete validatingwebhookconfiguration ingress-nginx-admission --ignore-not-found=true >/dev/null 2>&1 || true
            
            log_success "Cluster-wide resources cleaned up"
        else
            log_warning "Kubernetes cluster not accessible, skipping resource cleanup"
        fi
    else
        log_warning "kubectl not installed, skipping Kubernetes cleanup"
    fi
}

# Function to cleanup Docker Compose resources
cleanup_docker_compose() {
    log_info "Cleaning up Docker Compose resources..."
    
    if command_exists docker-compose; then
        if [ -f "docker-compose.yaml" ] || [ -f "docker-compose.yml" ]; then
            log_info "Stopping Docker Compose services"
            docker-compose down --volumes --remove-orphans >/dev/null 2>&1 || true
            log_success "Docker Compose services stopped"
        fi
        
        if [ -f "docker-compose.db.yaml" ]; then
            log_info "Stopping database services"
            docker-compose -f docker-compose.db.yaml down --volumes --remove-orphans >/dev/null 2>&1 || true
            log_success "Database services stopped"
        fi
    else
        log_warning "docker-compose not available, skipping compose cleanup"
    fi
}

# Function to cleanup local development files
cleanup_local_files() {
    log_info "Cleaning up temporary files..."
    
    # Remove common temporary files
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name ".pytest_cache" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.log" -delete 2>/dev/null || true
    
    log_success "Temporary files cleaned up"
}

# Function to display cleanup options
show_help() {
    echo "IOD V3 Backend Cleanup Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  all              Complete cleanup (Kind + Docker + hosts + files)"
    echo "  kind             Cleanup Kind cluster only (deletes all nodes, ingress, resources)"
    echo "  cluster          Alias for 'kind' - complete cluster cleanup"
    echo "  k8s              Cleanup Kubernetes resources (for non-Kind clusters)"
    echo "  docker           Cleanup Docker containers and images"
    echo "  registry         Cleanup Docker registry only"
    echo "  images           Cleanup Docker images only"
    echo "  hosts            Cleanup host entries only"
    echo "  compose          Cleanup Docker Compose resources"
    echo "  files            Cleanup temporary files only"
    echo "  selective        Interactive selective cleanup"
    echo "  help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all           # Complete cleanup"
    echo "  $0 kind          # Remove Kind cluster (all nodes + resources)"
    echo "  $0 cluster       # Same as 'kind'"
    echo "  $0 docker        # Remove Docker resources only"
    echo "  $0 selective     # Choose what to clean up"
    echo ""
    echo "What gets deleted with 'kind' cleanup:"
    echo "  • All cluster nodes (control-plane + 2 workers)"
    echo "  • All Kubernetes resources (pods, services, ingresses)"
    echo "  • All persistent volumes and claims"
    echo "  • Ingress controller and admission webhooks"
    echo "  • All network configurations"
    echo "  • All cluster-wide resources (RBAC, CRDs, etc.)"
}

# Function for selective cleanup
selective_cleanup() {
    echo "🧹 IOD V3 Selective Cleanup"
    echo "=========================="
    echo ""
    
    read -p "Clean up Kind cluster? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_kind_cluster
    fi
    
    read -p "Clean up Docker registry? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_docker_registry
    fi
    
    read -p "Clean up Docker images? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_docker_images
    fi
    
    read -p "Clean up host entries? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_host_entries
    fi
    
    read -p "Clean up Docker Compose resources? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_docker_compose
    fi
    
    read -p "Clean up temporary files? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup_local_files
    fi
}

# Function for complete cleanup
complete_cleanup() {
    log_info "Starting complete IOD V3 cleanup..."
    echo "=================================="
    
    cleanup_kind_cluster          # Deletes entire cluster (nodes, ingress, everything)
    cleanup_docker_registry       # Removes local registry containers
    cleanup_docker_images         # Removes IOD V3 Docker images
    cleanup_host_entries          # Removes /etc/hosts entries
    cleanup_docker_compose        # Removes Docker Compose resources
    cleanup_local_files           # Removes temp files
    
    echo ""
    log_success "Complete cleanup finished!"
    echo ""
    log_info "🧹 What was cleaned up:"
    log_info "  ✅ Kind cluster (including all 3 nodes)"
    log_info "  ✅ All Kubernetes resources (pods, services, ingresses, PVCs)"
    log_info "  ✅ Ingress controller and admission webhooks"
    log_info "  ✅ Docker registry containers"
    log_info "  ✅ IOD V3 Docker images"
    log_info "  ✅ Host entries from /etc/hosts"
    log_info "  ✅ Docker Compose resources"
    log_info "  ✅ Temporary files"
    echo ""
    log_info "System is now clean and ready for fresh deployment"
    log_info "To redeploy, run: make deploy-hybrid"
}

# Main script logic
case "${1:-help}" in
    "all"|"complete")
        complete_cleanup
        ;;
    "kind"|"cluster")
        cleanup_kind_cluster
        ;;
    "docker")
        cleanup_docker_registry
        cleanup_docker_images
        ;;
    "registry")
        cleanup_docker_registry
        ;;
    "images")
        cleanup_docker_images
        ;;
    "hosts")
        cleanup_host_entries
        ;;
    "k8s"|"kubernetes")
        cleanup_k8s_resources
        ;;
    "compose")
        cleanup_docker_compose
        ;;
    "files"|"temp")
        cleanup_local_files
        ;;
    "selective"|"choose")
        selective_cleanup
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        log_error "Unknown option: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
