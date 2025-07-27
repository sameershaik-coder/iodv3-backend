.PHONY: help install dev build test deploy clean setup-registry deploy-enhanced test-comprehensive kind-enhanced kind-status-enhanced

## Phase 1 Enhanced Commands

setup-registry: ## Setup local Docker registry for Kind
	./scripts/setup-registry.sh setup

registry-status: ## Check local registry status
	./scripts/setup-registry.sh status

registry-cleanup: ## Remove local Docker registry
	./scripts/setup-registry.sh cleanup

deploy-enhanced: ## Enhanced Kind deployment with automation
	./scripts/deploy-kind-enhanced.sh deploy

deploy-enhanced-build-only: ## Build and load images only (enhanced)
	./scripts/deploy-kind-enhanced.sh build-only

test-comprehensive: ## Run comprehensive test suite
	./scripts/test-comprehensive.sh all

test-quick: ## Run quick connectivity tests
	./scripts/test-comprehensive.sh quick

test-auth: ## Test authentication flow only
	./scripts/test-comprehensive.sh auth

test-db: ## Test database connectivity only
	./scripts/test-comprehensive.sh db

kind-enhanced: ## Complete enhanced deployment and test
	@echo "🚀 Starting Phase 1 enhanced deployment..."
	./scripts/deploy-kind-enhanced.sh deploy
	@echo ""
	@echo "🧪 Running comprehensive tests..."
	./scripts/test-comprehensive.sh all

kind-status-enhanced: ## Show enhanced cluster status
	./scripts/deploy-kind-enhanced.sh status

kind-cleanup-enhanced: ## Enhanced cleanup (cluster + registry)
	./scripts/deploy-kind-enhanced.sh cleanup

## Phase 2: Access Method Enhancement

deploy-phase2: ## Deploy Phase 2 enhancements (Ingress + host management)
	./scripts/deploy-phase2.sh

setup-hosts: ## Setup local domain resolution
	./scripts/setup-hosts.sh add

remove-hosts: ## Remove local domain resolution
	./scripts/setup-hosts.sh remove

show-hosts: ## Show current domain configuration
	./scripts/setup-hosts.sh show

test-hosts: ## Test domain resolution
	./scripts/setup-hosts.sh test

## Original Commands

install: ## Install dependencies with Poetry
	poetry install

dev-db: ## Start databases only (PostgreSQL and Redis)
	docker compose -f docker-compose.db.yaml up -d
	@echo "Databases started:"
	@echo "  PostgreSQL: localhost:5432 (user: postgres, password: password)"
	@echo "  Redis: localhost:6379"
	@echo ""
	@echo "Now run services with Poetry:"
	@echo "  Terminal 1: cd gateway && poetry run uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
	@echo "  Terminal 2: cd services/accounts && poetry run uvicorn main:app --host 0.0.0.0 --port 8001 --reload"
	@echo "  Terminal 3: cd services/blog && poetry run uvicorn main:app --host 0.0.0.0 --port 8002 --reload"

dev-local: ## Start services locally with Poetry (requires dev-db first)
	@echo "Starting services locally with Poetry..."
	@echo "Make sure databases are running: make dev-db"
	@echo ""
	@gnome-terminal --tab --title="Gateway" -- bash -c "cd gateway && poetry run uvicorn main:app --host 0.0.0.0 --port 8000 --reload; exec bash" || \
	echo "Could not open terminal tabs. Run manually:"
	@echo "  Terminal 1: cd gateway && poetry run uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
	@echo "  Terminal 2: cd services/accounts && poetry run uvicorn main:app --host 0.0.0.0 --port 8001 --reload"
	@echo "  Terminal 3: cd services/blog && poetry run uvicorn main:app --host 0.0.0.0 --port 8002 --reload"

