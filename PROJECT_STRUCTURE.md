# Project Structure

This document provides a comprehensive overview of the IOD V3 Backend project structure, showcasing a production-ready microservices platform.

## 📁 Directory Structure

```
iodv3-backend/
├── 📂 gateway/                      # API Gateway Service
│   ├── main.py                      # FastAPI gateway application
│   ├── pyproject.toml               # Poetry dependencies
│   ├── Dockerfile                   # Container configuration
│   └── poetry.lock                  # Locked dependencies
│
├── 📂 services/                     # Microservices
│   ├── 📂 accounts/                 # User management service
│   │   ├── main.py                  # Accounts service implementation
│   │   ├── pyproject.toml           # Service dependencies
│   │   ├── Dockerfile               # Container setup
│   │   └── poetry.lock              # Dependency lock
│   │
│   └── 📂 blog/                     # Content management service
│       ├── main.py                  # Blog service implementation
│       ├── pyproject.toml           # Service dependencies
│       ├── Dockerfile               # Container setup
│       └── poetry.lock              # Dependency lock
│
├── 📂 k8s/                          # Kubernetes Manifests
│   ├── 📂 phase1/                   # Basic deployment
│   │   ├── api-gateway.yaml         # Gateway deployment
│   │   ├── accounts-service.yaml    # Accounts deployment
│   │   ├── blog-service.yaml        # Blog deployment
│   │   ├── postgres.yaml            # Database deployment
│   │   ├── redis.yaml               # Cache deployment
│   │   └── namespace.yaml           # Namespace definition
│   │
│   ├── 📂 phase2/                   # Enhanced with host management
│   │   ├── api-gateway.yaml         # Enhanced gateway
│   │   ├── accounts-service.yaml    # Enhanced accounts
│   │   ├── blog-service.yaml        # Enhanced blog
│   │   ├── postgres.yaml            # Enhanced database
│   │   ├── redis.yaml               # Enhanced cache
│   │   ├── namespace.yaml           # Namespace with labels
│   │   └── ingress-nginx.yaml       # NGINX ingress controller
│   │
│   └── 📂 phase3/                   # Production-ready (Current)
│       ├── api-gateway.yaml         # Production gateway with health checks
│       ├── accounts-service.yaml    # Production accounts with monitoring
│       ├── blog-service.yaml        # Production blog with limits
│       ├── postgres.yaml            # Production database with resources
│       ├── redis.yaml               # Production cache with probes
│       ├── namespace.yaml           # Production namespace
│       └── ingress-nginx.yaml       # Production ingress
│
├── 📂 scripts/                      # Automation Scripts
│   ├── deploy-phase3.sh             # Phase 3 deployment automation
│   ├── monitor-resources.sh         # Resource monitoring system
│   ├── test-performance.sh          # Performance testing framework
│   └── setup-kind.sh                # Kind cluster setup
│
├── 📂 docker/                       # Docker Configurations
│   ├── docker-compose.yml           # Development environment
│   └── docker-compose.dev.yml       # Development with volumes
│
├── 📂 docs/                         # Documentation
│   ├── PHASE3_COMPLETION_REPORT.md  # Latest completion report
│   ├── PHASE2_COMPLETION_REPORT.md  # Phase 2 features
│   ├── DEPLOYMENT_ANALYSIS.md       # Technical analysis
│   └── PROJECT_STRUCTURE.md         # This document
│
├── 📄 Makefile                      # Build automation
├── 📄 README.md                     # Main project documentation
├── 📄 README.md.backup              # Previous README backup
└── 📄 .gitignore                    # Git ignore patterns
```

## 🏗️ Architecture Overview

### Service Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │────│ Accounts Service │────│  Blog Service   │
│   Port: 30000   │    │   Port: 30001    │    │   Port: 30002   │
│   CPU: 100m     │    │   CPU: 100m      │    │   CPU: 100m     │
│   Memory: 512Mi │    │   Memory: 512Mi  │    │   Memory: 512Mi │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐    ┌─────────────────┐
                    │   PostgreSQL    │    │      Redis      │
                    │   Port: 5432    │    │   Port: 6379    │
                    │   CPU: 200m     │    │   CPU: 100m     │
                    │   Memory: 1Gi   │    │   Memory: 256Mi │
                    └─────────────────┘    └─────────────────┘
