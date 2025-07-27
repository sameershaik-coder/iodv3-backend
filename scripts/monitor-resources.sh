#!/bin/bash

# IOD V3 Backend - Advanced Resource Monitoring Script
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

echo -e "${BLUE}${INFO}🔍 Starting Advanced Resource Monitoring for IOD V3...${NC}"
echo ""

# Check if kubectl is available and cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}${ERROR} Kubernetes cluster is not accessible${NC}"
    exit 1
fi

NAMESPACE="iodv3-dev"

echo -e "${BLUE}${INFO}Checking namespace and resources...${NC}"
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo -e "${RED}${ERROR} Namespace $NAMESPACE not found${NC}"
    exit 1
fi

echo -e "${GREEN}${SUCCESS} Namespace $NAMESPACE found${NC}"
echo ""

# 1. Pod Resource Usage
echo -e "${BLUE}${INFO}📊 Pod Resource Usage:${NC}"
echo "========================================"

# Check if metrics server is available
if kubectl top nodes &> /dev/null; then
    echo -e "${GREEN}${SUCCESS} Metrics server available${NC}"
    echo ""
    echo "Node resource usage:"
    kubectl top nodes
    echo ""
    echo "Pod resource usage in $NAMESPACE:"
    kubectl top pods -n $NAMESPACE
else
    echo -e "${YELLOW}${WARNING} Metrics server not available (expected in Kind)${NC}"
    echo "Using resource requests/limits instead..."
    
    # Show resource requests and limits
    echo ""
    echo "Resource specifications for pods:"
    kubectl get pods -n $NAMESPACE -o custom-columns="NAME:.metadata.name,CPU_REQ:.spec.containers[*].resources.requests.cpu,CPU_LIM:.spec.containers[*].resources.limits.cpu,MEM_REQ:.spec.containers[*].resources.requests.memory,MEM_LIM:.spec.containers[*].resources.limits.memory" 2>/dev/null || echo "Resource information not available"
fi

echo ""

# 2. Pod Health Status
echo -e "${BLUE}${INFO}🏥 Pod Health Status:${NC}"
echo "========================================"

PODS=$(kubectl get pods -n $NAMESPACE --no-headers -o custom-columns=":metadata.name")

for POD in $PODS; do
    echo -e "${BLUE}${INFO}Checking $POD...${NC}"
    
    # Get pod status
    STATUS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.phase}')
    READY=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
    RESTARTS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].restartCount}')
    
    if [ "$STATUS" = "Running" ] && [ "$READY" = "True" ]; then
        echo -e "  ${GREEN}${SUCCESS} $POD: Running and Ready (Restarts: $RESTARTS)${NC}"
    else
        echo -e "  ${YELLOW}${WARNING} $POD: Status=$STATUS, Ready=$READY, Restarts=$RESTARTS${NC}"
    fi
    
    # Check liveness and readiness probes
    LIVENESS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.containers[0].livenessProbe}' 2>/dev/null)
    READINESS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.containers[0].readinessProbe}' 2>/dev/null)
    
    if [ -n "$LIVENESS" ]; then
        echo -e "  ${GREEN}${SUCCESS} Liveness probe configured${NC}"
    else
        echo -e "  ${YELLOW}${WARNING} No liveness probe configured${NC}"
    fi
    
    if [ -n "$READINESS" ]; then
        echo -e "  ${GREEN}${SUCCESS} Readiness probe configured${NC}"
    else
        echo -e "  ${YELLOW}${WARNING} No readiness probe configured${NC}"
    fi
    
    echo ""
done

# 3. Service Health Checks
echo -e "${BLUE}${INFO}🌐 Service Health Checks:${NC}"
echo "========================================"

# List of services to check
SERVICES=("api-gateway:30000" "accounts-service:30001" "blog-service:30002")

for SERVICE_PORT in "${SERVICES[@]}"; do
    SERVICE_NAME=$(echo $SERVICE_PORT | cut -d':' -f1)
    PORT=$(echo $SERVICE_PORT | cut -d':' -f2)
    
    echo -e "${BLUE}${INFO}Testing $SERVICE_NAME on port $PORT...${NC}"
    
    # Test health endpoint
    if curl -s --max-time 5 "http://localhost:$PORT/health" > /dev/null; then
        RESPONSE=$(curl -s --max-time 5 "http://localhost:$PORT/health")
        echo -e "  ${GREEN}${SUCCESS} Health endpoint responding: $RESPONSE${NC}"
    else
        echo -e "  ${RED}${ERROR} Health endpoint not responding${NC}"
    fi
done

echo ""

# 4. Resource Utilization Analysis
echo -e "${BLUE}${INFO}📈 Resource Utilization Analysis:${NC}"
echo "========================================"

# Count pods per node
echo "Pod distribution across nodes:"
kubectl get pods -n $NAMESPACE -o wide --no-headers | awk '{print $7}' | sort | uniq -c

echo ""

# Check resource quotas if any
echo "Resource quotas in namespace $NAMESPACE:"
QUOTAS=$(kubectl get resourcequota -n $NAMESPACE --no-headers 2>/dev/null | wc -l)
if [ $QUOTAS -gt 0 ]; then
    kubectl get resourcequota -n $NAMESPACE
else
    echo -e "${YELLOW}${WARNING} No resource quotas configured${NC}"
fi

echo ""

# 5. Storage Analysis
echo -e "${BLUE}${INFO}💾 Storage Analysis:${NC}"
echo "========================================"

echo "Persistent Volume Claims:"
kubectl get pvc -n $NAMESPACE

