#!/bin/bash
# OS-project: Alpine Linux Build Configuration

set -e

# Configuration variables
ALPINE_VERSION="3.18"
ALPINE_MIRROR="http://dl-cdn.alpinelinux.org/alpine"
BUILD_DIR="$(pwd)/build"
ISO_DIR="$(pwd)/iso"
OUTPUT_ISO="${ISO_DIR}/os-project-cloud-alpine-${ALPINE_VERSION}.iso"

# Create build directories
mkdir -p "${BUILD_DIR}"
mkdir -p "${ISO_DIR}"

# Download Alpine Linux ISO
ALPINE_ISO="alpine-standard-${ALPINE_VERSION}.0-x86_64.iso"
ALPINE_ISO_URL="${ALPINE_MIRROR}/v${ALPINE_VERSION}/releases/x86_64/${ALPINE_ISO}"

if [ ! -f "${ISO_DIR}/${ALPINE_ISO}" ]; then
    echo "Downloading Alpine Linux ISO..."
    wget -P "${ISO_DIR}" "${ALPINE_ISO_URL}"
fi

# Extract the ISO contents
echo "Extracting ISO contents..."
mkdir -p "${BUILD_DIR}/iso_extract"
xorriso -osirrox on -indev "${ISO_DIR}/${ALPINE_ISO}" -extract / "${BUILD_DIR}/iso_extract"

# Create our custom answer file for automated installation
cat > "${BUILD_DIR}/iso_extract/custom_answers" << EOF
# Alpine Linux installation answer file
KEYMAPOPTS="us us"
HOSTNAMEOPTS="-n os-project-cloud"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
DNSOPTS="-d local -n 8.8.8.8 8.8.4.4"
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="-1"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
DISKOPTS="-m sys /dev/sda"
EOF

# Create custom APK repository configuration
mkdir -p "${BUILD_DIR}/iso_extract/etc/apk"
cat > "${BUILD_DIR}/iso_extract/etc/apk/repositories" << EOF
${ALPINE_MIRROR}/v${ALPINE_VERSION}/main
${ALPINE_MIRROR}/v${ALPINE_VERSION}/community
${ALPINE_MIRROR}/edge/testing
EOF

# Create custom installation script
cat > "${BUILD_DIR}/iso_extract/custom_install.sh" << EOF
#!/bin/sh
# OS-project: Custom installation script

# Setup Alpine with our answer file
setup-alpine -f /custom_answers

# Post-installation configuration will be executed on first boot
EOF

chmod +x "${BUILD_DIR}/iso_extract/custom_install.sh"

# Create a post-installation script to be executed on first boot
mkdir -p "${BUILD_DIR}/iso_extract/etc/local.d"
cat > "${BUILD_DIR}/iso_extract/etc/local.d/99-post-install.start" << EOF
#!/bin/sh
# OS-project: Post-installation configuration

# Enable community repository if not already enabled
sed -i -e '/community/ s/^#//' /etc/apk/repositories

# Update package index
apk update

# Install Docker
echo "Installing Docker..."
apk add docker
rc-update add docker default
service docker start

# Install Kubernetes tools
echo "Installing Kubernetes tools..."
apk add kubectl

# Install Terraform
echo "Installing Terraform..."
apk add terraform

# Install Ansible
echo "Installing Ansible..."
apk add ansible

# Install monitoring and logging tools
echo "Installing monitoring and logging tools..."
apk add prometheus node_exporter grafana loki promtail

# Basic system utilities
apk add curl wget git vim

# Cleanup
rm /etc/local.d/99-post-install.start

echo "Post-installation setup complete!"
EOF

chmod +x "${BUILD_DIR}/iso_extract/etc/local.d/99-post-install.start"

# Modify isolinux configuration to boot into our installer
sed -i 's/default virt/default custom/' "${BUILD_DIR}/iso_extract/boot/syslinux/syslinux.cfg"
cat >> "${BUILD_DIR}/iso_extract/boot/syslinux/syslinux.cfg" << EOF

LABEL custom
MENU LABEL OS-project Cloud Alpine Installer
KERNEL vmlinuz-lts
INITRD initramfs-lts
APPEND modules=loop,squashfs,sd-mod,usb-storage quiet console=tty0 alpine_repo=${ALPINE_MIRROR}/v${ALPINE_VERSION}/main modloop=/boot/modloop-lts
EOF

# Create the new ISO
echo "Creating new ISO..."
cd "${BUILD_DIR}/iso_extract"
find . -name .gitignore -delete
find . -type d -exec chmod 755 {} \;

xorriso -as mkisofs \
  -o "${OUTPUT_ISO}" \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -c boot/syslinux/boot.cat \
  -b boot/syslinux/isolinux.bin \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -eltorito-alt-boot \
  -e boot/grub/efi.img \
  -no-emul-boot \
  -isohybrid-gpt-basdat \
  -volid "OS-PROJECT-CLOUD" \
  .

echo "Custom ISO created: ${OUTPUT_ISO}"
