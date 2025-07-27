#!/bin/bash

# Deploy IOD V3 with Ingress-based Access
# This script deploys the complete IOD V3 stack using ingress for routing

set -e

echo "🚀 Deploying IOD V3 with Ingress-based Access..."

# Check if Kind cluster exists
if ! kind get clusters | grep -q iodv3; then
    echo "❌ Kind cluster 'iodv3' not found. Please run 'make kind-setup' first."
    exit 1
fi

# Install NGINX Ingress Controller if not already installed
echo "📦 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Apply all K8s manifests
echo "📋 Applying Kubernetes manifests..."
kubectl apply -f k8s/dev/namespace.yaml
kubectl apply -f k8s/dev/configmap.yaml
kubectl apply -f k8s/dev/postgres.yaml
kubectl apply -f k8s/dev/redis.yaml
kubectl apply -f k8s/dev/api-gateway.yaml
kubectl apply -f k8s/dev/accounts-service.yaml
kubectl apply -f k8s/dev/blog-service.yaml
kubectl apply -f k8s/dev/ingress.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/api-gateway -n iodv3-dev
kubectl wait --for=condition=available --timeout=300s deployment/accounts-service -n iodv3-dev
kubectl wait --for=condition=available --timeout=300s deployment/blog-service -n iodv3-dev
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n iodv3-dev
kubectl wait --for=condition=available --timeout=300s deployment/redis -n iodv3-dev

# Setup local hosts
echo "🌐 Setting up local host entries..."
if ! grep -q "dev.iodv3.local" /etc/hosts; then
    echo "127.0.0.1 dev.iodv3.local" | sudo tee -a /etc/hosts
    echo "✅ Added dev.iodv3.local to /etc/hosts"
else
    echo "✅ dev.iodv3.local already in /etc/hosts"
fi

# Get ingress status
echo "📊 Checking ingress status..."
kubectl get ingress -n iodv3-dev

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📍 Service Access URLs:"
echo "   Main Application: http://dev.iodv3.local:8080"
echo "   Accounts Service: http://dev.iodv3.local:8080/accounts"
echo "   Blog Service: http://dev.iodv3.local:8080/blog"
echo ""
echo "📚 API Documentation:"
echo "   Gateway Docs: http://dev.iodv3.local:8080/docs"
echo "   Accounts Docs: http://dev.iodv3.local:8080/accounts/docs"
echo "   Blog Docs: http://dev.iodv3.local:8080/blog/docs"
echo ""
echo "🔍 Health Check Commands:"
echo "   curl -H 'Host: dev.iodv3.local' http://localhost:8080/health"
echo "   curl -H 'Host: dev.iodv3.local' http://localhost:8080/accounts/health"
echo "   curl -H 'Host: dev.iodv3.local' http://localhost:8080/blog/health"
echo ""
echo "📊 Monitor with: make monitor-resources"