```

### Deployment Phases

#### Phase 1 - Basic Deployment
- **Purpose**: Core microservices deployment
- **Features**: Basic service communication, NodePort access
- **Status**: ✅ Complete

#### Phase 2 - Enhanced Access
- **Purpose**: Host management and ingress
- **Features**: Custom host configuration, NGINX ingress
- **Status**: ✅ Complete

#### Phase 3 - Production Ready (Current)
- **Purpose**: Production deployment with monitoring
- **Features**: Health checks, resource limits, performance monitoring
- **Status**: ✅ Complete & Active

## 📋 Component Details

### Gateway Service (`gateway/`)
- **Purpose**: Central API routing and service orchestration
- **Technology**: FastAPI with async support
- **Features**: 
  - Request routing to microservices
  - Health monitoring endpoints
  - Authentication middleware
  - Performance optimization

### Accounts Service (`services/accounts/`)
- **Purpose**: User authentication and profile management
- **Technology**: FastAPI with SQLAlchemy
- **Features**:
  - User registration and login
  - Profile management
  - JWT token handling
  - Database integration

### Blog Service (`services/blog/`)
- **Purpose**: Content management system
- **Technology**: FastAPI with async database operations
- **Features**:
  - CRUD operations for blog posts
  - Content validation
  - Performance optimized queries
  - Cache integration

### Kubernetes Manifests (`k8s/`)
- **Phase 3 Features**:
  - Liveness and readiness probes
  - Resource requests and limits
  - Production-ready configurations
  - Advanced health monitoring

### Automation Scripts (`scripts/`)
- **deploy-phase3.sh**: Complete deployment automation
- **monitor-resources.sh**: Comprehensive system monitoring
- **test-performance.sh**: Load testing and performance validation
- **setup-kind.sh**: Kind cluster initialization

## 🔧 Configuration Management

### Environment Variables
- **Development**: Defined in docker-compose files
- **Production**: ConfigMaps and Secrets in Kubernetes
- **Testing**: Override configurations in scripts

### Resource Allocation
- **Gateway**: 100m CPU, 512Mi memory
- **Services**: 100m CPU, 512Mi memory each
- **Database**: 200m CPU, 1Gi memory
- **Cache**: 100m CPU, 256Mi memory

### Networking
- **NodePort Services**: External access (30000-30002)
- **ClusterIP Services**: Internal communication
- **Ingress**: NGINX-based routing for production

## 📊 Monitoring & Health

### Health Checks
- **Liveness Probes**: Automatic restart on failure
- **Readiness Probes**: Traffic routing control
- **Health Endpoints**: Manual verification

### Performance Monitoring
- **Resource Usage**: CPU and memory tracking
- **Response Times**: Sub-30ms targets
- **Uptime Monitoring**: 99.9% availability goals

### Automation
- **One-Command Deployment**: `make deploy-phase3`
- **Automated Testing**: Performance and connectivity tests
- **Resource Monitoring**: Real-time system analysis

## 🚀 Getting Started

1. **Clone and Setup**:
   ```bash
   git clone <repository>
   cd iodv3-backend
   ```

2. **Deploy Phase 3**:
   ```bash
   make deploy-phase3
   ```

3. **Monitor System**:
   ```bash
   make monitor-resources
   ```

4. **Test Performance**:
   ```bash
   make test-performance
   ```

## 📈 Future Enhancements

### Planned Features
- Horizontal Pod Autoscaling (HPA)
- Advanced monitoring with Prometheus
- CI/CD pipeline integration
- Multi-environment deployments

### Scalability Considerations
- Microservice decomposition ready
- Database sharding capability
- Load balancer optimization
- Resource scaling automation

---

*This project structure represents a production-ready microservices platform with comprehensive automation, monitoring, and scalability features.*
