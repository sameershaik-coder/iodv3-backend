from sqlalchemy import Boolean, Column, String, DateTime, ForeignKey, Table, Integer
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base
import uuid
from datetime import datetime

# Association table for blog tags
blog_tags = Table('blog_tags', Base.metadata,
    Column('blog_id', UUID(as_uuid=True), ForeignKey('blogs.id')),
    Column('tag', String)
)

class Blog(Base):
    __tablename__ = "blogs"

    id = Column(UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4)
    title = Column(String, index=True)
    slug = Column(String, unique=True, index=True)
    content = Column(String)
    author_id = Column(String, index=True)  # This will store the user ID from accounts service
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    status = Column(String, default="draft")  # draft or published
    tags = relationship("Tag", secondary=blog_tags, backref="blogs")
    is_deleted = Column(Boolean, default=False)

class Tag(Base):
    __tablename__ = "tags"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
