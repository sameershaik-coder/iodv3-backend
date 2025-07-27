#!/bin/bash

# IOD V3 Backend - Comprehensive Testing Suite
# Enhanced testing with health checks, API validation, and performance metrics

set -e

# Configuration
CLUSTER_NAME="iodv3-cluster"
NAMESPACE="iodv3-dev"
TIMEOUT=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test execution functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "Testing $test_name... "
    
    if eval "$test_command" &> /dev/null; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo "Testing $test_name..."
    
    if eval "$test_command"; then
        log_success "$test_name - PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "$test_name - FAIL"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Function to check if Kind cluster is running
check_cluster() {
    log_info "Checking Kind cluster status..."
    
    if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        log_error "Kind cluster '${CLUSTER_NAME}' is not running."
        log_info "Run './scripts/deploy-kind-enhanced.sh' first to create the cluster."
        exit 1
    fi
    
    # Check if kubectl context is set correctly
    if ! kubectl config current-context | grep -q "kind-${CLUSTER_NAME}"; then
        log_info "Setting kubectl context to Kind cluster..."
        kubectl config use-context kind-${CLUSTER_NAME}
    fi
    
    log_success "Cluster is running and context is set"
}

# Function to check namespace and pods
check_infrastructure() {
    log_info "Checking infrastructure status..."
    
    # Check if namespace exists
    if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
        log_error "Namespace '${NAMESPACE}' not found. Please run deployment first."
        exit 1
    fi
    
    echo "Pods in ${NAMESPACE} namespace:"
    kubectl get pods -n ${NAMESPACE}
    echo ""
    
    # Check if all pods are running
    local not_running=$(kubectl get pods -n ${NAMESPACE} --no-headers | grep -v Running | grep -v Completed | wc -l)
    if [ "$not_running" -gt 0 ]; then
        log_warning "Some pods are not in Running state"
        kubectl get pods -n ${NAMESPACE} --no-headers | grep -v Running | grep -v Completed
        log_info "Waiting for pods to be ready..."
        sleep 10
    fi
}

# Function to test service connectivity
test_service_connectivity() {
    log_info "Testing service connectivity..."
    
    run_test "Gateway health endpoint" "curl -f http://localhost:30000/health --max-time ${TIMEOUT}"
    run_test "Accounts health endpoint" "curl -f http://localhost:30001/health --max-time ${TIMEOUT}"
    run_test "Blog health endpoint" "curl -f http://localhost:30002/health --max-time ${TIMEOUT}"
}

# Function to test API endpoints
test_api_endpoints() {
    log_info "Testing API endpoints..."
    
    # Test Gateway endpoints
    run_test "Gateway root endpoint" "curl -f http://localhost:30000/ --max-time ${TIMEOUT}"
    run_test "Gateway docs endpoint" "curl -f http://localhost:30000/docs --max-time ${TIMEOUT}"
    
    # Test Accounts endpoints
    run_test "Accounts root endpoint" "curl -f http://localhost:30001/ --max-time ${TIMEOUT}"
    run_test "Accounts docs endpoint" "curl -f http://localhost:30001/docs --max-time ${TIMEOUT}"
    
    # Test Blog endpoints
    run_test "Blog root endpoint" "curl -f http://localhost:30002/ --max-time ${TIMEOUT}"
    run_test "Blog docs endpoint" "curl -f http://localhost:30002/docs --max-time ${TIMEOUT}"
}

