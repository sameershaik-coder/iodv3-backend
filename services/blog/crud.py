from sqlalchemy.orm import Session
from datetime import datetime
from . import models, schemas

def get_blog(db: Session, blog_id: int):
    return db.query(models.Blog).filter(models.Blog.id == blog_id).first()

def get_blogs(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Blog).offset(skip).limit(limit).all()

def get_published_blogs(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Blog).filter(
        models.Blog.is_published == True
    ).offset(skip).limit(limit).all()

def get_published_blog(db: Session, blog_id: int):
    return db.query(models.Blog).filter(
        models.Blog.id == blog_id,
        models.Blog.is_published == True
    ).first()

def create_blog(db: Session, blog: schemas.BlogCreate, author_id: int):
    db_blog = models.Blog(
        title=blog.title,
        content=blog.content,
        summary=blog.summary,
        is_published=blog.is_published,
        author_id=author_id,
        published_at=datetime.utcnow() if blog.is_published else None
    )
    db.add(db_blog)
    db.commit()
    db.refresh(db_blog)
    return db_blog

def update_blog(db: Session, blog_id: int, blog_update: schemas.BlogUpdate):
    db_blog = db.query(models.Blog).filter(models.Blog.id == blog_id).first()
    if db_blog:
        update_data = blog_update.dict(exclude_unset=True)
        
        # If publishing for the first time, set published_at
        if "is_published" in update_data and update_data["is_published"] and not db_blog.is_published:
            update_data["published_at"] = datetime.utcnow()
        # If unpublishing, clear published_at
        elif "is_published" in update_data and not update_data["is_published"]:
            update_data["published_at"] = None
        
        for key, value in update_data.items():
            setattr(db_blog, key, value)
        
        db.commit()
        db.refresh(db_blog)
    return db_blog

def delete_blog(db: Session, blog_id: int):
    db_blog = db.query(models.Blog).filter(models.Blog.id == blog_id).first()
    if db_blog:
        db.delete(db_blog)
        db.commit()
    return db_blog
