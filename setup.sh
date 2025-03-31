#!/bin/bash
# OS-project: Development Environment Setup

# Create project directory
mkdir -p OS-project
cd OS-project

# Create project structure
mkdir -p {iso,packages,scripts,config}

# Install required tools
# This assumes you're on a Debian/Ubuntu-based system
# For other distributions, replace apt with the appropriate package manager
echo "Installing required tools..."
sudo apt update
sudo apt install -y \
  curl \
  wget \
  git \
  build-essential \
  qemu-system-x86 \
  libarchive-tools \
  xorriso \
  squashfs-tools \
  mktorrent

# Clone Alpine Linux aports repository for reference
git clone https://github.com/alpinelinux/aports.git reference/aports

echo "Development environment setup complete!"
echo "Project structure created in $(pwd)/OS-project"
