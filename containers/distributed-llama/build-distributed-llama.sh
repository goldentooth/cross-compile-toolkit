#!/bin/bash
set -euo pipefail

# Build script for distributed-llama ARM64 cross-compilation
# This script runs inside the container to build distributed-llama

echo "🚀 Starting distributed-llama ARM64 cross-compilation build"

# Configuration from environment
DISTRIBUTED_LLAMA_VERSION="${DISTRIBUTED_LLAMA_VERSION:-main}"
TARGET_ARCH="${TARGET_ARCH:-aarch64-linux-gnu}"
BUILD_CONFIG="${BUILD_CONFIG:-release}"
PARALLEL_JOBS="${PARALLEL_JOBS:-4}"

echo "📝 Build Configuration:"
echo "  Version: ${DISTRIBUTED_LLAMA_VERSION}"
echo "  Target: ${TARGET_ARCH}"
echo "  Config: ${BUILD_CONFIG}"
echo "  Jobs: ${PARALLEL_JOBS}"

# Navigate to workspace
cd /workspace

# Clone or update distributed-llama repository
if [ -d "distributed-llama" ]; then
    echo "📦 Updating existing distributed-llama repository"
    cd distributed-llama
    git fetch origin
    git checkout "${DISTRIBUTED_LLAMA_VERSION}"
    git pull origin "${DISTRIBUTED_LLAMA_VERSION}"
else
    echo "📦 Cloning distributed-llama repository"
    git clone --branch "${DISTRIBUTED_LLAMA_VERSION}" \
        https://github.com/b4rtaz/distributed-llama.git \
        distributed-llama
    cd distributed-llama
fi

# Set up cross-compilation environment
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export AR=aarch64-linux-gnu-ar
export STRIP=aarch64-linux-gnu-strip

# ARM64 optimizations for Raspberry Pi 4
export CFLAGS="-march=armv8-a -mtune=cortex-a72 -O3"
export CXXFLAGS="-march=armv8-a -mtune=cortex-a72 -O3"

# Clean any previous builds
echo "🧹 Cleaning previous builds"
make clean || true

# Build main distributed-llama binary
echo "🔨 Building dllama binary"
make -j${PARALLEL_JOBS} dllama CC=${CC} CXX=${CXX}

# Build API server binary
echo "🔨 Building dllama-api binary"
make -j${PARALLEL_JOBS} dllama-api CC=${CC} CXX=${CXX}

# Verify binaries were created
if [ ! -f "dllama" ]; then
    echo "❌ Failed to build dllama binary"
    exit 1
fi

if [ ! -f "dllama-api" ]; then
    echo "❌ Failed to build dllama-api binary"
    exit 1
fi

# Create artifacts directory
echo "📦 Preparing artifacts"
mkdir -p /artifacts/distributed-llama

# Copy binaries with architecture suffix
cp dllama /artifacts/distributed-llama/dllama-arm64
cp dllama-api /artifacts/distributed-llama/dllama-api-arm64

# Strip binaries to reduce size
echo "✂️  Stripping binaries"
${STRIP} /artifacts/distributed-llama/dllama-arm64
${STRIP} /artifacts/distributed-llama/dllama-api-arm64

# Create build metadata
echo "📋 Creating build metadata"
cat > /artifacts/distributed-llama/build-info.txt << EOF
Build Date: $(date -Iseconds)
Version: ${DISTRIBUTED_LLAMA_VERSION}
Target Architecture: ${TARGET_ARCH}
Compiler: $(${CXX} --version | head -1)
Build Config: ${BUILD_CONFIG}
Parallel Jobs: ${PARALLEL_JOBS}
Git Commit: $(git rev-parse HEAD)
Git Branch: $(git branch --show-current)
EOF

# Create checksums for verification
echo "🔐 Creating checksums"
cd /artifacts/distributed-llama
sha256sum dllama-arm64 > dllama-arm64.sha256
sha256sum dllama-api-arm64 > dllama-api-arm64.sha256

# Display build summary
echo "✅ Build completed successfully!"
echo "📁 Artifacts created:"
ls -lh /artifacts/distributed-llama/

echo "🎉 distributed-llama ARM64 cross-compilation complete"