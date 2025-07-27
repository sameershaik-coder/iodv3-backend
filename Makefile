.PHONY: help install dev build test deploy clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

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
