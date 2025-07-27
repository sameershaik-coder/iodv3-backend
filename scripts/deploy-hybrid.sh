#!/bin/bash

# Hybrid deployment combining ingress-based and NodePort access
# This provides both production-like ingress and development-friendly NodePort access

set -e

echo "🚀 Deploying IOD V3 with Hybrid Access (Ingress + NodePort)..."

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

# Convert ingress controller to NodePort for Kind compatibility
echo "🔧 Configuring ingress controller for Kind..."
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":80,"nodePort":30080},{"port":443,"targetPort":443,"nodePort":30443}]}}'

# Create hybrid service configurations (both ClusterIP for ingress and NodePort for direct access)
echo "📋 Creating hybrid service configurations..."

# Create the ClusterIP services first
kubectl apply -f k8s/dev/namespace.yaml
kubectl apply -f k8s/dev/configmap.yaml
kubectl apply -f k8s/dev/postgres.yaml
kubectl apply -f k8s/dev/redis.yaml
kubectl apply -f k8s/dev/api-gateway.yaml
kubectl apply -f k8s/dev/accounts-service.yaml
kubectl apply -f k8s/dev/blog-service.yaml

# Now create additional NodePort services for direct access
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: api-gateway-nodeport
  namespace: iodv3-dev
spec:
  selector:
    app: api-gateway
  ports:
  - port: 8000
    targetPort: 8000
    nodePort: 30000
  type: NodePort
---
apiVersion: v1
kind: Service
metadata:
  name: accounts-service-nodeport
  namespace: iodv3-dev
spec:
  selector:
    app: accounts-service
  ports:
  - port: 8001
    targetPort: 8001
    nodePort: 30001
  type: NodePort
---
apiVersion: v1
kind: Service
metadata:
  name: blog-service-nodeport
  namespace: iodv3-dev
spec:
  selector:
    app: blog-service
  ports:
  - port: 8002
    targetPort: 8002
    nodePort: 30002
  type: NodePort
EOF

# Apply ingress configuration
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

# Get status
echo "📊 Checking deployment status..."
kubectl get ingress -n iodv3-dev
echo ""
kubectl get services -n iodv3-dev

echo ""
echo "🎉 Hybrid Deployment completed successfully!"
echo ""
echo "📍 Service Access URLs:"
echo ""
echo "🌐 Ingress-based Access (Production-like):"
echo "   Main Application: http://dev.iodv3.local:30080"
echo "   Accounts Service: http://dev.iodv3.local:30080/accounts"
echo "   Blog Service: http://dev.iodv3.local:30080/blog"
echo ""
echo "🔌 NodePort Access (Development):"
echo "   API Gateway: http://localhost:30000"
echo "   Accounts Service: http://localhost:30001"
echo "   Blog Service: http://localhost:30002"
echo ""
echo "🔍 Health Check Commands:"
echo ""
echo "Via Ingress:"
echo "   curl -H 'Host: dev.iodv3.local' http://localhost:30080/health"
echo "   curl -H 'Host: dev.iodv3.local' http://localhost:30080/accounts/health"
echo "   curl -H 'Host: dev.iodv3.local' http://localhost:30080/blog/health"
echo ""
echo "Via NodePort:"
echo "   curl http://localhost:30000/health"
echo "   curl http://localhost:30001/health"
echo "   curl http://localhost:30002/health"
echo ""
echo "📊 Monitor with: make monitor-resources"
