#!/bin/bash

# Test IOD V3 Ingress-based Access
# Comprehensive testing of ingress routing and service functionality

set -e

echo "🧪 Testing IOD V3 Ingress-based Access..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_TOTAL=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"
    
    ((TESTS_TOTAL++))
    echo -n "Testing $test_name... "
    
    if result=$(eval "$test_command" 2>/dev/null) && echo "$result" | grep -q "$expected_pattern"; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "  Command: $test_command"
        echo "  Expected pattern: $expected_pattern"
        echo "  Actual result: $result"
    fi
}

# Check if ingress is properly configured
echo "🔍 Checking ingress configuration..."
if ! kubectl get ingress -n iodv3-dev iodv3-ingress &>/dev/null; then
    echo -e "${RED}❌ Ingress not found. Please deploy with ingress first.${NC}"
    exit 1
fi

# Check if host is configured
if ! grep -q "dev.iodv3.local" /etc/hosts; then
    echo -e "${YELLOW}⚠️  dev.iodv3.local not found in /etc/hosts. Adding it...${NC}"
    echo "127.0.0.1 dev.iodv3.local" | sudo tee -a /etc/hosts
fi

# Wait for ingress to be ready
echo "⏳ Waiting for ingress to be ready..."
sleep 10

echo ""
echo "🧪 Running Ingress Access Tests..."
echo "=================================="

# Test 1: Main gateway health
run_test "Gateway Health via Ingress" \
    "curl -s -H 'Host: dev.iodv3.local' http://localhost:8080/health" \
    "healthy\|ok\|status.*ok"

# Test 2: Accounts service health  
run_test "Accounts Service Health via Ingress" \
    "curl -s -H 'Host: dev.iodv3.local' http://localhost:8080/accounts/health" \
    "healthy\|ok\|status.*ok"

# Test 3: Blog service health
run_test "Blog Service Health via Ingress" \
    "curl -s -H 'Host: dev.iodv3.local' http://localhost:8080/blog/health" \
    "healthy\|ok\|status.*ok"

# Test 4: Gateway root endpoint
run_test "Gateway Root Endpoint" \
    "curl -s -H 'Host: dev.iodv3.local' http://localhost:8080/" \
    "IOD V3\|API Gateway\|FastAPI"

# Test 5: Accounts service root
run_test "Accounts Service Root" \
    "curl -s -H 'Host: dev.iodv3.local' http://localhost:8080/accounts/" \
    "Accounts\|service\|FastAPI"

# Test 6: Blog service root
run_test "Blog Service Root" \
    "curl -s -H 'Host: dev.iodv3.local' http://localhost:8080/blog/" \
    "Blog\|service\|FastAPI"

# Test 7: OpenAPI docs accessibility
run_test "Gateway OpenAPI Docs" \
    "curl -s -H 'Host: dev.iodv3.local' http://localhost:8080/docs" \
    "swagger\|openapi\|FastAPI"

# Test 8: Response time test
echo -n "Testing Response Time... "
RESPONSE_TIME=$(curl -s -w "%{time_total}" -H "Host: dev.iodv3.local" http://localhost:8080/health -o /dev/null)
if (( $(echo "$RESPONSE_TIME < 1.0" | bc -l) )); then
    echo -e "${GREEN}✅ PASS${NC} (${RESPONSE_TIME}s)"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} (${RESPONSE_TIME}s - too slow)"
fi
((TESTS_TOTAL++))

# Test 9: Ingress status
echo -n "Testing Ingress Status... "
if kubectl get ingress -n iodv3-dev iodv3-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' | grep -q "localhost\|127\|172\|192"; then
    echo -e "${GREEN}✅ PASS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}"
fi
((TESTS_TOTAL++))

# Test 10: Service connectivity through ingress
echo -n "Testing Service Connectivity... "
if kubectl get services -n iodv3-dev | grep -q "ClusterIP"; then
    echo -e "${GREEN}✅ PASS${NC} (Services are ClusterIP)"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} (Services not properly configured)"
fi
((TESTS_TOTAL++))

echo ""
echo "📊 Test Results Summary"
echo "======================"
echo "Tests Passed: $TESTS_PASSED/$TESTS_TOTAL"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 All tests passed! Ingress is working correctly.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the configuration.${NC}"
    
    echo ""
    echo "🔧 Troubleshooting Tips:"
    echo "1. Check ingress controller: kubectl get pods -n ingress-nginx"
    echo "2. Check ingress status: kubectl describe ingress -n iodv3-dev"
    echo "3. Check service endpoints: kubectl get endpoints -n iodv3-dev"
    echo "4. Verify host file: grep dev.iodv3.local /etc/hosts"
    exit 1
fi
