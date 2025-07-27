import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch

from gateway.main import app

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "IOD V3 API Gateway"
    assert data["version"] == "1.0.0"

@patch('httpx.AsyncClient')
def test_health_check(mock_client):
    # Mock the async client responses
    mock_response = AsyncMock()
    mock_response.status_code = 200
    mock_client.return_value.__aenter__.return_value.get.return_value = mock_response
    
    response = client.get("/health")
    assert response.status_code == 200

def test_auth_proxy_route_exists():
    # Test that auth routes are properly set up (even if they fail without backend)
    response = client.post("/auth/signup")
    # Should get a connection error or similar, not a 404
    assert response.status_code != 404

def test_users_proxy_route_exists():
    # Test that user routes are properly set up
    response = client.get("/users/me")
    # Should get a connection error or similar, not a 404
    assert response.status_code != 404

def test_blogs_proxy_route_exists():
    # Test that blog routes are properly set up
    response = client.get("/blogs/")
    # Should get a connection error or similar, not a 404
    assert response.status_code != 404
