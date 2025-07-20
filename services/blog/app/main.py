from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import blogs

app = FastAPI(
    title="Blog Microservice",
    description="Handles blog posts and related operations",
    version="1.0.0"
)

# CORS Configuration
origins = [
    "http://localhost",
    "http://localhost:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(blogs.router, prefix="/blogs", tags=["blogs"])

@app.get("/health")
def health_check():
    return {"status": "healthy"}
