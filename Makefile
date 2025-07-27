.PHONY: help install dev build test deploy clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies with Poetry
	poetry install

dev: ## Start development environment with docker-compose
	docker-compose up -d
	@echo "Development environment started!"
	@echo "API Gateway: http://localhost:8000"
	@echo "Accounts Service: http://localhost:8001"
	@echo "Blog Service: http://localhost:8002"

dev-stop: ## Stop development environment
	docker-compose down

dev-logs: ## Show development logs
	docker-compose logs -f

build: ## Build Docker images
	./scripts/build.sh

test: ## Run tests
	poetry run pytest tests/ -v

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
	docker-compose down -v
	docker system prune -f

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
