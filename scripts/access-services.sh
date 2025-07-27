#!/bin/bash

# Service access script for Kind deployment
echo "IOD V3 Kind Deployment - Service Access Information"
echo "=================================================="

# Check if cluster exists
if ! kubectl cluster-info --context kind-iodv3-dev &> /dev/null; then
    echo "Error: Kind cluster 'iodv3-dev' not found!"
    echo "Run 'make kind-cluster' to create the cluster first."
    exit 1
fi

# Get node IP (for Kind, it's usually localhost)
NODE_IP="localhost"

echo ""
echo "Services are accessible via NodePort on the following URLs:"
echo ""
echo "🌐 API Gateway:     http://${NODE_IP}:30000"
echo "👤 Accounts Service: http://${NODE_IP}:30001"  
echo "📝 Blog Service:     http://${NODE_IP}:30002"
echo ""

# Test connectivity
echo "Testing service connectivity..."
echo ""

test_service() {
    local service_name=$1
    local url=$2
    
    if curl -s "$url/health" > /dev/null 2>&1; then
        echo "✅ $service_name is accessible at $url"
    else
        echo "❌ $service_name is not accessible at $url"
    fi
}

test_service "API Gateway" "http://${NODE_IP}:30000"
test_service "Accounts Service" "http://${NODE_IP}:30001"
test_service "Blog Service" "http://${NODE_IP}:30002"

echo ""
echo "📖 API Documentation:"
echo "  API Gateway Docs:     http://${NODE_IP}:30000/docs"
echo "  Accounts Service Docs: http://${NODE_IP}:30001/docs"
echo "  Blog Service Docs:     http://${NODE_IP}:30002/docs"
echo ""
echo "🧪 To run tests:"
echo "  ./scripts/test-kind-deployment.sh"