dev: ## Start full development environment (simplified)
	@echo "Starting simplified development environment..."
	@echo "Step 1: Starting databases..."
	docker compose -f docker-compose.db.yaml up -d
	@echo ""
	@echo "Step 2: Waiting for databases to be ready..."
	@sleep 5
	@echo ""
	@echo "Databases are ready! Now start the services manually in separate terminals:"
	@echo "  Terminal 1: cd gateway && poetry run uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
	@echo "  Terminal 2: cd services/accounts && poetry run uvicorn main:app --host 0.0.0.0 --port 8001 --reload"
	@echo "  Terminal 3: cd services/blog && poetry run uvicorn main:app --host 0.0.0.0 --port 8002 --reload"
	@echo ""
	@echo "Or use: make dev-local"

dev-build: ## Build and start development environment (full Docker - may have issues)
	docker compose up -d --build
	@echo "Development environment built and started!"
	@echo "API Gateway: http://localhost:8000"
	@echo "Accounts Service: http://localhost:8001"
	@echo "Blog Service: http://localhost:8002"

dev-stop: ## Stop development environment
	docker compose down || docker compose -f docker-compose.db.yaml down

dev-restart: ## Restart development environment
	docker compose restart || docker compose -f docker-compose.db.yaml restart

dev-logs: ## Show development logs
	docker compose logs -f || docker compose -f docker-compose.db.yaml logs -f

dev-shell: ## Get shell access to a service (usage: make dev-shell service=postgres)
	@if [ -z "$(service)" ]; then \
		echo "Usage: make dev-shell service=<service_name>"; \
		echo "Available services: postgres, redis"; \
	else \
		docker compose -f docker-compose.db.yaml exec $(service) /bin/bash || docker compose -f docker-compose.db.yaml exec $(service) /bin/sh; \
	fi

# Kubernetes/Kind deployment commands
kind-cluster: ## Create Kind cluster for development
	@echo "Creating Kind cluster..."
	kind create cluster --config k8s/kind-config.yaml --name iodv3-dev
	@echo "Cluster created successfully!"
	@echo "Use 'kubectl cluster-info --context kind-iodv3-dev' to verify"

kind-delete: ## Delete Kind cluster
	kind delete cluster --name iodv3-dev
	@echo "Kind cluster deleted"

kind-build-images: ## Build Docker images for Kind deployment
	@echo "Building Docker images..."
	docker build -t iodv3/accounts-service:dev -f services/accounts/Dockerfile .
	docker build -t iodv3/blog-service:dev -f services/blog/Dockerfile .
	docker build -t iodv3/api-gateway:dev -f gateway/Dockerfile .
	@echo "Images built successfully!"

kind-load-images: ## Load Docker images into Kind cluster
	@echo "Loading images into Kind cluster..."
	kind load docker-image iodv3/accounts-service:dev --name iodv3-dev
	kind load docker-image iodv3/blog-service:dev --name iodv3-dev
	kind load docker-image iodv3/api-gateway:dev --name iodv3-dev
	@echo "Images loaded successfully!"

kind-deploy-k8s: ## Deploy Kubernetes manifests
	@echo "Deploying to Kubernetes..."
	kubectl apply -f k8s/dev/namespace.yaml
	kubectl apply -f k8s/dev/configmap.yaml
	kubectl apply -f k8s/dev/postgres.yaml
	kubectl apply -f k8s/dev/redis.yaml
	@echo "Waiting for databases to be ready..."
	kubectl wait --for=condition=ready pod -l app=postgres -n iodv3-dev --timeout=300s || true
	kubectl wait --for=condition=ready pod -l app=redis -n iodv3-dev --timeout=300s || true
	@echo "Deploying services..."
	kubectl apply -f k8s/dev/accounts-service.yaml
	kubectl apply -f k8s/dev/blog-service.yaml
	kubectl apply -f k8s/dev/api-gateway.yaml
	@echo "Waiting for services to be ready..."
	kubectl wait --for=condition=ready pod -l app=accounts-service -n iodv3-dev --timeout=300s || true
	kubectl wait --for=condition=ready pod -l app=blog-service -n iodv3-dev --timeout=300s || true
	kubectl wait --for=condition=ready pod -l app=api-gateway -n iodv3-dev --timeout=300s || true
	@echo "Deployment complete!"

