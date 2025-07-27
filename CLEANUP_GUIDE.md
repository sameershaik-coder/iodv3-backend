# IOD V3 Backend - Cleanup Guide

This guide covers the comprehensive cleanup functionality available in the IOD V3 Backend project.

## 🧹 Cleanup Script Overview

The project includes a comprehensive cleanup script (`scripts/cleanup.sh`) that handles all types of resource cleanup for different deployment scenarios.

## 🎯 Available Cleanup Options

### Complete Cleanup
```bash
# Complete cleanup of all resources
make cleanup
# or
make clean-all
# or
./scripts/cleanup.sh all
```

**What it cleans:**
- Kind cluster
- Docker registry containers
- Docker images (IOD V3 specific)
- Host entries (/etc/hosts)
- Docker Compose resources
- Temporary files (.pyc, __pycache__, logs)

### Selective Cleanup
```bash
# Interactive cleanup - choose what to clean
make clean-selective
# or
./scripts/cleanup.sh selective
```

**Interactive prompts for:**
- Kind cluster cleanup
- Docker registry cleanup
- Docker images cleanup
- Host entries cleanup
- Docker Compose cleanup
- Temporary files cleanup

### Specific Component Cleanup

#### Kind Cluster Only
```bash
make cleanup-kind
# or
./scripts/cleanup.sh kind
```

#### Docker Resources
```bash
# All Docker resources (registry + images)
make cleanup-docker
# or
./scripts/cleanup.sh docker

# Registry only
make cleanup-registry
# or
./scripts/cleanup.sh registry

# Images only
./scripts/cleanup.sh images
```

#### Host Entries
```bash
make cleanup-hosts
# or
./scripts/cleanup.sh hosts
```

#### Temporary Files
```bash
make cleanup-files
# or
./scripts/cleanup.sh files
```

#### Docker Compose Resources
```bash
./scripts/cleanup.sh compose
```

## 🛡️ Safety Features

### Backup Creation
- **Host file backup**: Creates timestamped backup before modifying /etc/hosts
- **Non-destructive checks**: Verifies resources exist before attempting cleanup
- **Graceful handling**: Continues even if some resources don't exist

### Error Handling
- **Command availability check**: Verifies tools (docker, kind, kubectl) before use
- **Resource existence check**: Only attempts cleanup if resources are present
- **Timeout handling**: Uses timeouts for Kubernetes resource deletion

### User Confirmation
- **Selective mode**: Interactive prompts for each cleanup action
- **Clear output**: Color-coded status messages for all operations
- **Status reporting**: Success/warning/error indicators for each step

## 📋 Cleanup Scenarios

### Development Reset
After working on features and wanting a clean slate:
```bash
make cleanup
make deploy-hybrid
```

### Switching Deployment Types
When switching from one deployment type to another:
```bash
# Clean current setup
make cleanup-kind

# Deploy different version
make deploy-phase3
```

### Docker Resource Management
When Docker resources are taking up space:
```bash
# Clean IOD V3 images only
make cleanup-docker

# Keep cluster, just clean Docker
./scripts/cleanup.sh images
```

### Host File Management
When having issues with domain resolution:
```bash
# Clean and reset host entries
make cleanup-hosts

# Redeploy to recreate host entries
make deploy-hybrid
```

## 🔍 Verification Commands

### Check What Exists Before Cleanup
```bash
# Check Kind clusters
kind get clusters

# Check Docker containers
docker ps -a | grep -E "(kind|registry|iodv3)"

# Check Docker images
docker images | grep -E "(iodv3|localhost:5002)"

# Check host entries
grep iodv3.local /etc/hosts

# Check Kubernetes resources
kubectl get namespaces | grep iodv3
```

### Verify Cleanup Completion
```bash
# Verify cluster removal
kind get clusters | grep -v iodv3

# Verify Docker cleanup
docker ps -a | grep -E "(kind|registry|iodv3)" | wc -l

# Verify host cleanup
grep iodv3.local /etc/hosts | wc -l
```

## 🚨 Troubleshooting

### Common Issues

#### Permission Errors
```bash
# If you get permission errors for /etc/hosts
sudo ./scripts/cleanup.sh hosts
```

#### Stuck Kubernetes Resources
```bash
# Force cleanup if resources are stuck
kubectl delete namespace iodv3-dev --force --grace-period=0
```

#### Docker Permission Issues
```bash
# If Docker commands fail due to permissions
sudo ./scripts/cleanup.sh docker
```

### Manual Cleanup
If the script fails, manual cleanup commands:

```bash
# Manual Kind cleanup
kind delete cluster --name iodv3-cluster

# Manual Docker cleanup
docker stop kind-registry
docker rm kind-registry
docker system prune -f

# Manual host cleanup
sudo sed -i '/iodv3\.local/d' /etc/hosts

# Manual Kubernetes cleanup
kubectl delete namespace iodv3-dev --timeout=60s
kubectl delete namespace ingress-nginx --timeout=60s
```

## 📊 Cleanup Script Features

### Comprehensive Coverage
- ✅ Kind clusters
- ✅ Docker containers
- ✅ Docker images
- ✅ Docker registry
- ✅ Host entries
- ✅ Kubernetes resources
- ✅ Docker Compose resources
- ✅ Temporary files

### User Experience
- ✅ Color-coded output
- ✅ Progress indicators
- ✅ Error handling
- ✅ Interactive mode
- ✅ Help documentation
- ✅ Multiple invocation methods

### Integration
- ✅ Makefile integration
- ✅ Consistent with project patterns
- ✅ Works with all deployment types
- ✅ Safe for production usage

## 🔄 Best Practices

### Regular Cleanup
```bash
# Weekly cleanup of temporary files
make cleanup-files

# Monthly full cleanup for fresh start
make cleanup
```

### Development Workflow
```bash
# Start of development session
make cleanup
make deploy-hybrid

# End of development session
make cleanup-files
```

### CI/CD Integration
```bash
# In CI scripts - clean slate for each run
./scripts/cleanup.sh all
./scripts/deploy-hybrid.sh
```

## 📞 Support

For cleanup-related issues:

1. **Check script help**: `make cleanup-help`
2. **Use selective mode**: `make clean-selective`
3. **Manual verification**: Check individual components
4. **Force cleanup**: Use manual commands if script fails

The cleanup functionality ensures that the IOD V3 Backend project maintains a clean development environment and provides reliable resource management for all deployment scenarios.
