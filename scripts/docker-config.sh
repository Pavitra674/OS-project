#!/bin/sh
# OS-project: Docker Configuration

# This script configures Docker with optimized settings for cloud environments

# Create Docker daemon configuration directory
mkdir -p /etc/docker

# Create optimized daemon.json configuration
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "metrics-addr": "0.0.0.0:9323",
  "experimental": true,
  "live-restore": true,
  "default-address-pools": [
    {
      "base": "172.17.0.0/16",
      "size": 24
    }
  ]
}
EOF

# Set up Docker to start at boot
rc-update add docker default

# Start Docker service
service docker start || echo "Docker service will be started on next boot"

echo "Docker configured successfully!"
