#!/bin/bash

# Deploy script for IOD V3 Backend

set -e

ENVIRONMENT=${1:-dev}

if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "qa" ]; then
    echo "Usage: $0 [dev|qa]"
    echo "Example: $0 dev"
    exit 1
fi

echo "Deploying to $ENVIRONMENT environment..."

# Create Kind cluster if it doesn't exist
if ! kind get clusters | grep -q "iodv3-cluster"; then
    echo "Creating Kind cluster..."
    kind create cluster --config k8s/kind-config.yaml
fi

# Build and load images
./scripts/build.sh

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests for $ENVIRONMENT..."
kubectl apply -f k8s/$ENVIRONMENT/

echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment --all -n iodv3-$ENVIRONMENT

echo "Deployment completed!"
echo ""
echo "Services:"
kubectl get services -n iodv3-$ENVIRONMENT

echo ""
echo "Pods:"
kubectl get pods -n iodv3-$ENVIRONMENT

echo ""
echo "API Gateway is available at:"
if [ "$ENVIRONMENT" = "dev" ]; then
    echo "http://localhost:8000"
else
    echo "Check the LoadBalancer IP:"
    echo "kubectl get service api-gateway -n iodv3-$ENVIRONMENT"
fi
