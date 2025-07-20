from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from uuid import UUID

class TagBase(BaseModel):
    name: str

class TagCreate(TagBase):
    pass

class Tag(TagBase):
    id: int

    class Config:
        orm_mode = True

class BlogBase(BaseModel):
    title: str
    content: str
    tags: List[str] = []

class BlogCreate(BlogBase):
    pass

class BlogUpdate(BlogBase):
    status: Optional[str] = "draft"

class Blog(BlogBase):
    id: UUID
    slug: str
    author_id: str
    created_at: datetime
    updated_at: datetime
    status: str
    tags: List[str]
    is_deleted: bool = False

    class Config:
        orm_mode = True

class BlogList(BaseModel):
    items: List[Blog]
    total: int
    page: int
    size: int

class BlogResponse(Blog):
    pass
