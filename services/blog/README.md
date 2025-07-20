# Blog Microservice

This microservice handles blog post management and related operations. It's built using FastAPI and SQLite, with JWT authentication via the Accounts service.

## Features

- Blog CRUD operations
- Tag management
- User-specific blog listings
- Authentication via Accounts service
- RESTful API design
- Docker support
- Kubernetes deployment ready

## Prerequisites

- Python 3.11+
- Docker (for containerization)
- Kubernetes cluster (for deployment)
- Running instance of Accounts service

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
   DATABASE_URL=sqlite:///./blog.db
   ACCOUNTS_SERVICE_URL=http://localhost:8000
   ```

4. Run the application:
   ```bash
   uvicorn app.main:app --reload --port 8001
   ```

The API will be available at http://localhost:8001

## Docker Setup

1. Build the Docker image:
   ```bash
   docker build -t blog-service .
   ```

2. Run the container:
   ```bash
   docker run -p 8001:8000 blog-service
   ```

## Kubernetes Deployment

1. Apply the Kubernetes manifests:
   ```bash
   kubectl apply -f kubernetes/
   ```

2. Verify the deployment:
   ```bash
   kubectl get pods -l app=blog-service
   kubectl get service blog-service
   ```

## API Documentation

Once the service is running, you can access the API documentation at:
- Swagger UI: http://localhost:8001/docs
- ReDoc: http://localhost:8001/redoc

## API Endpoints

### Blogs
- POST /blogs - Create new blog
- GET /blogs - List all blogs
- GET /blogs/{id} - Get single blog
- PUT /blogs/{id} - Update blog
- DELETE /blogs/{id} - Delete blog
- GET /blogs/user/{user_id} - Get user's blogs

## Testing

Run the tests with:
```bash
pytest
```

## Directory Structure

```
blog/
├── app/
│   ├── api/
│   │   └── blogs.py
│   ├── core/
│   │   ├── database.py
│   │   └── auth.py
│   ├── models/
│   │   └── blog.py
│   ├── schemas/
│   │   └── blog.py
│   └── main.py
├── kubernetes/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── config.yaml
├── tests/
├── Dockerfile
└── requirements.txt
```
