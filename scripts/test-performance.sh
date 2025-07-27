#!/bin/bash

# IOD V3 Backend - Advanced Performance Testing Script
# Phase 3: Advanced Features

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Emoji for better UX
INFO="ℹ️ "
SUCCESS="✅"
WARNING="⚠️ "
ERROR="❌"

echo -e "${BLUE}${INFO}🚀 Starting Advanced Performance Testing for IOD V3...${NC}"
echo ""

# Configuration
NAMESPACE="iodv3-dev"
BASE_URL="http://localhost"
SERVICES=("30000:api-gateway" "30001:accounts-service" "30002:blog-service")
CONCURRENT_REQUESTS=10
TOTAL_REQUESTS=100

# Check prerequisites
echo -e "${BLUE}${INFO}Checking prerequisites...${NC}"

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo -e "${RED}${ERROR} curl is required but not installed${NC}"
    exit 1
fi

# Check if ab (Apache Bench) is available for load testing
if command -v ab &> /dev/null; then
    AB_AVAILABLE=true
    echo -e "${GREEN}${SUCCESS} Apache Bench (ab) available for load testing${NC}"
else
    AB_AVAILABLE=false
    echo -e "${YELLOW}${WARNING} Apache Bench (ab) not available, using basic curl testing${NC}"
fi

# Check if jq is available for JSON parsing
if command -v jq &> /dev/null; then
    JQ_AVAILABLE=true
    echo -e "${GREEN}${SUCCESS} jq available for JSON parsing${NC}"
else
    JQ_AVAILABLE=false
    echo -e "${YELLOW}${WARNING} jq not available, using basic JSON parsing${NC}"
fi

echo ""

# 1. Basic Health Check Performance
echo -e "${BLUE}${INFO}🏥 Basic Health Check Performance:${NC}"
echo "========================================"

for SERVICE_INFO in "${SERVICES[@]}"; do
    PORT=$(echo $SERVICE_INFO | cut -d':' -f1)
    SERVICE_NAME=$(echo $SERVICE_INFO | cut -d':' -f2)
    
    echo -e "${BLUE}${INFO}Testing $SERVICE_NAME health endpoint...${NC}"
    
    # Measure response time
    RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /tmp/health_response.json --max-time 10 "$BASE_URL:$PORT/health" 2>/dev/null || echo "timeout")
    
    if [ "$RESPONSE_TIME" != "timeout" ]; then
        echo -e "  ${GREEN}${SUCCESS} Response time: ${RESPONSE_TIME}s${NC}"
        
        # Check response content
        if [ -f /tmp/health_response.json ]; then
            if $JQ_AVAILABLE; then
                STATUS=$(jq -r '.status // "unknown"' /tmp/health_response.json 2>/dev/null || echo "unknown")
                echo -e "  ${GREEN}${SUCCESS} Health status: $STATUS${NC}"
            else
                echo -e "  ${GREEN}${SUCCESS} Response received (JSON parsing not available)${NC}"
            fi
        fi
    else
        echo -e "  ${RED}${ERROR} Health check timeout or failed${NC}"
    fi
    
    # Cleanup
    rm -f /tmp/health_response.json
    echo ""
done

# 2. Load Testing
echo -e "${BLUE}${INFO}⚡ Load Testing:${NC}"
echo "========================================"

