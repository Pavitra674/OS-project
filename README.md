# OS-project: Cloud-Optimized Alpine Linux

A customized Alpine Linux distribution optimized for cloud environments, container orchestration, and infrastructure as code.

## Overview

OS-project provides a lightweight, secure, cloud-optimized operating system based on Alpine Linux. It includes:

- **Container Orchestration**: Docker and Kubernetes (K3s)
- **Infrastructure as Code**: Terraform and Ansible
- **Monitoring & Logging**: Prometheus, Grafana, Loki, and Promtail

## Project Structure

```
OS-project/
├── build-iso.sh              # Basic ISO build script
├── build-final-iso.sh        # Complete ISO build script with customizations
├── Dockerfile                # Docker image for building the ISO
├── scripts/                  # Configuration scripts
│   ├── docker-config.sh      # Docker configuration
│   ├── k8s-config.sh         # Kubernetes configuration
│   ├── terraform-config.sh   # Terraform configuration
│   ├── ansible-config.sh     # Ansible configuration
│   ├── monitoring-config.sh  # Monitoring/logging configuration
│   └── main-script.sh        # Main integration script
├── iso/                      # ISO files (not in repository)
├── build/                    # Build artifacts (not in repository)
├── output/                   # Output ISO location (not in repository)
└── vm/                       # VM disk images for testing (not in repository)
```

## Prerequisites

- Linux environment (can be a VM or WSL on Windows)
- Docker installed and running
- Internet connection to download packages

## Quick Start

1. **Clone this repository**:
   ```bash
   git clone https://github.com/yourusername/OS-project.git
   cd OS-project
   ```

2. **Build the Docker image**:
   ```bash
   docker build -t os-project-builder .
   ```

3. **Build the ISO**:
   ```bash
   docker run -v $(pwd):/os-project os-project-builder ./build-final-iso.sh
   ```

4. **Find your custom ISO**:
   ```
   OS-project/iso/os-project-cloud-alpine-3.18.iso
   ```

## Testing Your ISO

### Using VirtualBox

1. Create a new VM with at least 2GB RAM
2. Select the custom ISO as the boot device
3. Start the VM and follow the installation process

### Using QEMU

```bash
# Create a QCOW2 disk image (10GB)
mkdir -p vm
qemu-img create -f qcow2 vm/alpine-disk.qcow2 10G

# Boot VM from ISO to install to the disk image
qemu-system-x86_64 -m 2048 -boot d -cdrom iso/os-project-cloud-alpine-3.18.iso -hda vm/alpine-disk.qcow2
```

After installation, the VM can be booted from the disk:
```bash
qemu-system-x86_64 -m 2048 -hda vm/alpine-disk.qcow2
```

## Using Your Cloud OS

After installation, the system will automatically configure:

1. **Docker**: Pre-configured with optimized settings
   ```bash
   docker run hello-world
   ```

2. **Kubernetes (K3s)**: Lightweight Kubernetes
   ```bash
   kubectl get nodes
   ```

3. **Terraform**: For infrastructure as code
   ```bash
   # Example configs in /etc/terraform/examples/
   terraform init
   terraform plan
   ```

4. **Ansible**: For configuration management
   ```bash
   # Example playbooks in /etc/ansible/examples/
   ansible-playbook -i inventory.ini playbook.yml
   ```

5. **Monitoring**: Access Prometheus (http://localhost:9090) and Grafana (http://localhost:3000)

## Customization

To customize the OS for your specific needs:

1. Modify the configuration scripts in the `scripts/` directory
2. Update the `build-final-iso.sh` script if needed
3. Rebuild the ISO using the Docker container

## Troubleshooting

### Common Issues

1. **Docker service won't start**
   ```bash
   # Check logs
   dmesg | grep -i docker
   ```

2. **Kubernetes pods stuck in pending**
   ```bash
   # Check node status
   kubectl describe node
   ```

3. **Monitoring services not working**
   ```bash
   # Check service status
   rc-status
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Alpine Linux project for the base distribution
- Docker, Kubernetes, Terraform, Ansible, and other open-source projects included
