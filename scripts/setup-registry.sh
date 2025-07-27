#!/bin/bash

# IOD V3 Backend - Local Docker Registry Setup
# This script creates and configures a local Docker registry for Kind

set -e

REGISTRY_NAME="iodv3-registry"
REGISTRY_PORT="5002"
CLUSTER_NAME="iodv3-cluster"

echo "🚀 Setting up local Docker registry for IOD V3..."

# Function to create local registry
create_registry() {
    # Check if registry container already exists
    if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" 2>/dev/null || true)" != 'true' ]; then
        echo "🏗️  Creating local Docker registry..."
        docker run \
            -d --restart=always \
            -p "127.0.0.1:${REGISTRY_PORT}:5000" \
            --name "${REGISTRY_NAME}" \
            registry:2
        
        echo "✅ Registry created at localhost:${REGISTRY_PORT}"
    else
        echo "📦 Local Docker registry already running at localhost:${REGISTRY_PORT}"
    fi
}

# Function to connect registry to Kind network
connect_registry() {
    if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}" 2>/dev/null)" = 'null' ]; then
        echo "🔗 Connecting registry to Kind network..."
        docker network connect "kind" "${REGISTRY_NAME}" || true
        echo "✅ Registry connected to Kind network"
    else
        echo "🔗 Registry already connected to Kind network"
    fi
}

# Function to configure cluster to use local registry
configure_cluster_registry() {
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        echo "⚙️  Configuring cluster to use local registry..."
        kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
        echo "✅ Cluster configured to use local registry"
    else
        echo "⚠️  Kind cluster '${CLUSTER_NAME}' not found. Registry will be available when cluster is created."
    fi
}

# Function to test registry
test_registry() {
    echo "🧪 Testing registry connectivity..."
    if curl -f http://localhost:${REGISTRY_PORT}/v2/ > /dev/null 2>&1; then
        echo "✅ Registry is accessible at http://localhost:${REGISTRY_PORT}"
    else
        echo "❌ Registry test failed"
        exit 1
    fi
}

# Function to show registry info
show_registry_info() {
    echo ""
    echo "🎉 Local Docker Registry Setup Complete!"
    echo ""
    echo "📦 Registry Information:"
    echo "  Name: ${REGISTRY_NAME}"
    echo "  URL: localhost:${REGISTRY_PORT}"
    echo "  Docker URL: localhost:${REGISTRY_PORT}"
    echo ""
    echo "🛠️  Usage Examples:"
    echo "  # Tag image for local registry"
    echo "  docker tag iodv3-gateway:latest localhost:${REGISTRY_PORT}/iodv3-gateway:latest"
    echo ""
    echo "  # Push to local registry"
    echo "  docker push localhost:${REGISTRY_PORT}/iodv3-gateway:latest"
    echo ""
    echo "  # Load image into Kind cluster"
    echo "  kind load docker-image localhost:${REGISTRY_PORT}/iodv3-gateway:latest --name=${CLUSTER_NAME}"
    echo ""
    echo "📋 Useful Commands:"
    echo "  # List images in registry"
    echo "  curl http://localhost:${REGISTRY_PORT}/v2/_catalog"
    echo ""
    echo "  # Remove registry"
    echo "  docker rm -f ${REGISTRY_NAME}"
}

# Main execution
main() {
    create_registry
    connect_registry
    configure_cluster_registry
    test_registry
    show_registry_info
}

# Parse command line arguments
case "${1:-setup}" in
    "setup"|"create"|"")
        main
        ;;
    "cleanup"|"remove")
        echo "🧹 Removing local Docker registry..."
        docker rm -f ${REGISTRY_NAME} || echo "Registry not found"
        echo "✅ Registry cleanup completed"
        ;;
    "status")
        echo "📊 Registry Status:"
        if docker ps --format '{{.Names}}' | grep -q "^${REGISTRY_NAME}$"; then
            echo "✅ Registry is running at localhost:${REGISTRY_PORT}"
            echo ""
            echo "Registry info:"
            docker inspect ${REGISTRY_NAME} --format '{{.State.Status}}: {{.NetworkSettings.IPAddress}}'
        else
            echo "❌ Registry is not running"
        fi
        ;;
    "help"|"--help"|"-h")
        echo "Usage: $0 [setup|cleanup|status|help]"
        echo "  setup    - Create and configure local registry (default)"
        echo "  cleanup  - Remove local registry"
        echo "  status   - Show registry status"
        echo "  help     - Show this help message"
        ;;
    *)
        echo "❌ Invalid command. Use: setup, cleanup, status, or help"
        exit 1
        ;;
esac