for SERVICE_INFO in "${SERVICES[@]}"; do
    PORT=$(echo $SERVICE_INFO | cut -d':' -f1)
    SERVICE_NAME=$(echo $SERVICE_INFO | cut -d':' -f2)
    URL="$BASE_URL:$PORT/health"
    
    echo -e "${BLUE}${INFO}Load testing $SERVICE_NAME...${NC}"
    echo "  URL: $URL"
    echo "  Concurrent requests: $CONCURRENT_REQUESTS"
    echo "  Total requests: $TOTAL_REQUESTS"
    
    if $AB_AVAILABLE; then
        echo -e "${BLUE}${INFO}Running Apache Bench test...${NC}"
        
        # Run ab test and capture output
        AB_OUTPUT=$(ab -n $TOTAL_REQUESTS -c $CONCURRENT_REQUESTS -q "$URL" 2>/dev/null | grep -E "(Requests per second|Time per request|Transfer rate|Failed requests)" || echo "ab test failed")
        
        if [ "$AB_OUTPUT" != "ab test failed" ]; then
            echo -e "${GREEN}${SUCCESS} Apache Bench results:${NC}"
            echo "$AB_OUTPUT" | while read line; do
                echo "    $line"
            done
        else
            echo -e "${RED}${ERROR} Apache Bench test failed${NC}"
        fi
    else
        echo -e "${BLUE}${INFO}Running basic curl load test...${NC}"
        
        # Basic curl-based load test
        TOTAL_TIME=0
        SUCCESSFUL_REQUESTS=0
        FAILED_REQUESTS=0
        
        echo -e "  ${BLUE}${INFO}Sending $TOTAL_REQUESTS requests...${NC}"
        
        for i in $(seq 1 $TOTAL_REQUESTS); do
            START_TIME=$(date +%s.%N)
            
            if curl -s --max-time 5 "$URL" > /dev/null 2>&1; then
                END_TIME=$(date +%s.%N)
                REQUEST_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0")
                TOTAL_TIME=$(echo "$TOTAL_TIME + $REQUEST_TIME" | bc -l 2>/dev/null || echo "$TOTAL_TIME")
                ((SUCCESSFUL_REQUESTS++))
            else
                ((FAILED_REQUESTS++))
            fi
            
            # Show progress every 20 requests
            if [ $((i % 20)) -eq 0 ]; then
                echo -n "."
            fi
        done
        
        echo ""
        
        # Calculate and display results
        if command -v bc &> /dev/null && [ $SUCCESSFUL_REQUESTS -gt 0 ]; then
            AVG_TIME=$(echo "scale=4; $TOTAL_TIME / $SUCCESSFUL_REQUESTS" | bc)
            REQUESTS_PER_SEC=$(echo "scale=2; $SUCCESSFUL_REQUESTS / $TOTAL_TIME" | bc)
            echo -e "  ${GREEN}${SUCCESS} Basic load test results:${NC}"
            echo "    Successful requests: $SUCCESSFUL_REQUESTS"
            echo "    Failed requests: $FAILED_REQUESTS"
            echo "    Average response time: ${AVG_TIME}s"
            echo "    Requests per second: $REQUESTS_PER_SEC"
        else
            echo -e "  ${GREEN}${SUCCESS} Basic load test completed:${NC}"
            echo "    Successful requests: $SUCCESSFUL_REQUESTS"
            echo "    Failed requests: $FAILED_REQUESTS"
        fi
    fi
    
    echo ""
done

# 3. API Endpoint Performance Testing
echo -e "${BLUE}${INFO}🔗 API Endpoint Performance Testing:${NC}"
echo "========================================"

# Test various API endpoints
API_ENDPOINTS=(
    "30000:/:Gateway root"
    "30000:/docs:Gateway docs"
    "30001:/:Accounts root"
    "30001:/docs:Accounts docs"
    "30002:/:Blog root"
    "30002:/docs:Blog docs"
)

for ENDPOINT_INFO in "${API_ENDPOINTS[@]}"; do
    PORT=$(echo $ENDPOINT_INFO | cut -d':' -f1)
    ENDPOINT=$(echo $ENDPOINT_INFO | cut -d':' -f2)
    DESCRIPTION=$(echo $ENDPOINT_INFO | cut -d':' -f3)
    URL="$BASE_URL:$PORT$ENDPOINT"
    
    echo -e "${BLUE}${INFO}Testing $DESCRIPTION ($URL)...${NC}"
    
    # Test response time and status
    HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/endpoint_response.html --max-time 10 "$URL" 2>/dev/null || echo "000")
    RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /dev/null --max-time 10 "$URL" 2>/dev/null || echo "timeout")
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "  ${GREEN}${SUCCESS} HTTP 200 OK - Response time: ${RESPONSE_TIME}s${NC}"
        
        # Check response size
        if [ -f /tmp/endpoint_response.html ]; then
            SIZE=$(wc -c < /tmp/endpoint_response.html)
            echo -e "  ${GREEN}${SUCCESS} Response size: $SIZE bytes${NC}"
        fi
    elif [ "$HTTP_CODE" = "000" ]; then
        echo -e "  ${RED}${ERROR} Connection failed${NC}"
    else
        echo -e "  ${YELLOW}${WARNING} HTTP $HTTP_CODE - Response time: ${RESPONSE_TIME}s${NC}"
    fi
    
    # Cleanup
    rm -f /tmp/endpoint_response.html
    echo ""
done

# 4. Database Performance Testing
echo -e "${BLUE}${INFO}🗄️  Database Performance Testing:${NC}"
echo "========================================"

# Test database connectivity through services
echo -e "${BLUE}${INFO}Testing database connectivity through services...${NC}"

# Get a running pod for database testing
TEST_POD=$(kubectl get pods -n $NAMESPACE -l app=api-gateway --no-headers -o custom-columns=":metadata.name" | head -1)

