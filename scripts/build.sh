#!/bin/bash

# Build script for IOD V3 Backend

set -e

echo "Building IOD V3 Backend Services..."

# Build API Gateway
echo "Building API Gateway..."
docker build -t iodv3/api-gateway:dev -f gateway/Dockerfile .
docker build -t iodv3/api-gateway:qa -f gateway/Dockerfile .

# Build Accounts Service
echo "Building Accounts Service..."
docker build -t iodv3/accounts-service:dev -f services/accounts/Dockerfile .
docker build -t iodv3/accounts-service:qa -f services/accounts/Dockerfile .

# Build Blog Service
echo "Building Blog Service..."
docker build -t iodv3/blog-service:dev -f services/blog/Dockerfile .
docker build -t iodv3/blog-service:qa -f services/blog/Dockerfile .

echo "All services built successfully!"

# Load images into Kind cluster (if running)
if kind get clusters | grep -q "iodv3-cluster"; then
    echo "Loading images into Kind cluster..."
    kind load docker-image iodv3/api-gateway:dev --name iodv3-cluster
    kind load docker-image iodv3/accounts-service:dev --name iodv3-cluster
    kind load docker-image iodv3/blog-service:dev --name iodv3-cluster
    kind load docker-image iodv3/api-gateway:qa --name iodv3-cluster
    kind load docker-image iodv3/accounts-service:qa --name iodv3-cluster
    kind load docker-image iodv3/blog-service:qa --name iodv3-cluster
    echo "Images loaded into Kind cluster!"
fi
