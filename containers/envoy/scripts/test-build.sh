#!/bin/bash
# Quick test of Envoy ARM64 build environment

set -euo pipefail

echo "Testing Envoy ARM64 cross-compilation environment..."
echo ""

# Check Bazel version
echo "Bazel version:"
bazel version | grep 'Build label' || true
echo ""

# Check ARM64 toolchain
echo "ARM64 toolchain:"
aarch64-linux-gnu-gcc --version | head -1 || true
echo ""

# Navigate to workspace
cd /workspace/envoy

# Try to fetch dependencies first
echo "Fetching Envoy dependencies..."
bazel fetch //source/exe:envoy-static || true
echo ""

# Try a minimal build to test configuration
echo "Testing minimal build configuration..."
bazel build \
    --platforms=@envoy//bazel:linux_aarch64 \
    --define tcmalloc=disabled \
    --verbose_failures \
    --show_result=10 \
    //source/common/version:version_lib || true

echo ""
echo "Test complete!"