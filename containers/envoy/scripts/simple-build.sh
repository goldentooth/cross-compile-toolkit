#!/bin/bash
# Simple Envoy ARM64 build script for Raspberry Pi

set -euo pipefail

echo "Starting Envoy ARM64 build for Raspberry Pi..."
echo "Version: ${ENVOY_VERSION:-v1.32.0}"
echo "Memory Allocator: ${MEMORY_ALLOCATOR:-disabled}"
echo ""

cd /workspace/envoy

# Create a simple .bazelrc for this build
cat > .bazelrc.local << EOF
# ARM64 cross-compilation
build --platforms=@envoy//bazel:linux_aarch64
build --action_env=CC=aarch64-linux-gnu-gcc
build --action_env=CXX=aarch64-linux-gnu-g++
build --action_env=AR=aarch64-linux-gnu-ar
build --action_env=STRIP=aarch64-linux-gnu-strip

# Disable tcmalloc for Raspberry Pi compatibility
build --define tcmalloc=${MEMORY_ALLOCATOR:-disabled}

# Optimizations
build --copt=-O3
build --copt=-march=armv8-a
build --copt=-mtune=cortex-a72
build --strip=always

# Resource limits
build --local_cpu_resources=${PARALLEL_JOBS:-4}
build --jobs=${PARALLEL_JOBS:-4}

# Verbose output
build --show_timestamps
build --verbose_failures
EOF

echo "Starting build with Bazel..."
echo ""

# Run the build
timeout 7200 bazel build \
    --config=release \
    //source/exe:envoy-static \
    || exit $?

echo ""
echo "Build completed successfully!"

# Copy the binary to artifacts
mkdir -p /artifacts/envoy
cp bazel-bin/source/exe/envoy-static /artifacts/envoy/envoy-${ENVOY_VERSION:-v1.32.0}-arm64
chmod +x /artifacts/envoy/envoy-${ENVOY_VERSION:-v1.32.0}-arm64

# Create build info
cat > /artifacts/envoy/build-info.txt << EOF
Envoy ARM64 Build for Raspberry Pi
==================================
Version: ${ENVOY_VERSION:-v1.32.0}
Date: $(date)
Memory Allocator: ${MEMORY_ALLOCATOR:-disabled}
Architecture: ARM64/AArch64
Target: Raspberry Pi 4B
EOF

echo "Binary saved to: /artifacts/envoy/envoy-${ENVOY_VERSION:-v1.32.0}-arm64"