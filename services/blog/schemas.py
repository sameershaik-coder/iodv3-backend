from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class BlogBase(BaseModel):
    title: str
    content: str
    summary: Optional[str] = None
    is_published: bool = False

class BlogCreate(BlogBase):
    pass

class BlogUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    summary: Optional[str] = None
    is_published: Optional[bool] = None

class Blog(BlogBase):
    id: int
    author_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    published_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class BlogPublic(BaseModel):
    """Public view of blog (no author_id exposed)"""
    id: int
    title: str
    content: str
    summary: Optional[str] = None
    published_at: Optional[datetime] = None

    class Config:
        from_attributes = True
