#!/bin/sh
# OS-project: Terraform Configuration

# Install Terraform
echo "Installing Terraform..."
apk add terraform

# Create example Terraform directory
mkdir -p /etc/terraform/examples

# Create a sample Terraform configuration for AWS
cat > /etc/terraform/examples/aws-example.tf << EOF
# AWS Provider Configuration
provider "aws" {
  region = "us-west-2"
}

# EC2 Instance Resource
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  
  tags = {
    Name = "OS-project-example"
  }
}

# Output the instance ID
output "instance_id" {
  value = aws_instance.example.id
}

# Output the public IP
output "public_ip" {
  value = aws_instance.example.public_ip
}
EOF

# Create a sample Terraform configuration for Azure
cat > /etc/terraform/examples/azure-example.tf << EOF
# Azure Provider Configuration
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "os-project-resources"
  location = "West Europe"
}

# Virtual Network
resource "azurerm_virtual_network" "example" {
  name                = "os-project-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Output the resource group ID
output "resource_group_id" {
  value = azurerm_resource_group.example.id
}
EOF

# Create a sample Terraform configuration for GCP
cat > /etc/terraform/examples/gcp-example.tf << EOF
# GCP Provider Configuration
provider "google" {
  project = "os-project"
  region  = "us-central1"
  zone    = "us-central1-c"
}

# Compute Instance
resource "google_compute_instance" "example" {
  name         = "os-project-example"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
}

# Output the instance ID
output "instance_id" {
  value = google_compute_instance.example.instance_id
}
EOF

echo "Terraform configured successfully with examples for AWS, Azure, and GCP!"
