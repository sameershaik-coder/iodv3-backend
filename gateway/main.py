from fastapi import FastAPI, Request, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import httpx
import os
from typing import Optional
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="IOD V3 API Gateway",
    description="API Gateway for IOD V3 Microservices",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer(auto_error=False)

# Service URLs
ACCOUNTS_SERVICE_URL = os.getenv("ACCOUNTS_SERVICE_URL", "http://localhost:8001")
BLOG_SERVICE_URL = os.getenv("BLOG_SERVICE_URL", "http://localhost:8002")

async def get_current_user(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)):
    """Validate JWT token with accounts service"""
    if not credentials:
        return None
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{ACCOUNTS_SERVICE_URL}/auth/verify",
                headers={"Authorization": f"Bearer {credentials.credentials}"}
            )
            if response.status_code == 200:
                return response.json()
            return None
    except Exception as e:
        logger.error(f"Error validating token: {e}")
        return None

async def proxy_request(request: Request, service_url: str, path: str):
    """Proxy request to the appropriate microservice"""
    try:
        async with httpx.AsyncClient() as client:
            # Prepare headers
            headers = dict(request.headers)
            headers.pop("host", None)  # Remove host header
            
            # Get request body
            body = await request.body()
            
            # Make request to microservice
            response = await client.request(
                method=request.method,
                url=f"{service_url}{path}",
                headers=headers,
                content=body,
                params=request.query_params
            )
            
            return {
                "status_code": response.status_code,
                "content": response.content,
                "headers": dict(response.headers)
            }
    except Exception as e:
        logger.error(f"Error proxying request: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/")
async def root():
    return {"message": "IOD V3 API Gateway", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Check accounts service
        async with httpx.AsyncClient() as client:
            accounts_response = await client.get(f"{ACCOUNTS_SERVICE_URL}/health", timeout=5.0)
            blog_response = await client.get(f"{BLOG_SERVICE_URL}/health", timeout=5.0)
            
        return {
            "status": "healthy",
            "services": {
                "accounts": accounts_response.status_code == 200,
                "blog": blog_response.status_code == 200
            }
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {"status": "unhealthy", "error": str(e)}

# Auth routes (proxy to accounts service)
@app.api_route("/auth/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def auth_proxy(request: Request, path: str):
    result = await proxy_request(request, ACCOUNTS_SERVICE_URL, f"/auth/{path}")
    return result["content"]

# Users routes (proxy to accounts service)
@app.api_route("/users/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def users_proxy(request: Request, path: str):
    result = await proxy_request(request, ACCOUNTS_SERVICE_URL, f"/users/{path}")
    return result["content"]

# Blog routes (proxy to blog service)
@app.api_route("/blogs/{path:path}", methods=["GET", "POST", "PUT", "DELETE"])
async def blogs_proxy(request: Request, path: str):
    result = await proxy_request(request, BLOG_SERVICE_URL, f"/blogs/{path}")
    return result["content"]

@app.api_route("/blogs", methods=["GET", "POST"])
async def blogs_root_proxy(request: Request):
    result = await proxy_request(request, BLOG_SERVICE_URL, "/blogs")
    return result["content"]

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
