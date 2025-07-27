#!/bin/bash

# IOD V3 Backend - Deployment Status Check
# This script shows what's currently deployed and would be cleaned up

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔍 IOD V3 Backend - Current Deployment Status"
echo "============================================="
echo ""

# Check Kind clusters
log_info "Kind Clusters:"
if command -v kind >/dev/null 2>&1; then
    CLUSTERS=$(kind get clusters 2>/dev/null || echo "")
    if [ -n "$CLUSTERS" ]; then
        echo "$CLUSTERS" | while read -r cluster_name; do
            echo "  📦 $cluster_name"
        done
    else
        log_warning "No Kind clusters found"
    fi
else
    log_warning "Kind not installed"
fi
echo ""

# Check current Kubernetes context
log_info "Current Kubernetes Context:"
if command -v kubectl >/dev/null 2>&1; then
    CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "none")
    echo "  🎯 $CURRENT_CONTEXT"
    
    # Check cluster nodes
    log_info "Cluster Nodes:"
    if kubectl get nodes >/dev/null 2>&1; then
        kubectl get nodes --no-headers | while read -r line; do
            node_name=$(echo "$line" | awk '{print $1}')
            node_status=$(echo "$line" | awk '{print $2}')
            node_role=$(echo "$line" | awk '{print $3}')
            echo "  🖥️  $node_name ($node_role) - $node_status"
        done
    else
        log_warning "Cannot access cluster nodes"
    fi
else
    log_warning "kubectl not installed"
fi
echo ""

# Check IOD V3 namespace
log_info "IOD V3 Namespace Resources:"
if kubectl get namespace iodv3-dev >/dev/null 2>&1; then
    log_success "Namespace 'iodv3-dev' exists"
    
    # Check pods
    POD_COUNT=$(kubectl get pods -n iodv3-dev --no-headers 2>/dev/null | wc -l)
    if [ "$POD_COUNT" -gt 0 ]; then
        echo "  📋 Pods ($POD_COUNT):"
        kubectl get pods -n iodv3-dev --no-headers | while read -r line; do
            pod_name=$(echo "$line" | awk '{print $1}')
            pod_status=$(echo "$line" | awk '{print $3}')
            echo "    🟢 $pod_name - $pod_status"
        done
    else
        log_warning "No pods found in iodv3-dev namespace"
    fi
    
    # Check services
    SVC_COUNT=$(kubectl get services -n iodv3-dev --no-headers 2>/dev/null | wc -l)
    if [ "$SVC_COUNT" -gt 0 ]; then
        echo "  🌐 Services ($SVC_COUNT):"
        kubectl get services -n iodv3-dev --no-headers | while read -r line; do
            svc_name=$(echo "$line" | awk '{print $1}')
            svc_type=$(echo "$line" | awk '{print $2}')
            echo "    🔗 $svc_name ($svc_type)"
        done
    else
        log_warning "No services found in iodv3-dev namespace"
    fi
    
    # Check ingresses
    ING_COUNT=$(kubectl get ingresses -n iodv3-dev --no-headers 2>/dev/null | wc -l)
    if [ "$ING_COUNT" -gt 0 ]; then
        echo "  🚪 Ingresses ($ING_COUNT):"
        kubectl get ingresses -n iodv3-dev --no-headers | while read -r line; do
            ing_name=$(echo "$line" | awk '{print $1}')
            ing_hosts=$(echo "$line" | awk '{print $3}')
            echo "    🌐 $ing_name - $ing_hosts"
        done
    else
        log_warning "No ingresses found in iodv3-dev namespace"
    fi
else
    log_warning "Namespace 'iodv3-dev' not found"
fi
echo ""

# Check ingress controller
log_info "Ingress Controller:"
if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
    log_success "Ingress controller namespace exists"
    
    CONTROLLER_PODS=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | wc -l)
    if [ "$CONTROLLER_PODS" -gt 0 ]; then
        echo "  🎮 Controller pods ($CONTROLLER_PODS):"
        kubectl get pods -n ingress-nginx --no-headers | while read -r line; do
            pod_name=$(echo "$line" | awk '{print $1}')
            pod_status=$(echo "$line" | awk '{print $3}')
            echo "    🟢 $pod_name - $pod_status"
        done
    fi
else
    log_warning "Ingress controller not found"
fi
echo ""

# Check Docker resources
log_info "Docker Resources:"
if command -v docker >/dev/null 2>&1; then
    # Check for Kind registry
    if docker ps -a | grep -q "kind-registry"; then
        log_success "Kind registry container found"
    else
        log_warning "Kind registry container not found"
    fi
    
    # Check for IOD V3 images
    IOD_IMAGES=$(docker images | grep -E "(iodv3|localhost:5002)" | wc -l)
    if [ "$IOD_IMAGES" -gt 0 ]; then
        log_success "IOD V3 Docker images found ($IOD_IMAGES)"
    else
        log_warning "No IOD V3 Docker images found"
    fi
else
    log_warning "Docker not available"
fi
echo ""

# Check host entries
log_info "Host Entries:"
if grep -q "iodv3.local" /etc/hosts 2>/dev/null; then
    log_success "IOD V3 host entries found:"
    grep "iodv3.local" /etc/hosts | while read -r line; do
        echo "    🌐 $line"
    done
else
    log_warning "No IOD V3 host entries found"
fi
echo ""

echo "📋 Summary:"
echo "==========="
echo "This shows what would be cleaned up by running:"
echo "  make cleanup          # Complete cleanup"
echo "  make cleanup-kind     # Cluster cleanup only"
echo "  make cleanup-docker   # Docker cleanup only"
echo "  make cleanup-hosts    # Host entries only"
echo ""
echo "For interactive cleanup: make clean-selective"
