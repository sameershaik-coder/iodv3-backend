from typing import Optional, Dict
import httpx
from fastapi import HTTPException, Depends
from fastapi.security import OAuth2PasswordBearer
import os
from dotenv import load_dotenv

load_dotenv()

ACCOUNTS_SERVICE_URL = os.getenv("ACCOUNTS_SERVICE_URL", "http://accounts-service:8000")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{ACCOUNTS_SERVICE_URL}/token")

async def verify_token(token: str) -> Dict:
    """Verify JWT token with accounts service"""
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{ACCOUNTS_SERVICE_URL}/users/me",
                headers={"Authorization": f"Bearer {token}"}
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError:
            raise HTTPException(
                status_code=401,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )

async def get_current_user(token: str = Depends(oauth2_scheme)) -> Dict:
    """Get current user from token"""
    user = await verify_token(token)
    return user
