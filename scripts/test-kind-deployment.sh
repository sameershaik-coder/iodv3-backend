#!/bin/bash

echo "=== IOD V3 Kind Deployment Test ==="
echo ""

# Check if services are accessible
check_service() {
    local service_name=$1
    local url=$2
    
    if curl -s "$url" > /dev/null; then
        echo "✅ $service_name is accessible"
        return 0
    else
        echo "❌ $service_name is not accessible"
        return 1
    fi
}

echo "1. Checking service accessibility..."
check_service "API Gateway" "http://localhost:30000/health"
check_service "Accounts Service" "http://localhost:30001/health"
check_service "Blog Service" "http://localhost:30002/health"
echo ""

echo "2. Testing API Gateway health..."
HEALTH_RESPONSE=$(curl -s http://localhost:30000/health)
if [ $? -eq 0 ]; then
    echo "$HEALTH_RESPONSE" | python3 -m json.tool
else
    echo "❌ Failed to get health status"
    exit 1
fi
echo ""

echo "3. Testing user signup..."
SIGNUP_RESPONSE=$(curl -s -X POST http://localhost:30000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Kind Test User",
    "email": "kindtest@example.com", 
    "password": "testpassword123"
  }')

if echo "$SIGNUP_RESPONSE" | grep -q "email"; then
    echo "✅ User signup successful"
    echo "$SIGNUP_RESPONSE" | python3 -m json.tool
else
    echo "⚠️  User signup response: $SIGNUP_RESPONSE"
fi
echo ""

echo "4. Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:30000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "kindtest@example.com",
    "password": "testpassword123"
  }')

if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
    echo "✅ User login successful"
    # Extract token
    TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.loads(sys.stdin.read().strip('\"'))
    print(data.get('access_token', ''))
except:
    print('')
" 2>/dev/null)
    
    if [ ! -z "$TOKEN" ]; then
        echo "✅ Token extracted successfully"
        
        echo ""
        echo "5. Testing protected endpoint..."
        USER_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:30000/users/me)
        if echo "$USER_RESPONSE" | grep -q "email"; then
            echo "✅ Protected endpoint accessible"
            echo "$USER_RESPONSE" | python3 -m json.tool
        else
            echo "❌ Protected endpoint failed: $USER_RESPONSE"
        fi
        
        echo ""
        echo "6. Testing blog creation..."
        BLOG_RESPONSE=$(curl -s -X POST http://localhost:30000/blogs \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d '{
            "title": "Kind Test Blog Post",
            "content": "This is a test blog post created in Kind deployment.",
            "author": "Kind Test User"
          }')
        
        if echo "$BLOG_RESPONSE" | grep -q "Admin access required\|title"; then
            echo "✅ Blog endpoint responding (may require admin access)"
            echo "$BLOG_RESPONSE" | python3 -m json.tool
        else
            echo "❌ Blog creation failed: $BLOG_RESPONSE"
        fi
        
    else
        echo "❌ Failed to extract token"
    fi
else
    echo "❌ User login failed: $LOGIN_RESPONSE"
fi

echo ""
echo "7. Testing blog list (public endpoint)..."
BLOGS_RESPONSE=$(curl -s http://localhost:30000/blogs)
if [ $? -eq 0 ]; then
    echo "✅ Blog list endpoint accessible"
    echo "$BLOGS_RESPONSE" | python3 -m json.tool
else
    echo "❌ Blog list endpoint failed"
fi

echo ""
echo "=== Test Complete ==="
echo ""
echo "To check Kubernetes status:"
echo "  make kind-status"
echo ""
echo "To view logs:"
echo "  make kind-logs service=accounts"
echo "  make kind-logs service=blog"
echo "  make kind-logs service=gateway"
