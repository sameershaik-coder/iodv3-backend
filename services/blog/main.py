from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import httpx
import os
from typing import Optional

import models, schemas, crud
from database import SessionLocal, engine

# Create tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Blog Service",
    description="Blog management service",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

ACCOUNTS_SERVICE_URL = os.getenv("ACCOUNTS_SERVICE_URL", "http://localhost:8001")

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def get_current_user(token: HTTPAuthorizationCredentials = Depends(security)):
    """Verify user with accounts service"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{ACCOUNTS_SERVICE_URL}/auth/verify",
                headers={"Authorization": f"Bearer {token.credentials}"}
            )
            if response.status_code == 200:
                user_data = response.json()
                return user_data
            else:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Could not validate credentials",
                    headers={"WWW-Authenticate": "Bearer"},
                )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

def require_admin(current_user: dict = Depends(get_current_user)):
    """Ensure user is admin"""
    if not current_user.get("is_admin", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required"
        )
    return current_user

@app.get("/")
async def root():
    return {"message": "Blog Service", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "blog"}

# Blog endpoints (all require admin access)
@app.get("/blogs/", response_model=list[schemas.Blog])
def read_blogs(
    skip: int = 0,
    limit: int = 100,
    current_user: dict = Depends(require_admin),
    db: Session = Depends(get_db)
):
    blogs = crud.get_blogs(db, skip=skip, limit=limit)
    return blogs

@app.post("/blogs/", response_model=schemas.Blog)
def create_blog(
    blog: schemas.BlogCreate,
    current_user: dict = Depends(require_admin),
    db: Session = Depends(get_db)
):
    return crud.create_blog(db=db, blog=blog, author_id=current_user["id"])

@app.get("/blogs/{blog_id}", response_model=schemas.Blog)
def read_blog(
    blog_id: int,
    current_user: dict = Depends(require_admin),
    db: Session = Depends(get_db)
):
    db_blog = crud.get_blog(db, blog_id=blog_id)
    if db_blog is None:
        raise HTTPException(status_code=404, detail="Blog not found")
    return db_blog

@app.put("/blogs/{blog_id}", response_model=schemas.Blog)
def update_blog(
    blog_id: int,
    blog_update: schemas.BlogUpdate,
    current_user: dict = Depends(require_admin),
    db: Session = Depends(get_db)
):
    db_blog = crud.update_blog(db=db, blog_id=blog_id, blog_update=blog_update)
    if db_blog is None:
        raise HTTPException(status_code=404, detail="Blog not found")
    return db_blog

@app.delete("/blogs/{blog_id}")
def delete_blog(
    blog_id: int,
    current_user: dict = Depends(require_admin),
    db: Session = Depends(get_db)
):
    db_blog = crud.delete_blog(db=db, blog_id=blog_id)
    if db_blog is None:
        raise HTTPException(status_code=404, detail="Blog not found")
    return {"message": "Blog deleted successfully"}

# Public endpoints (no authentication required)
@app.get("/blogs/public/", response_model=list[schemas.BlogPublic])
def read_public_blogs(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get published blogs for public viewing"""
    blogs = crud.get_published_blogs(db, skip=skip, limit=limit)
    return blogs

@app.get("/blogs/public/{blog_id}", response_model=schemas.BlogPublic)
def read_public_blog(blog_id: int, db: Session = Depends(get_db)):
    """Get a specific published blog for public viewing"""
    db_blog = crud.get_published_blog(db, blog_id=blog_id)
    if db_blog is None:
        raise HTTPException(status_code=404, detail="Blog not found")
    return db_blog

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