kind-deploy: ## Full Kind deployment (create cluster, build, load, deploy)
	@echo "Starting full Kind deployment..."
	make kind-cluster
	make kind-build-images
	make kind-load-images
	make kind-deploy-k8s
	@echo ""
	@echo "🎉 Deployment complete!"
	@echo ""
	@echo "Services are accessible via NodePort:"
	@echo "  API Gateway:     http://localhost:30000"
	@echo "  Accounts Service: http://localhost:30001"
	@echo "  Blog Service:     http://localhost:30002"
	@echo ""
	@echo "Run 'make kind-ports' to see detailed access information"
	@echo "Run 'make kind-test' to test the deployment"

kind-update-image: ## Update specific service image (usage: make kind-update-image service=accounts)
	@if [ -z "$(service)" ]; then \
		echo "Usage: make kind-update-image service=<service_name>"; \
		echo "Available services: accounts, blog, gateway"; \
		exit 1; \
	fi
	@echo "Updating $(service) service image..."
	@if [ "$(service)" = "accounts" ]; then \
		docker build -t iodv3/accounts-service:dev -f services/accounts/Dockerfile .; \
		kind load docker-image iodv3/accounts-service:dev --name iodv3-dev; \
		kubectl rollout restart deployment/accounts-service -n iodv3-dev; \
	elif [ "$(service)" = "blog" ]; then \
		docker build -t iodv3/blog-service:dev -f services/blog/Dockerfile .; \
		kind load docker-image iodv3/blog-service:dev --name iodv3-dev; \
		kubectl rollout restart deployment/blog-service -n iodv3-dev; \
	elif [ "$(service)" = "gateway" ]; then \
		docker build -t iodv3/api-gateway:dev -f gateway/Dockerfile .; \
		kind load docker-image iodv3/api-gateway:dev --name iodv3-dev; \
		kubectl rollout restart deployment/api-gateway -n iodv3-dev; \
	else \
		echo "Invalid service name. Use: accounts, blog, or gateway"; \
		exit 1; \
	fi
	@echo "Service $(service) updated successfully!"

kind-rebuild-deploy: ## Rebuild all images and redeploy
	make kind-build-images
	make kind-load-images
	kubectl rollout restart deployment/accounts-service -n iodv3-dev
	kubectl rollout restart deployment/blog-service -n iodv3-dev
	kubectl rollout restart deployment/api-gateway -n iodv3-dev
	@echo "All services redeployed!"

kind-ports: ## Show service access information
	@echo "Service access information for Kind deployment:"
	@./scripts/access-services.sh

kind-status: ## Check Kind deployment status
	@echo "=== Cluster Info ==="
	kubectl cluster-info --context kind-iodv3-dev
	@echo ""
	@echo "=== Pods Status ==="
	kubectl get pods -n iodv3-dev
	@echo ""
	@echo "=== Services Status ==="
	kubectl get services -n iodv3-dev
	@echo ""
	@echo "=== Endpoints ==="
	kubectl get endpoints -n iodv3-dev

kind-logs: ## View logs for a specific service (usage: make kind-logs service=accounts)
	@if [ -z "$(service)" ]; then \
		echo "Usage: make kind-logs service=<service_name>"; \
		echo "Available services: accounts, blog, gateway, postgres, redis"; \
		exit 1; \
	fi
	kubectl logs -n iodv3-dev deployment/$(service)-service -f

kind-shell: ## Get shell access to a pod (usage: make kind-shell service=accounts)
	@if [ -z "$(service)" ]; then \
		echo "Usage: make kind-shell service=<service_name>"; \
		echo "Available services: accounts, blog, gateway, postgres, redis"; \
		exit 1; \
	fi
	kubectl exec -it -n iodv3-dev deployment/$(service) -- /bin/bash

kind-test: ## Test the Kind deployment
	@echo "Testing Kind deployment..."
	@./scripts/test-kind-deployment.sh

kind-clean: ## Clean up Kind deployment and resources
	@echo "Cleaning up Kind deployment..."
	@pkill -f "kubectl port-forward" || true
	make kind-delete
	@echo "Cleanup complete!"

build: ## Build Docker images
	./scripts/build.sh