if [ -n "$TEST_POD" ]; then
    echo -e "${BLUE}${INFO}Using pod $TEST_POD for database tests...${NC}"
    
    # Test PostgreSQL connectivity
    echo -e "${BLUE}${INFO}Testing PostgreSQL connectivity...${NC}"
    if kubectl exec -n $NAMESPACE $TEST_POD -- timeout 5 nc -z postgres-service 5432 2>/dev/null; then
        echo -e "  ${GREEN}${SUCCESS} PostgreSQL connection successful${NC}"
        
        # Test PostgreSQL response time
        START_TIME=$(date +%s.%N)
        kubectl exec -n $NAMESPACE $TEST_POD -- timeout 10 sh -c 'echo "SELECT 1;" | nc postgres-service 5432' &>/dev/null || true
        END_TIME=$(date +%s.%N)
        
        if command -v bc &> /dev/null; then
            DB_RESPONSE_TIME=$(echo "$END_TIME - $START_TIME" | bc -l)
            echo -e "  ${GREEN}${SUCCESS} Database response time: ${DB_RESPONSE_TIME}s${NC}"
        fi
    else
        echo -e "  ${RED}${ERROR} PostgreSQL connection failed${NC}"
    fi
    
    # Test Redis connectivity
    echo -e "${BLUE}${INFO}Testing Redis connectivity...${NC}"
    if kubectl exec -n $NAMESPACE $TEST_POD -- timeout 5 nc -z redis-service 6379 2>/dev/null; then
        echo -e "  ${GREEN}${SUCCESS} Redis connection successful${NC}"
        
        # Test Redis response time
        START_TIME=$(date +%s.%N)
        kubectl exec -n $NAMESPACE $TEST_POD -- timeout 10 sh -c 'echo "PING" | nc redis-service 6379' &>/dev/null || true
        END_TIME=$(date +%s.%N)
        
        if command -v bc &> /dev/null; then
            REDIS_RESPONSE_TIME=$(echo "$END_TIME - $START_TIME" | bc -l)
            echo -e "  ${GREEN}${SUCCESS} Redis response time: ${REDIS_RESPONSE_TIME}s${NC}"
        fi
    else
        echo -e "  ${RED}${ERROR} Redis connection failed${NC}"
    fi
else
    echo -e "${YELLOW}${WARNING} No test pod available for database testing${NC}"
fi

echo ""

# 5. Resource Usage During Load
echo -e "${BLUE}${INFO}📊 Resource Usage During Load:${NC}"
echo "========================================"

echo -e "${BLUE}${INFO}Monitoring resource usage during performance test...${NC}"

# Check current pod resource usage if metrics available
if kubectl top pods -n $NAMESPACE &> /dev/null; then
    echo "Current resource usage:"
    kubectl top pods -n $NAMESPACE
else
    echo -e "${YELLOW}${WARNING} Metrics server not available for resource monitoring${NC}"
fi

# Check pod status during load
echo ""
echo "Pod status during testing:"
kubectl get pods -n $NAMESPACE -o wide

echo ""

# 6. Network Latency Testing
echo -e "${BLUE}${INFO}🌐 Network Latency Testing:${NC}"
echo "========================================"

for SERVICE_INFO in "${SERVICES[@]}"; do
    PORT=$(echo $SERVICE_INFO | cut -d':' -f1)
    SERVICE_NAME=$(echo $SERVICE_INFO | cut -d':' -f2)
    
    echo -e "${BLUE}${INFO}Testing network latency to $SERVICE_NAME...${NC}"
    
    # Multiple ping-like tests to get average latency
    TOTAL_LATENCY=0
    SUCCESSFUL_TESTS=0
    
    for i in {1..5}; do
        LATENCY=$(curl -s -w "%{time_connect}" -o /dev/null --max-time 5 "$BASE_URL:$PORT/health" 2>/dev/null || echo "timeout")
        
        if [ "$LATENCY" != "timeout" ]; then
            if command -v bc &> /dev/null; then
                TOTAL_LATENCY=$(echo "$TOTAL_LATENCY + $LATENCY" | bc -l)
            fi
            ((SUCCESSFUL_TESTS++))
        fi
    done
    
    if [ $SUCCESSFUL_TESTS -gt 0 ] && command -v bc &> /dev/null; then
        AVG_LATENCY=$(echo "scale=4; $TOTAL_LATENCY / $SUCCESSFUL_TESTS" | bc)
        echo -e "  ${GREEN}${SUCCESS} Average connection latency: ${AVG_LATENCY}s (from $SUCCESSFUL_TESTS tests)${NC}"
    else
        echo -e "  ${YELLOW}${WARNING} Latency testing failed or incomplete${NC}"
    fi
    
    echo ""
done

# 7. Performance Summary
echo -e "${BLUE}${INFO}📋 Performance Summary:${NC}"
echo "========================================"

echo "Performance test completed for IOD V3 Backend"
echo "Test configuration:"
echo "  • Concurrent requests: $CONCURRENT_REQUESTS"
echo "  • Total requests per service: $TOTAL_REQUESTS"
echo "  • Services tested: ${#SERVICES[@]}"
echo "  • API endpoints tested: ${#API_ENDPOINTS[@]}"

echo ""
echo "Recommendations:"
echo "  • Monitor performance trends over time"
echo "  • Consider implementing performance alerting"
echo "  • Optimize slow endpoints if identified"
echo "  • Scale resources based on load requirements"

echo ""
echo -e "${GREEN}${SUCCESS} Advanced performance testing complete!${NC}"

# Generate timestamp report
echo ""
echo "Performance test completed at: $(date)"
echo "Kubernetes cluster: $(kubectl config current-context)"
echo "Namespace: $NAMESPACE"

# Cleanup temporary files
rm -f /tmp/health_response.json /tmp/endpoint_response.html
