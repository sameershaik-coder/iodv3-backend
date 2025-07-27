# Kind Development Environment Deployment Guide

## Prerequisites

1. **Docker**: Ensure Docker is installed and running
2. **Kind**: Install Kind for local Kubernetes clusters
3. **kubectl**: Install kubectl to interact with Kubernetes

### Install Kind

```bash
# For Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verify installation
kind version
```

### Install kubectl

```bash
# For Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client
```

## Quick Start

### Option 1: Using Makefile (Recommended)

```bash
# Deploy everything
make kind-deploy

# Check deployment status
make kind-status

# Access services
make kind-ports

# Clean up
make kind-clean
```

### Option 2: Manual Deployment

## Step-by-Step Manual Deployment

### 1. Create Kind Cluster

```bash
# Create cluster with custom configuration
kind create cluster --config k8s/kind-config.yaml --name iodv3-dev

# Verify cluster is running
kubectl cluster-info --context kind-iodv3-dev
```

### 2. Build and Load Docker Images

```bash
# Build all service images
docker build -t iodv3/accounts-service:dev -f services/accounts/Dockerfile .
docker build -t iodv3/blog-service:dev -f services/blog/Dockerfile .
docker build -t iodv3/api-gateway:dev -f gateway/Dockerfile .

# Load images into Kind cluster
kind load docker-image iodv3/accounts-service:dev --name iodv3-dev
kind load docker-image iodv3/blog-service:dev --name iodv3-dev
kind load docker-image iodv3/api-gateway:dev --name iodv3-dev
```

### 3. Deploy to Kubernetes

```bash
# Apply configurations in order
kubectl apply -f k8s/dev/namespace.yaml
kubectl apply -f k8s/dev/configmap.yaml
kubectl apply -f k8s/dev/postgres.yaml
kubectl apply -f k8s/dev/redis.yaml

# Wait for databases to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n iodv3-dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n iodv3-dev --timeout=300s

# Deploy services
kubectl apply -f k8s/dev/accounts-service.yaml
kubectl apply -f k8s/dev/blog-service.yaml
kubectl apply -f k8s/dev/api-gateway.yaml

# Wait for services to be ready
kubectl wait --for=condition=ready pod -l app=accounts-service -n iodv3-dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=blog-service -n iodv3-dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=api-gateway -n iodv3-dev --timeout=300s
```

### 4. Access Services

```bash
# Port forward to access services locally
kubectl port-forward -n iodv3-dev service/api-gateway 8000:80 &
kubectl port-forward -n iodv3-dev service/accounts-service 8001:80 &
kubectl port-forward -n iodv3-dev service/blog-service 8002:80 &

# Access the API Gateway
curl http://localhost:8000/health
```

## Monitoring and Debugging

### Check Pod Status

```bash
# Get all pods in dev namespace
kubectl get pods -n iodv3-dev

# Check specific pod logs
kubectl logs -n iodv3-dev deployment/accounts-service
kubectl logs -n iodv3-dev deployment/blog-service
kubectl logs -n iodv3-dev deployment/api-gateway

# Describe pod for detailed information
kubectl describe pod -n iodv3-dev <pod-name>
```

### Check Services and Endpoints

```bash
# Get all services
kubectl get services -n iodv3-dev

# Get service endpoints
kubectl get endpoints -n iodv3-dev

# Check service details
kubectl describe service -n iodv3-dev api-gateway
```

### Database Access

```bash
# Connect to PostgreSQL
kubectl exec -it -n iodv3-dev deployment/postgres -- psql -U postgres -d iodv3_accounts

# Connect to Redis
kubectl exec -it -n iodv3-dev deployment/redis -- redis-cli
```

## Testing the Deployment

### Basic Health Check

```bash
# Test API Gateway health
curl http://localhost:8000/health

# Expected response:
# {"status":"healthy","services":{"accounts":true,"blog":true}}
```

### API Testing

```bash
# Create a user
curl -X POST http://localhost:8000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Test User",
    "email": "test@example.com",
    "password": "testpassword123"
  }'

# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }'
```

## Cleanup

### Remove Kind Cluster

```bash
# Delete the entire cluster
kind delete cluster --name iodv3-dev
```

### Stop Port Forwards

```bash
# Kill all port-forward processes
pkill -f "kubectl port-forward"
```

## Troubleshooting

### Common Issues

1. **ImagePullBackOff**: Images not loaded into Kind cluster
   ```bash
   kind load docker-image <image-name> --name iodv3-dev
   ```

2. **Pod CrashLoopBackOff**: Check logs for errors
   ```bash
   kubectl logs -n iodv3-dev <pod-name>
   ```

3. **Service Connection Issues**: Check service endpoints
   ```bash
   kubectl get endpoints -n iodv3-dev
   ```

### Useful Commands

```bash
# Get cluster information
kubectl cluster-info --context kind-iodv3-dev

# Get all resources in namespace
kubectl get all -n iodv3-dev

# Watch pod status
kubectl get pods -n iodv3-dev -w

# Port forward all services at once
./scripts/port-forward.sh
```

## Development Workflow

1. Make code changes
2. Rebuild Docker images
3. Load images into Kind
4. Apply updated Kubernetes manifests
5. Test changes

```bash
# Quick update workflow
make kind-update-image service=accounts
# or
make kind-rebuild-deploy
```

This deployment provides a full Kubernetes environment that closely mirrors production while running locally on your development machine.
