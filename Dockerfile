FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    qemu-system-x86 \
    libarchive-tools \
    xorriso \
    isolinux \
    squashfs-tools \
    mktorrent \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
WORKDIR /os-project

# Copy the build script
COPY build-iso.sh /os-project/
RUN chmod +x /os-project/build-iso.sh

# Create directories
RUN mkdir -p /os-project/{iso,build,output}

ENTRYPOINT ["/os-project/build-iso.sh"]