test: ## Run tests
	docker compose exec accounts-service poetry run pytest /app/tests/ -v || \
	poetry run pytest tests/ -v

test-accounts: ## Run tests for accounts service
	docker compose exec accounts-service poetry run pytest /app/tests/test_accounts.py -v

test-gateway: ## Run tests for gateway
	docker compose exec api-gateway poetry run pytest /app/tests/test_gateway.py -v

test-integration: ## Run integration tests against running services
	./scripts/test.sh

deploy-dev: ## Deploy to development environment
	./scripts/deploy.sh dev

deploy-qa: ## Deploy to QA environment
	./scripts/deploy.sh qa

k8s-create: ## Create Kind cluster
	kind create cluster --config k8s/kind-config.yaml

k8s-delete: ## Delete Kind cluster
	kind delete cluster --name iodv3-cluster

k8s-status: ## Show Kubernetes status
	@echo "=== Development Environment ==="
	kubectl get all -n iodv3-dev 2>/dev/null || echo "Dev environment not deployed"
	@echo ""
	@echo "=== QA Environment ==="
	kubectl get all -n iodv3-qa 2>/dev/null || echo "QA environment not deployed"

clean: ## Clean up development environment
	docker compose down -v
	docker system prune -f
	docker volume prune -f

db-reset: ## Reset databases (WARNING: This will delete all data)
	docker compose stop postgres
	docker compose rm -f postgres
	docker volume rm iodv3-backend_postgres_data || true
	docker compose up -d postgres
	@echo "Database reset complete. Waiting for PostgreSQL to be ready..."
	@sleep 10

db-shell: ## Access PostgreSQL shell
	docker compose exec postgres psql -U postgres

redis-shell: ## Access Redis shell
	docker compose exec redis redis-cli

logs-accounts: ## Show accounts service logs
	docker compose logs -f accounts-service

logs-blog: ## Show blog service logs
	docker compose logs -f blog-service

logs-gateway: ## Show gateway logs
	docker compose logs -f api-gateway

logs-db: ## Show database logs
	docker compose logs -f postgres redis

lint: ## Run linting
	poetry run black --check .
	poetry run isort --check-only .
	poetry run flake8 .

format: ## Format code
	poetry run black .
	poetry run isort .

setup: install ## Setup project for development
	@echo "Project setup complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Copy .env.example to .env and update values"
	@echo "2. Run 'make dev' to start development environment"
	@echo "3. Run 'make test' to run tests"

help: ## Show this help message
	@echo "IOD V3 Backend - Available Commands:"
	@echo ""
	@echo "� Phase 1 Enhanced (Recommended):"
	@grep -E '^[a-zA-Z_-]+.*?## .*$$' $(MAKEFILE_LIST) | grep -E '^(setup-registry|deploy-enhanced|test-comprehensive|test-quick|kind-enhanced)' | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "�📦 Development (Docker Compose):"
	@grep -E '^[a-zA-Z_-]+.*?## .*$$' $(MAKEFILE_LIST) | grep -E '^(dev|install)' | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "☸️  Kubernetes (Kind):"
	@grep -E '^[a-zA-Z_-]+.*?## .*$$' $(MAKEFILE_LIST) | grep '^kind' | head -10 | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🧪 Testing & Quality:"
	@grep -E '^[a-zA-Z_-]+.*?## .*$$' $(MAKEFILE_LIST) | grep -E '^(test)' | head -8 | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🛠️  Setup & Utilities:"
	@grep -E '^[a-zA-Z_-]+.*?## .*$$' $(MAKEFILE_LIST) | grep -E '^(registry|help|clean)' | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "📖 Quick Start:"
	@echo "  🚀 Enhanced (Phase 1):    make kind-enhanced"
	@echo "  📦 Docker Development:    make dev-db && start services with Poetry"
	@echo "  ☸️  Basic Kind:           make kind-deploy && make kind-ports"
	@echo ""
	@echo "💡 Tip: Use 'make kind-enhanced' for the best experience with automation and testing!"

.PHONY: help
.DEFAULT_GOAL := help