echo ""
echo "Persistent Volumes:"
kubectl get pv | grep -E "(iodv3|postgres|redis)" || echo "No matching PVs found"

echo ""

# 6. Network Connectivity Test
echo -e "${BLUE}${INFO}🔗 Network Connectivity Tests:${NC}"
echo "========================================"

# Test internal service connectivity
echo "Testing internal service connectivity..."

# Get a running pod to use for testing
TEST_POD=$(kubectl get pods -n $NAMESPACE -l app=api-gateway --no-headers -o custom-columns=":metadata.name" | head -1)

if [ -n "$TEST_POD" ]; then
    echo -e "${BLUE}${INFO}Using pod $TEST_POD for connectivity tests...${NC}"
    
    # Test connectivity to other services
    INTERNAL_SERVICES=("accounts-service:8001" "blog-service:8002" "postgres-service:5432" "redis-service:6379")
    
    for SERVICE_PORT in "${INTERNAL_SERVICES[@]}"; do
        SERVICE_NAME=$(echo $SERVICE_PORT | cut -d':' -f1)
        PORT=$(echo $SERVICE_PORT | cut -d':' -f2)
        
        echo -e "${BLUE}${INFO}Testing connectivity to $SERVICE_NAME:$PORT...${NC}"
        
        if kubectl exec -n $NAMESPACE $TEST_POD -- timeout 5 nc -z $SERVICE_NAME $PORT 2>/dev/null; then
            echo -e "  ${GREEN}${SUCCESS} Connection to $SERVICE_NAME:$PORT successful${NC}"
        else
            echo -e "  ${YELLOW}${WARNING} Connection to $SERVICE_NAME:$PORT failed or timeout${NC}"
        fi
    done
else
    echo -e "${YELLOW}${WARNING} No API Gateway pod found for connectivity testing${NC}"
fi

echo ""

# 7. Performance Metrics
echo -e "${BLUE}${INFO}⚡ Performance Metrics:${NC}"
echo "========================================"

echo "Response time tests:"
for SERVICE_PORT in "${SERVICES[@]}"; do
    SERVICE_NAME=$(echo $SERVICE_PORT | cut -d':' -f1)
    PORT=$(echo $SERVICE_PORT | cut -d':' -f2)
    
    echo -e "${BLUE}${INFO}Measuring response time for $SERVICE_NAME...${NC}"
    
    RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /dev/null --max-time 5 "http://localhost:$PORT/health" 2>/dev/null || echo "timeout")
    
    if [ "$RESPONSE_TIME" != "timeout" ]; then
        echo -e "  ${GREEN}${SUCCESS} $SERVICE_NAME response time: ${RESPONSE_TIME}s${NC}"
    else
        echo -e "  ${RED}${ERROR} $SERVICE_NAME: Request timeout or failed${NC}"
    fi
done

echo ""

# 8. Summary Report
echo -e "${BLUE}${INFO}📋 Summary Report:${NC}"
echo "========================================"

TOTAL_PODS=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)
RUNNING_PODS=$(kubectl get pods -n $NAMESPACE --no-headers | grep "Running" | wc -l)
READY_PODS=$(kubectl get pods -n $NAMESPACE --no-headers | awk '{print $2}' | grep -E "^[0-9]+/\1$" | wc -l)

echo "Pod Status Summary:"
echo "  Total pods: $TOTAL_PODS"
echo "  Running pods: $RUNNING_PODS"
echo "  Ready pods: $READY_PODS"

if [ $RUNNING_PODS -eq $TOTAL_PODS ] && [ $READY_PODS -eq $TOTAL_PODS ]; then
    echo -e "${GREEN}${SUCCESS} All pods are running and ready${NC}"
else
    echo -e "${YELLOW}${WARNING} Some pods may have issues${NC}"
fi

echo ""
echo "Service Status Summary:"
HEALTHY_SERVICES=0
for SERVICE_PORT in "${SERVICES[@]}"; do
    PORT=$(echo $SERVICE_PORT | cut -d':' -f2)
    if curl -s --max-time 5 "http://localhost:$PORT/health" > /dev/null; then
        ((HEALTHY_SERVICES++))
    fi
done

echo "  Healthy services: $HEALTHY_SERVICES/${#SERVICES[@]}"

if [ $HEALTHY_SERVICES -eq ${#SERVICES[@]} ]; then
    echo -e "${GREEN}${SUCCESS} All services are healthy${NC}"
else
    echo -e "${YELLOW}${WARNING} Some services may have issues${NC}"
fi

echo ""

# 9. Recommendations
echo -e "${BLUE}${INFO}💡 Recommendations:${NC}"
echo "========================================"

if [ $HEALTHY_SERVICES -eq ${#SERVICES[@]} ] && [ $RUNNING_PODS -eq $TOTAL_PODS ]; then
    echo -e "${GREEN}${SUCCESS} System is running optimally${NC}"
    echo "Consider:"
    echo "  • Monitor resource usage over time"
    echo "  • Set up automated monitoring"
    echo "  • Consider implementing metrics collection"
else
    echo -e "${YELLOW}${WARNING} System has some issues${NC}"
    echo "Recommended actions:"
    echo "  • Check pod logs: kubectl logs <pod-name> -n $NAMESPACE"
    echo "  • Restart failed services: kubectl rollout restart deployment/<service> -n $NAMESPACE"
    echo "  • Check resource constraints"
fi

echo ""
echo -e "${GREEN}${SUCCESS} Advanced monitoring complete!${NC}"

# Optional: Generate timestamp report
echo ""
echo "Report generated at: $(date)"
echo "Kubernetes cluster: $(kubectl config current-context)"
echo "Namespace: $NAMESPACE"
