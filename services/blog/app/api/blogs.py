from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.blog import Blog as BlogModel, Tag as TagModel
from app.schemas.blog import BlogCreate, Blog, BlogUpdate, BlogList
from sqlalchemy import and_
from datetime import datetime
from slugify import slugify

router = APIRouter()

@router.post("/", response_model=Blog)
async def create_blog(
    blog: BlogCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    db_blog = BlogModel(
        title=blog.title,
        slug=slugify(blog.title),
        content=blog.content,
        author_id=current_user["id"],
        tags=blog.tags
    )
    db.add(db_blog)
    db.commit()
    db.refresh(db_blog)
    return db_blog

@router.get("/", response_model=BlogList)
async def list_blogs(
    page: int = Query(1, gt=0),
    size: int = Query(10, gt=0, le=100),
    tag: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    query = db.query(BlogModel).filter(BlogModel.is_deleted == False)
    
    if tag:
        query = query.filter(BlogModel.tags.any(tag))
    if status:
        query = query.filter(BlogModel.status == status)
    
    total = query.count()
    blogs = query.offset((page - 1) * size).limit(size).all()
    
    return BlogList(
        items=blogs,
        total=total,
        page=page,
        size=size
    )

@router.get("/{blog_id}", response_model=Blog)
async def get_blog(blog_id: str, db: Session = Depends(get_db)):
    blog = db.query(BlogModel).filter(
        and_(BlogModel.id == blog_id, BlogModel.is_deleted == False)
    ).first()
    if not blog:
        raise HTTPException(status_code=404, detail="Blog not found")
    return blog

@router.put("/{blog_id}", response_model=Blog)
async def update_blog(
    blog_id: str,
    blog_update: BlogUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    db_blog = db.query(BlogModel).filter(
        and_(BlogModel.id == blog_id, BlogModel.is_deleted == False)
    ).first()
    if not db_blog:
        raise HTTPException(status_code=404, detail="Blog not found")
    
    if db_blog.author_id != current_user["id"]:
        raise HTTPException(status_code=403, detail="Not authorized to update this blog")
    
    for field, value in blog_update.dict(exclude_unset=True).items():
        setattr(db_blog, field, value)
    
    db_blog.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_blog)
    return db_blog

@router.delete("/{blog_id}")
async def delete_blog(
    blog_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    db_blog = db.query(BlogModel).filter(
        and_(BlogModel.id == blog_id, BlogModel.is_deleted == False)
    ).first()
    if not db_blog:
        raise HTTPException(status_code=404, detail="Blog not found")
    
    if db_blog.author_id != current_user["id"]:
        raise HTTPException(status_code=403, detail="Not authorized to delete this blog")
    
    db_blog.is_deleted = True
    db.commit()
    return {"detail": "Blog deleted successfully"}

@router.get("/user/{user_id}", response_model=BlogList)
async def get_user_blogs(
    user_id: str,
    page: int = Query(1, gt=0),
    size: int = Query(10, gt=0, le=100),
    db: Session = Depends(get_db)
):
    query = db.query(BlogModel).filter(
        and_(BlogModel.author_id == user_id, BlogModel.is_deleted == False)
    )
    
    total = query.count()
    blogs = query.offset((page - 1) * size).limit(size).all()
    
    return BlogList(
        items=blogs,
        total=total,
        page=page,
        size=size
    )
