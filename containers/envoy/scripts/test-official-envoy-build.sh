#!/bin/bash
# Test using official Envoy build environment for ARM64

set -euo pipefail

echo "Testing official Envoy ARM64 build environment..."
echo ""

cd /workspace/envoy

echo "=== Checking Envoy's official build documentation ==="
if [ -f DEVELOPER.md ]; then
    echo "Found DEVELOPER.md - checking for ARM64 instructions:"
    grep -n -i -A5 -B5 "aarch64\|arm64\|cross.*compil" DEVELOPER.md || echo "No ARM64 instructions found"
fi
echo ""

echo "=== Checking for build scripts ==="
find . -name "*build*" -type f | grep -v bazel-out | head -10
echo ""

echo "=== Checking ci/ directory for official build configs ==="
if [ -d ci ]; then
    ls -la ci/ | head -10
    echo ""
    echo "Looking for ARM64 configurations in ci/:"
    find ci/ -name "*arm*" -o -name "*aarch64*" | head -5
fi
echo ""

echo "=== Trying Envoy's official cross-compilation approach ==="
# Check if there's a specific script or documented approach
if [ -f ci/do_ci.sh ]; then
    echo "Found ci/do_ci.sh - checking for ARM64 support:"
    grep -n "aarch64\|arm64" ci/do_ci.sh || echo "No ARM64 support in ci script"
fi
echo ""

echo "=== Using official Envoy Docker build approach ==="
# Pull the official Envoy build image that supports ARM64
echo "Pulling official Envoy build image..."
podman pull --platform linux/arm64 docker.io/envoyproxy/envoy-build-ubuntu:mobile-v1.32.0 2>/dev/null || \
podman pull --platform linux/arm64 docker.io/envoyproxy/envoy-build-ubuntu:v1.32.0 2>/dev/null || \
echo "Official ARM64 build image not available"

# Check if official image has better toolchain support
echo ""
echo "=== Testing build in official environment ==="
echo "Trying with official Envoy build process..."

# Use Envoy's standard build process
./ci/run_envoy_docker.sh 'bazel build --config=release-arm64 //source/exe:envoy-static' || \
echo "Official build script not available or failed"

echo ""
echo "=== Alternative: Manual build with proper environment ==="
# Try the approach documented in Envoy's ARM64 support
bazel build \
    --config=release \
    --cpu=aarch64 \
    --define=tcmalloc=disabled \
    --define=signal_trace=disabled \
    --define=hot_restart=disabled \
    --action_env=CC=aarch64-linux-gnu-gcc \
    --action_env=CXX=aarch64-linux-gnu-g++ \
    --verbose_failures \
    --jobs=2 \
    //source/exe:envoy-static

build_result=$?

if [ $build_result -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS: Official approach worked!"
    echo ""
    echo "=== Verifying ARM64 binary ==="
    file bazel-bin/source/exe/envoy-static
    echo ""
    echo "=== Copying to artifacts ==="
    mkdir -p /artifacts/envoy
    cp bazel-bin/source/exe/envoy-static /artifacts/envoy/envoy-v1.32.0-arm64-official
    echo "✅ Official Envoy ARM64 binary ready!"
else
    echo ""
    echo "❌ Official build approach also failed"
    echo "Issue appears to be fundamental Bazel toolchain configuration"
    echo ""
    echo "=== Summary of attempts ==="
    echo "1. ❌ Custom cross-compilation setup - Bazel toolchain missing"
    echo "2. ❌ Platform-based approach - Wrong platform type"  
    echo "3. ❌ CPU-based approach - Bazel toolchain missing"
    echo "4. ❌ Official Envoy approach - Same toolchain issue"
    echo ""
    echo "Recommendation: Envoy ARM64 cross-compilation may not be supported"
    echo "in this Bazel version, or requires specific build environment setup"
    echo "that we haven't identified yet."
fi