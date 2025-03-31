#!/bin/bash
# OS-project: Final ISO Build Script

set -e

# Configuration variables
PROJECT_NAME="OS-project"
ALPINE_VERSION="3.18"
ALPINE_MIRROR="http://dl-cdn.alpinelinux.org/alpine"
OUTPUT_DIR="$(pwd)/output"
ISO_DIR="$(pwd)/iso"
BUILD_DIR="$(pwd)/build"
OUTPUT_ISO="${OUTPUT_DIR}/${PROJECT_NAME}-cloud-alpine-${ALPINE_VERSION}.iso"
SCRIPTS_DIR="$(pwd)/scripts"
CONFIG_DIR="$(pwd)/config"

# Banner
echo "========================================"
echo " Building ${PROJECT_NAME} Cloud OS ISO"
echo "========================================"
echo "Alpine Version: ${ALPINE_VERSION}"
echo "Output ISO: ${OUTPUT_ISO}"
echo "========================================"

# Create directories
mkdir -p "${OUTPUT_DIR}" "${ISO_DIR}" "${BUILD_DIR}" "${SCRIPTS_DIR}" "${CONFIG_DIR}"

# Download Alpine Linux ISO if not exists
ALPINE_ISO="alpine-standard-${ALPINE_VERSION}.0-x86_64.iso"
ALPINE_ISO_URL="${ALPINE_MIRROR}/v${ALPINE_VERSION}/releases/x86_64/${ALPINE_ISO}"

if [ ! -f "${ISO_DIR}/${ALPINE_ISO}" ]; then
    echo "Downloading Alpine Linux ISO..."
    wget -P "${ISO_DIR}" "${ALPINE_ISO_URL}"
else
    echo "Using existing Alpine Linux ISO: ${ISO_DIR}/${ALPINE_ISO}"
fi

# Clean build directory
rm -rf "${BUILD_DIR}"/*
mkdir -p "${BUILD_DIR}/iso_extract"

# Extract the ISO
echo "Extracting ISO contents..."
xorriso -osirrox on -indev "${ISO_DIR}/${ALPINE_ISO}" -extract / "${BUILD_DIR}/iso_extract"

# Create scripts directory in the ISO
mkdir -p "${BUILD_DIR}/iso_extract/scripts"

# Copy all configuration scripts to the ISO
echo "Copying configuration scripts to ISO..."
cp "${SCRIPTS_DIR}/docker-config.sh" "${BUILD_DIR}/iso_extract/scripts/"
cp "${SCRIPTS_DIR}/k8s-config.sh" "${BUILD_DIR}/iso_extract/scripts/"
cp "${SCRIPTS_DIR}/terraform-config.sh" "${BUILD_DIR}/iso_extract/scripts/"
cp "${SCRIPTS_DIR}/ansible-config.sh" "${BUILD_DIR}/iso_extract/scripts/"
cp "${SCRIPTS_DIR}/monitoring-config.sh" "${BUILD_DIR}/iso_extract/scripts/"
cp "${SCRIPTS_DIR}/main-script.sh" "${BUILD_DIR}/iso_extract/scripts/"

# Make all scripts executable
chmod +x "${BUILD_DIR}/iso_extract/scripts/"*.sh

# Create a custom init script that will run on boot
cat > "${BUILD_DIR}/iso_extract/etc/local.d/10-os-project-init.start" << EOF
#!/bin/sh
# OS-project initialization script
# This will run on first boot after installation

# Check if the setup has already been completed
if [ ! -f /etc/os-project/setup-completed ]; then
    echo "Starting OS-project cloud optimization setup..."
    
    # Create log directory
    mkdir -p /var/log/os-project
    
    # Run the main integration script
    /scripts/main-script.sh > /var/log/os-project/setup.log 2>&1
    
    # Mark setup as completed
    mkdir -p /etc/os-project
    touch /etc/os-project/setup-completed
    
    echo "OS-project cloud optimization setup completed!"
fi
EOF

chmod +x "${BUILD_DIR}/iso_extract/etc/local.d/10-os-project-init.start"

# Create our custom answer file for automated installation
cat > "${BUILD_DIR}/iso_extract/os-project-answers" << EOF
# OS-project automated installation answer file
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

# Modify isolinux configuration to boot into our installer
sed -i 's/default virt/default os-project/' "${BUILD_DIR}/iso_extract/boot/syslinux/syslinux.cfg"
cat >> "${BUILD_DIR}/iso_extract/boot/syslinux/syslinux.cfg" << EOF

LABEL os-project
MENU LABEL ${PROJECT_NAME} Cloud OS Installer
KERNEL vmlinuz-lts
INITRD initramfs-lts
APPEND modules=loop,squashfs,sd-mod,usb-storage quiet console=tty0 alpine_repo=${ALPINE_MIRROR}/v${ALPINE_VERSION}/main modloop=/boot/modloop-lts setup=os-project-answers
EOF

# Create a custom first boot service file
mkdir -p "${BUILD_DIR}/iso_extract/etc/init.d"
cat > "${BUILD_DIR}/iso_extract/etc/init.d/os-project-setup" << EOF
#!/sbin/openrc-run
# OS-project setup service

description="OS-project Cloud OS Setup Service"
depend() {
    need net
    after networking
}

start() {
    ebegin "Starting OS-project setup"
    if [ ! -f /etc/os-project/setup-completed ]; then
        /scripts/main-script.sh
        touch /etc/os-project/setup-completed
    else
        echo "OS-project setup already completed"
    fi
    eend \$?
}
EOF

chmod +x "${BUILD_DIR}/iso_extract/etc/init.d/os-project-setup"

# Create the new ISO
echo "Creating ${PROJECT_NAME} Cloud OS ISO..."
mkdir -p "${OUTPUT_DIR}"

cd "${BUILD_DIR}/iso_extract"
find . -name .gitignore -delete
find . -type d -exec chmod 755 {} \;

# Create the ISO using xorriso
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
  -volid "${PROJECT_NAME}-CLOUD" \
  .

echo ""
echo "ISO creation completed!"
echo "ISO is located at: ${OUTPUT_ISO}"
echo "ISO size: $(du -h "${OUTPUT_ISO}" | cut -f1)"
echo ""
echo "To use this ISO:"
echo "1. Boot from the ISO"
echo "2. The system will automatically install and configure ${PROJECT_NAME} Cloud OS"
echo "3. After installation, the system will reboot and complete setup automatically"
echo "4. Log in with username 'root' and the password you set during installation"
echo ""
