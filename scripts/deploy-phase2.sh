#!/bin/bash

# IOD V3 Backend - Enhanced Deployment Script for Phase 2
# Builds on Phase 1 with additional Phase 2 features

set -e

# Import Phase 1 script
source "$(dirname "$0")/deploy-kind-enhanced.sh"

# Phase 2 Configuration
PHASE="Phase 2: Access Method Enhancement"

# Function to setup Phase 2 features
setup_phase2() {
    log_info "🚀 Starting $PHASE implementation..."
    
    # Setup local domains
    log_info "Setting up local domain resolution..."
    if ./scripts/setup-hosts.sh show | grep -q "IOD V3 entries are currently active"; then
        log_success "Domain entries already configured"
    else
        log_info "Adding domain entries (requires sudo)..."
        sudo ./scripts/setup-hosts.sh add
    fi
    
    # Phase 1 deployment
    log_info "Running Phase 1 enhanced deployment..."
    main
    
    # Additional Phase 2 features would go here
    # (Ingress setup temporarily disabled due to configuration complexity)
    
    show_phase2_access_info
}

# Function to show Phase 2 access information
show_phase2_access_info() {
    echo ""
    log_success "🎉 IOD V3 Backend Phase 2 deployed successfully!"
    echo ""
    echo "📖 Access Information:"
    echo "  Cluster: ${CLUSTER_NAME}"
    echo "  Context: kind-${CLUSTER_NAME}"
    echo "  Namespace: ${NAMESPACE}"
    echo ""
    echo "🌐 Primary Access (NodePort) - Working:"
    echo "  API Gateway:     http://localhost:30000"
    echo "  Accounts Service: http://localhost:30001" 
    echo "  Blog Service:    http://localhost:30002"
    echo ""
    echo "🌍 Domain Access (Ready for future Ingress):"
    echo "  API Gateway:     http://api.iodv3.local:8080 (Ingress pending)"
    echo "  Accounts Service: http://accounts.iodv3.local:8080 (Ingress pending)"
    echo "  Blog Service:    http://blog.iodv3.local:8080 (Ingress pending)"
    echo ""
    echo "✅ Phase 2 Features Implemented:"
    echo "  • Enhanced automation scripts"
    echo "  • Local domain configuration"
    echo "  • Host management automation"
    echo "  • Multi-node cluster (3 nodes)"
    echo "  • Local Docker registry (localhost:5002)"
    echo "  • Comprehensive testing framework"
    echo ""
    echo "🔄 Phase 2 Features Pending:"
    echo "  • Ingress Controller (configuration in progress)"
    echo "  • Domain-based routing (requires Ingress)"
    echo ""
    echo "🧪 Test Commands:"
    echo "  # Test Phase 1 functionality"
    echo "  curl http://localhost:30000/health"
    echo "  curl http://localhost:30001/health"
    echo "  curl http://localhost:30002/health"
    echo ""
    echo "  # Run comprehensive tests"
    echo "  ./scripts/test-comprehensive.sh"
    echo ""
    echo "  # Host management"
    echo "  ./scripts/setup-hosts.sh show"
    echo ""
    echo "📋 Phase 3 Ready:"
    echo "  All infrastructure is ready for Phase 3 (Advanced Features)"
    echo "  • Health checks enhancement"
    echo "  • Resource management"
    echo "  • Advanced monitoring"
}

# Main function for Phase 2
main_phase2() {
    setup_phase2
}

# Parse command line arguments
case "${1:-deploy}" in
    "deploy"|"")
        main_phase2
        ;;
    "cleanup"|"clean")
        cleanup_deployment
        sudo ./scripts/setup-hosts.sh remove
        ;;
    "status")
        show_status
        ./scripts/setup-hosts.sh show
        ;;
    "help"|"--help"|"-h")
        echo "Usage: $0 [deploy|cleanup|status|help]"
        echo "  deploy     - Deploy the full IOD V3 stack with Phase 2 features"
        echo "  cleanup    - Remove cluster, registry, and host entries"
        echo "  status     - Show cluster and host status"
        echo "  help       - Show this help message"
        ;;
    *)
        log_error "Invalid command. Use: deploy, cleanup, status, or help"
        exit 1
        ;;
esac
