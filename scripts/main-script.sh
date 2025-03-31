#!/bin/sh
# OS-project: Main Integration Script

# This script integrates all the configuration scripts to set up our cloud-optimized Alpine Linux

# Log file setup
LOG_FILE="/var/log/os-project-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting OS-project cloud optimization setup at $(date)"

# Update package index
echo "Updating package repository..."
apk update

# Install required packages
echo "Installing required packages..."
apk add \
  docker \
  curl \
  wget \
  git \
  vim \
  bash \
  sudo \
  htop \
  iftop \
  jq \
  terraform \
  ansible \
  kubectl \
  prometheus \
  grafana \
  node_exporter \
  loki \
  promtail \
  openssh

# Create necessary directories
mkdir -p /opt/os-project/scripts
mkdir -p /opt/os-project/config
mkdir -p /etc/os-project

# Copy all our configuration scripts to the appropriate locations
cp /scripts/docker-config.sh /opt/os-project/scripts/
cp /scripts/k8s-config.sh /opt/os-project/scripts/
cp /scripts/terraform-config.sh /opt/os-project/scripts/
cp /scripts/ansible-config.sh /opt/os-project/scripts/
cp /scripts/monitoring-config.sh /opt/os-project/scripts/

# Make all scripts executable
chmod +x /opt/os-project/scripts/*.sh

# Run each configuration script
echo "Configuring Docker..."
/opt/os-project/scripts/docker-config.sh

echo "Configuring Kubernetes..."
/opt/os-project/scripts/k8s-config.sh

echo "Configuring Terraform..."
/opt/os-project/scripts/terraform-config.sh

echo "Configuring Ansible..."
/opt/os-project/scripts/ansible-config.sh

echo "Configuring monitoring and logging..."
/opt/os-project/scripts/monitoring-config.sh

# Create a configuration file for the OS
cat > /etc/os-project/config.json << EOF
{
  "name": "OS-project Cloud OS",
  "version": "1.0.0",
  "based_on": "Alpine Linux",
  "components": {
    "container": {
      "docker": true,
      "kubernetes": true
    },
    "deployment": {
      "terraform": true,
      "ansible": true
    },
    "monitoring": {
      "prometheus": true,
      "grafana": true,
      "node_exporter": true
    },
    "logging": {
      "loki": true,
      "promtail": true
    }
  }
}
EOF

# Create a README file with usage instructions
cat > /etc/os-project/README.md << EOF
# OS-project Cloud OS

This is a customized Alpine Linux distribution optimized for cloud environments.

## Included Components

### Container Orchestration
- Docker: Containerization platform
- Kubernetes (K3s): Container orchestration

### Deployment Tools
- Terraform: Infrastructure as Code
- Ansible: Configuration management

### Monitoring and Logging
- Prometheus: Metrics collection and alerting
- Grafana: Metrics visualization
- Node Exporter: System metrics collection
- Loki: Log aggregation
- Promtail: Log collection agent

## Basic Usage

### Docker
- Start Docker: \`service docker start\`
- Run a container: \`docker run hello-world\`

### Kubernetes
- Check K3s status: \`kubectl get nodes\`
- Deploy a pod: \`kubectl apply -f /etc/kubernetes/examples/sample-pod.yaml\`

### Terraform
- Initialize a project: \`cd /path/to/project && terraform init\`
- Plan changes: \`cd /path/to/project && terraform plan\`
- Apply changes: \`cd /path/to/project && terraform apply\`
- Example configs are in: \`/etc/terraform/examples/\`

### Ansible
- Run a playbook: \`ansible-playbook -i /etc/ansible/examples/inventory.ini /etc/ansible/examples/setup-webserver.yml\`
- Check syntax: \`ansible-playbook --syntax-check /etc/ansible/examples/setup-webserver.yml\`

### Monitoring
- Prometheus UI: http://localhost:9090
- Grafana UI: http://localhost:3000 (default login: admin/admin)
- Node Exporter metrics: http://localhost:9100/metrics

### Logging
- Loki API: http://localhost:3100
- View logs in Grafana by adding Loki as a data source

## Configuration Files
- Docker: \`/etc/docker/daemon.json\`
- Kubernetes: \`/etc/kubernetes/\`
- Prometheus: \`/etc/prometheus/prometheus.yml\`
- Grafana: \`/etc/grafana/grafana.ini\`
- Loki: \`/etc/loki/loki-config.yml\`
- Promtail: \`/etc/promtail/promtail-config.yml\`

EOF

# Create a welcome message for login
cat > /etc/motd << EOF
Welcome to OS-project Cloud OS!

This Alpine Linux-based system has been optimized for cloud deployments with:
- Container tools: Docker, Kubernetes (K3s)
- Deployment tools: Terraform, Ansible
- Monitoring tools: Prometheus, Grafana, Node Exporter
- Logging tools: Loki, Promtail

For documentation, see: /etc/os-project/README.md

EOF

# Create a system status script
cat > /usr/local/bin/os-project-status << EOF
#!/bin/sh
# OS-project status script

echo "OS-project Cloud OS Status"
echo "=========================="
echo ""

echo "System Information:"
echo "-------------------"
uname -a
echo ""

echo "Memory Usage:"
echo "-------------"
free -h
echo ""

echo "Disk Usage:"
echo "-----------"
df -h
echo ""

echo "Docker Status:"
echo "--------------"
docker info 2>/dev/null || echo "Docker is not running"
echo ""

echo "Kubernetes Status:"
echo "------------------"
kubectl get nodes 2>/dev/null || echo "Kubernetes is not running"
echo ""

echo "Services Status:"
echo "----------------"
rc-status
echo ""

echo "Monitoring URLs:"
echo "----------------"
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000"
echo "Node Exporter: http://localhost:9100/metrics"
echo ""

echo "Last 5 system log entries:"
echo "--------------------------"
tail -n 5 /var/log/messages
EOF

chmod +x /usr/local/bin/os-project-status

# Create a first-boot script
cat > /etc/local.d/10-first-boot.start << EOF
#!/bin/sh
# OS-project first boot script

# Check if this is the first boot
if [ ! -f /etc/os-project/first-boot-completed ]; then
    echo "Running first boot setup..."
    
    # Enable necessary services
    rc-update add docker default
    rc-update add k3s default
    rc-update add prometheus default
    rc-update add grafana default
    rc-update add node-exporter default
    rc-update add loki default
    rc-update add promtail default
    
    # Start services
    service docker start
    service k3s start
    service prometheus start
    service grafana start
    service node-exporter start
    service loki start
    service promtail start
    
    # Create first boot completed marker
    touch /etc/os-project/first-boot-completed
    
    echo "First boot setup completed!"
fi
EOF

chmod +x /etc/local.d/10-first-boot.start

# Enable local scripts to run at boot
rc-update add local default

echo "OS-project cloud optimization setup completed at $(date)"
echo "Log file is available at: $LOG_FILE"
