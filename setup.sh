#!/bin/bash

# Add Poetry to PATH if not already added
if [[ ":$PATH:" != *":/home/ioduser/.local/bin:"* ]]; then
    export PATH="/home/ioduser/.local/bin:$PATH"
fi

# Create a .env file if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env file from .env.example"
    echo "Please update the environment variables in .env file"
fi

echo "IOD V3 Backend project setup complete!"
echo ""
echo "Available commands:"
echo "  make help        - Show all available commands"
echo "  make dev         - Start development environment"
echo "  make test        - Run tests"
echo "  make deploy-dev  - Deploy to development K8s"
echo "  make deploy-qa   - Deploy to QA K8s"
echo ""
echo "Project structure created successfully with:"
echo "✓ API Gateway (port 8000)"
echo "✓ Accounts Service (port 8001) with JWT authentication"
echo "✓ Blog Service (port 8002) with admin-only access"
echo "✓ PostgreSQL databases for each service"
echo "✓ Redis for caching"
echo "✓ Kubernetes deployment files for dev and QA"
echo "✓ Docker Compose for local development"
echo "✓ Poetry for dependency management"
echo "✓ Testing setup"
echo ""
echo "Next steps:"
echo "1. Update .env file with your configuration"
echo "2. Run 'make dev' to start development environment"
echo "3. Test the API at http://localhost:8000"
