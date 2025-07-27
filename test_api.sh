#!/bin/bash

echo "=== IOD V3 Backend API Test ==="
echo ""

# Test API Gateway
echo "1. Testing API Gateway health..."
curl -s http://localhost:8000/health | python3 -m json.tool
echo ""

# Test user signup
echo "2. Testing user signup..."
SIGNUP_RESPONSE=$(curl -s -X POST http://localhost:8000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Test User",
    "email": "test@example.com", 
    "password": "testpassword123"
  }')

echo $SIGNUP_RESPONSE | python3 -m json.tool
echo ""

# Test user login
echo "3. Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }')

echo $LOGIN_RESPONSE | python3 -m json.tool

# Extract token for further tests
TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; data=json.loads(sys.stdin.read().strip('\"')); print(data.get('access_token', ''))" 2>/dev/null)

if [ ! -z "$TOKEN" ]; then
    echo ""
    echo "4. Testing protected endpoint with token..."
    curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8000/users/me | python3 -m json.tool
    echo ""
    
    echo "5. Testing blog creation (admin required)..."
    curl -s -X POST http://localhost:8000/blogs \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "title": "Test Blog Post",
        "content": "This is a test blog post created via the API.",
        "author": "Test User"
      }' | python3 -m json.tool
    echo ""
    
    echo "6. Testing blog list..."
    curl -s http://localhost:8000/blogs | python3 -m json.tool
else
    echo "Login failed, skipping authenticated tests"
fi

echo ""
echo "=== Test Complete ==="
