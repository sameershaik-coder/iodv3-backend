# IOD V3 Backend - Microservices Architecture

make kind-deploy-k8s

# Check status
make kind-status

# View logs
make kind-logs service=accounts
make kind-logs service=blog
make kind-logs service=gateway

# Run tests
./scripts/test-kind-deployment.sh

# Access services
./scripts/access-services.sh

# Clean up
make kind-clean


A microservices-based backend system with FastAPI, PostgreSQL, and Kubernetes deployment.

## Architecture

- **API Gateway**: Single entry point routing requests to microservices
- **Accounts Service**: User management with JWT authentication
- **Blog Service**: Blog CRUD operations (admin only)
- **PostgreSQL**: Database for each service
- **Redis**: Caching and session management

## Services

### 1. API Gateway
- Single port entry point (8000)
- Routes requests to appropriate microservices
- Handles authentication middleware

### 2. Accounts Service
- User CRUD operations
- JWT authentication
- Password encryption
- User signup, edit, delete

### 3. Blog Service
- Blog CRUD operations
- Admin-only access
- Content management

## Development Setup

### Prerequisites
- Docker
- Kind (Kubernetes in Docker)
- kubectl
- Python 3.11+
- Poetry

### Quick Start

1. Install dependencies:
```bash
poetry install
```

2. Start development environment:
```bash
docker-compose up -d
```

3. Run services locally:
```bash
# Terminal 1 - API Gateway
cd gateway && poetry run uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# Terminal 2 - Accounts Service
cd services/accounts && poetry run uvicorn main:app --host 0.0.0.0 --port 8001 --reload

# Terminal 3 - Blog Service
cd services/blog && poetry run uvicorn main:app --host 0.0.0.0 --port 8002 --reload
```

### Kubernetes Deployment

1. Create Kind cluster:
```bash
kind create cluster --config k8s/kind-config.yaml
```

2. Deploy to development:
```bash
kubectl apply -f k8s/dev/
```

3. Deploy to QA:
```bash
kubectl apply -f k8s/qa/
```

## API Endpoints

### Authentication
- POST `/auth/signup` - User registration
- POST `/auth/login` - User login
- POST `/auth/refresh` - Refresh token

### Users
- GET `/users/me` - Get current user
- PUT `/users/me` - Update current user
- DELETE `/users/me` - Delete current user

### Blogs (Admin only)
- GET `/blogs/` - List all blogs
- POST `/blogs/` - Create blog
- GET `/blogs/{blog_id}` - Get blog by ID
- PUT `/blogs/{blog_id}` - Update blog
- DELETE `/blogs/{blog_id}` - Delete blog

## Environment Variables

See `.env.example` for required environment variables.
