#!/bin/sh
# OS-project: Kubernetes Configuration

# This script configures K3s (a lightweight Kubernetes distribution)
# for our cloud-optimized Alpine Linux

# Install K3s - a lightweight Kubernetes distribution
echo "Installing K3s..."
apk add curl

# Download and install K3s
curl -sfL https://get.k3s.io | sh -

# Enable and start K3s service
rc-update add k3s default
service k3s start || echo "K3s service will be started on next boot"

# Create Kubernetes configuration directory
mkdir -p /etc/kubernetes/manifests

# Create a sample pod configuration
cat > /etc/kubernetes/examples/sample-pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: alpine-sample
  labels:
    app: alpine-sample
spec:
  containers:
  - name: alpine-container
    image: alpine:latest
    command: ["/bin/sh", "-c", "echo Hello from the alpine container! && sleep 3600"]
EOF

echo "Kubernetes (K3s) configured successfully!"
