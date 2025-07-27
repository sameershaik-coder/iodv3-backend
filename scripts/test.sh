#!/bin/bash

# Test script for IOD V3 Backend

set -e

BASE_URL=${1:-http://localhost:8000}

echo "Testing IOD V3 Backend at $BASE_URL"

# Test health endpoints
echo "1. Testing health endpoints..."
curl -s "$BASE_URL/health" | jq .
echo ""

# Test user signup
echo "2. Testing user signup..."
SIGNUP_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "full_name": "Admin User",
    "password": "admin123"
  }')

echo $SIGNUP_RESPONSE | jq .
echo ""

# Test user login
echo "3. Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }')

echo $LOGIN_RESPONSE | jq .

# Extract token
TOKEN=$(echo $LOGIN_RESPONSE | jq -r .access_token)

if [ "$TOKEN" = "null" ]; then
    echo "Login failed, cannot continue with authenticated tests"
    exit 1
fi

echo ""

# Test get current user
echo "4. Testing get current user..."
curl -s -H "Authorization: Bearer $TOKEN" "$BASE_URL/users/me" | jq .
echo ""

# Note: To test blog endpoints, the user needs to be an admin
# You would need to manually update the user in the database to set is_admin=true

echo "Basic tests completed!"
echo ""
echo "To test blog endpoints, you need to:"
echo "1. Connect to the database"
echo "2. Update the user to be an admin: UPDATE users SET is_admin = true WHERE email = 'admin@example.com';"
echo "3. Then test blog creation:"
echo "curl -s -X POST '$BASE_URL/blogs/' -H 'Authorization: Bearer $TOKEN' -H 'Content-Type: application/json' -d '{\"title\": \"Test Blog\", \"content\": \"This is a test blog post\", \"is_published\": true}'"