# Function to test user registration and authentication
test_authentication() {
    log_info "Testing authentication flow..."
    
    # Test user registration
    local test_user='{
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpassword123"
    }'
    
    echo "Testing user registration..."
    local signup_response=$(curl -s -X POST http://localhost:30000/auth/signup \
        -H "Content-Type: application/json" \
        -d "$test_user" \
        --max-time ${TIMEOUT} || echo "FAILED")
    
    if [[ "$signup_response" == *"FAILED"* ]] || [[ "$signup_response" == *"error"* ]]; then
        log_warning "User registration failed (user might already exist)"
    else
        log_success "User registration successful"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # Test user login
    local login_data='{
        "username": "testuser",
        "password": "testpassword123"
    }'
    
    echo "Testing user login..."
    local login_response=$(curl -s -X POST http://localhost:30000/auth/login \
        -H "Content-Type: application/json" \
        -d "$login_data" \
        --max-time ${TIMEOUT} || echo "FAILED")
    
    if [[ "$login_response" == *"access_token"* ]]; then
        log_success "User login successful"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        
        # Extract token for further tests
        export ACCESS_TOKEN=$(echo "$login_response" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
        log_info "Access token extracted for authenticated requests"
    else
        log_error "User login failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

# Function to test authenticated endpoints
test_authenticated_endpoints() {
    if [ -z "$ACCESS_TOKEN" ]; then
        log_warning "No access token available, skipping authenticated tests"
        return
    fi
    
    log_info "Testing authenticated endpoints..."
    
    # Test get current user
    run_test "Get current user" "curl -f -H \"Authorization: Bearer $ACCESS_TOKEN\" http://localhost:30000/users/me --max-time ${TIMEOUT}"
    
    # Test blog endpoints (admin required)
    log_info "Testing blog endpoints..."
    run_test "Get blogs list" "curl -f -H \"Authorization: Bearer $ACCESS_TOKEN\" http://localhost:30000/blogs/ --max-time ${TIMEOUT}"
}

# Function to test database connectivity
test_database_connectivity() {
    log_info "Testing database connectivity..."
    
    # Test PostgreSQL connectivity
    run_test "PostgreSQL connectivity" "kubectl exec -n ${NAMESPACE} deployment/postgres -- pg_isready -U postgres"
    
    # Test database existence
    run_test "Accounts database exists" "kubectl exec -n ${NAMESPACE} deployment/postgres -- psql -U postgres -lqt | cut -d \| -f 1 | grep -w accounts_db"
    run_test "Blog database exists" "kubectl exec -n ${NAMESPACE} deployment/postgres -- psql -U postgres -lqt | cut -d \| -f 1 | grep -w blog_db"
    
    # Test Redis connectivity
    run_test "Redis connectivity" "kubectl exec -n ${NAMESPACE} deployment/redis -- redis-cli ping"
}

# Function to test performance
test_performance() {
    log_info "Running basic performance tests..."
    
    # Test response time for health endpoints
    echo "Measuring response times:"
    
    local gateway_time=$(curl -o /dev/null -s -w "%{time_total}" http://localhost:30000/health)
    echo "  Gateway health: ${gateway_time}s"
    
    local accounts_time=$(curl -o /dev/null -s -w "%{time_total}" http://localhost:30001/health)
    echo "  Accounts health: ${accounts_time}s"
    
    local blog_time=$(curl -o /dev/null -s -w "%{time_total}" http://localhost:30002/health)
    echo "  Blog health: ${blog_time}s"
    
    # Simple load test (10 requests to gateway)
    log_info "Running simple load test (10 requests)..."
    for i in {1..10}; do
        curl -s http://localhost:30000/health > /dev/null &
    done
    wait
    log_success "Load test completed"
}

# Function to check resource usage
check_resource_usage() {
    log_info "Checking resource usage..."
    
    echo "Pod resource usage:"
    kubectl top pods -n ${NAMESPACE} 2>/dev/null || log_warning "Metrics server not available"
    
    echo ""
    echo "Node resource usage:"
    kubectl top nodes 2>/dev/null || log_warning "Metrics server not available"
}

# Function to show logs
show_logs() {
    log_info "Recent logs from services..."
    
    echo "=== Gateway Logs ==="
    kubectl logs --tail=5 deployment/gateway -n ${NAMESPACE} || log_warning "Gateway logs not available"
    
    echo ""
    echo "=== Accounts Service Logs ==="
    kubectl logs --tail=5 deployment/accounts-service -n ${NAMESPACE} || log_warning "Accounts service logs not available"
    
    echo ""
    echo "=== Blog Service Logs ==="
    kubectl logs --tail=5 deployment/blog-service -n ${NAMESPACE} || log_warning "Blog service logs not available"
}

# Function to show test summary
show_test_summary() {
    echo ""
    echo "🧪 Test Summary:"
    echo "================="
    echo "Total tests: $TESTS_TOTAL"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All tests passed! 🎉"
        echo ""
        echo "🌐 Your IOD V3 Backend is working correctly!"
        echo "  Gateway: http://localhost:30000"
        echo "  Accounts: http://localhost:30001"
        echo "  Blog: http://localhost:30002"
    else
        log_warning "Some tests failed. Check the output above for details."
        echo ""
        echo "🔧 Troubleshooting suggestions:"
        echo "  1. Check pod status: kubectl get pods -n ${NAMESPACE}"
        echo "  2. Check logs: kubectl logs deployment/<service-name> -n ${NAMESPACE}"
        echo "  3. Check services: kubectl get services -n ${NAMESPACE}"
        echo "  4. Restart deployment: kubectl rollout restart deployment/<service-name> -n ${NAMESPACE}"
    fi
}

# Function to run all tests
run_all_tests() {
    log_info "🧪 Starting comprehensive testing of IOD V3 Backend..."
    echo ""
    
    check_cluster
    check_infrastructure
    test_service_connectivity
    test_api_endpoints
    test_database_connectivity
    test_authentication
    test_authenticated_endpoints
    test_performance
    check_resource_usage
    
    show_test_summary
}

# Function to run quick tests only
run_quick_tests() {
    log_info "🧪 Running quick tests..."
    
    check_cluster
    test_service_connectivity
    test_api_endpoints
    
    show_test_summary
}

# Main execution
case "${1:-all}" in
    "all"|"")
        run_all_tests
        ;;
    "quick")
        run_quick_tests
        ;;
    "connectivity")
        check_cluster
        test_service_connectivity
        show_test_summary
        ;;
    "auth")
        check_cluster
        test_authentication
        test_authenticated_endpoints
        show_test_summary
        ;;
    "db")
        check_cluster
        test_database_connectivity
        show_test_summary
        ;;
    "logs")
        check_cluster
        show_logs
        ;;
    "help"|"--help"|"-h")
        echo "Usage: $0 [all|quick|connectivity|auth|db|logs|help]"
        echo "  all          - Run comprehensive test suite (default)"
        echo "  quick        - Run quick connectivity tests only"
        echo "  connectivity - Test service connectivity only"
        echo "  auth         - Test authentication flow only"
        echo "  db           - Test database connectivity only"
        echo "  logs         - Show recent service logs"
        echo "  help         - Show this help message"
        ;;
    *)
        log_error "Invalid command. Use: all, quick, connectivity, auth, db, logs, or help"
        exit 1
        ;;
esac
