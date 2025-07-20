from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="Accounts Microservice",
    description="Handles user accounts and authentication",
    version="1.0.0"
)

# CORS Configuration
origins = [
    "http://localhost",
    "http://localhost:3000",  # React frontend
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import and include routers
from app.api import users, auth

app.include_router(auth.router, tags=["authentication"])
app.include_router(users.router, prefix="/users", tags=["users"])

@app.get("/health")
def health_check():
    return {"status": "healthy"}
