 ✗ Preparing nodes 📦 📦 📦  
Deleted nodes: ["iodv3-dev-control-plane" "iodv3-dev-worker" "iodv3-dev-worker2"]
ERROR: failed to create cluster: command "docker run --name iodv3-dev-control-plane --hostname iodv3-dev-control-plane --label io.x-k8s.kind.role=control-plane --privileged --security-opt seccomp=unconfined --security-opt apparmor=unconfined --tmpfs /tmp --tmpfs /run --volume /var --volume /lib/modules:/lib/modules:ro -e KIND_EXPERIMENTAL_CONTAINERD_SNAPSHOTTER --detach --tty --label io.x-k8s.kind.cluster=iodv3-dev --net kind --restart=on-failure:1 --init=false --cgroupns=private --publish=0.0.0.0:80:80/TCP --publish=0.0.0.0:443:443/TCP --publish=0.0.0.0:8000:8000/TCP --publish=127.0.0.1:43607:6443/TCP -e KUBECONFIG=/etc/kubernetes/admin.conf kindest/node:v1.27.3@sha256:3966ac761ae0136263ffdb6cfd4db23ef8a83cba8a463690e98317add2c9ba72" failed with error: exit status 125
Command Output: 7763995169df328c64d8f96df704cea6a5ac060f6672e00a553844bddd4934cc
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint iodv3-dev-control-plane (e3726fa3fc6818f48417d292bfb9acd78a84f8c38a1293012df9865bd3d5bf40): failed to bind host port for 0.0.0.0:80:172.19.0.3:80/tcp: address already in use

Run 'docker run --help' for more information
make[1]: *** [Makefile:75: kind-cluster] Error 1
make[1]: Leaving directory '/home/ioduser/iodv3-backend'
make: *** [Makefile:118: kind-deploy] Error 2#!/bin/bash

# Port forwarding script for Kind deployment
echo "Starting port forwarding for IOD V3 services..."

# Function to cleanup on exit
cleanup() {
    echo "Stopping port forwarding..."
    jobs -p | xargs -r kill
    exit 0
}

# Trap interrupt signal
trap cleanup SIGINT SIGTERM

# Check if cluster exists
if ! kubectl cluster-info --context kind-iodv3-dev &> /dev/null; then
    echo "Error: Kind cluster 'iodv3-dev' not found!"
    echo "Run 'make kind-cluster' to create the cluster first."
    exit 1
fi

# Start port forwarding
echo "Starting port forwarding..."
echo "API Gateway: http://localhost:8000"
echo "Accounts Service: http://localhost:8001"  
echo "Blog Service: http://localhost:8002"
echo ""
echo "Press Ctrl+C to stop"

kubectl port-forward -n iodv3-dev service/api-gateway 8000:80 &
kubectl port-forward -n iodv3-dev service/accounts-service 8001:80 &
kubectl port-forward -n iodv3-dev service/blog-service 8002:80 &

# Wait for port forwards to be ready
sleep 2

# Test connectivity
echo ""
echo "Testing connectivity..."
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ API Gateway is accessible"
else
    echo "❌ API Gateway is not accessible"
fi

if curl -s http://localhost:8001/health > /dev/null; then
    echo "✅ Accounts Service is accessible"
else
    echo "❌ Accounts Service is not accessible"
fi

if curl -s http://localhost:8002/health > /dev/null; then
    echo "✅ Blog Service is accessible"
else
    echo "❌ Blog Service is not accessible"
fi

# Wait for user interrupt
wait
