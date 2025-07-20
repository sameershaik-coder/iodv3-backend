# Accounts Microservice

This microservice handles user account management and authentication for the system. It's built using FastAPI and SQLite, with JWT authentication.

## Features

- User registration and management
- JWT-based authentication
- RESTful API design
- Docker support
- Kubernetes deployment ready

## Prerequisites

- Python 3.11+
- Docker (for containerization)
- Kubernetes cluster (for deployment)

## Local Development Setup

1. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Create a `.env` file:
   ```
   DATABASE_URL=sqlite:///./accounts.db
   SECRET_KEY=your-secret-key-for-development
   ```

4. Run the application:
   ```bash
   uvicorn app.main:app --reload
   ```

The API will be available at http://localhost:8000

## Docker Setup

1. Build the Docker image:
   ```bash
   docker build -t accounts-service .
   ```

2. Run with Docker Compose:
   ```bash
   docker-compose up
   ```

## Kubernetes Deployment

1. Apply the Kubernetes manifests:
   ```bash
   kubectl apply -f kubernetes/
   ```

2. Verify the deployment:
   ```bash
   kubectl get pods
   kubectl get services
   ```

## API Documentation

Once the service is running, you can access the API documentation at:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API Endpoints

### Authentication
- POST /token - Get access token

### Users
- POST /users - Create new user
- GET /users/me - Get current user
- PUT /users/me - Update current user
- DELETE /users/me - Delete current user

## Testing

Run the tests with:
```bash
pytest
```

## Directory Structure

```
accounts/
├── app/
│   ├── api/
│   │   ├── auth.py
│   │   └── users.py
│   ├── core/
│   │   ├── database.py
│   │   └── security.py
│   ├── models/
│   │   └── user.py
│   ├── schemas/
│   │   └── user.py
│   └── main.py
├── kubernetes/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── config.yaml
├── tests/
├── Dockerfile
├── docker-compose.yml
└── requirements.txt
```
