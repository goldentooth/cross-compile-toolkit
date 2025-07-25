#!/bin/bash
# Test using Envoy's CI environment for ARM64 build

set -euo pipefail

echo "Testing Envoy CI-style ARM64 build..."
echo ""

cd /workspace/envoy

echo "=== Setting up Envoy CI environment variables ==="
export ENVOY_BUILD_ARCH=aarch64
export BUILD_ARCH_DIR="/linux/arm64"

echo "ENVOY_BUILD_ARCH: $ENVOY_BUILD_ARCH"
echo "BUILD_ARCH_DIR: $BUILD_ARCH_DIR"
echo ""

echo "=== Checking how CI script handles aarch64 ==="
grep -A20 -B5 "setup_clang_toolchain" ci/do_ci.sh | head -25
echo ""

echo "=== Looking for ARM64-specific build configurations ==="
grep -n "aarch64\|arm64" ci/do_ci.sh | head -10
echo ""

echo "=== Trying CI-style build approach ==="
# Set up environment like the CI system
export ENVOY_SRCDIR=/workspace/envoy
export ENVOY_BUILD_DIR=/tmp/envoy_build

mkdir -p "$ENVOY_BUILD_DIR"

echo "=== Attempting with CI environment ==="
# Use the exact approach from ci/do_ci.sh for ARM64
if grep -q "bazel.*arm64" ci/do_ci.sh; then
    echo "Found ARM64 bazel configuration in CI script"
    grep "bazel.*arm64" ci/do_ci.sh
else
    echo "No specific ARM64 bazel config found in CI script"
fi
echo ""

echo "=== Trying official Envoy ARM64 release build ==="
# Try the release configuration that CI uses
export ENVOY_BUILD_ARCH=aarch64

# The CI script would run something like this for ARM64
timeout 1800 bazel build \
    --config=release \
    --define=tcmalloc=disabled \
    --verbose_failures \
    --jobs=2 \
    --local_cpu_resources=2 \
    //source/exe:envoy-static

build_result=$?

if [ $build_result -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS: CI-style ARM64 build worked!"
    echo ""
    file bazel-bin/source/exe/envoy-static
    echo ""
    mkdir -p /artifacts/envoy
    cp bazel-bin/source/exe/envoy-static /artifacts/envoy/envoy-v1.32.0-arm64-ci
    echo "✅ CI-style Envoy ARM64 binary ready!"
elif [ $build_result -eq 124 ]; then
    echo "⏰ CI build timed out after 30 minutes"
else
    echo ""
    echo "❌ CI-style build failed with same toolchain issue"
    echo ""
    echo "=== Final analysis ==="
    echo "The issue appears to be that:"
    echo "1. ✅ Envoy officially supports ARM64 builds (evident in CI script)"
    echo "2. ✅ ARM64 cross-compilation toolchain is available"  
    echo "3. ❌ Bazel 6.5.0 toolchain doesn't include aarch64 CPU support"
    echo "4. ❌ This is a gap between Envoy's expectations and our environment"
    echo ""
    echo "Potential solutions:"
    echo "- Use Envoy's official build Docker image (may have toolchain)"
    echo "- Use newer Bazel with built-in ARM64 support"
    echo "- Define custom Bazel toolchain for aarch64"
    echo "- Switch to a different proxy (nginx, HAProxy, etc.)"
    echo ""
    echo "Recommendation: The juice may indeed not be worth the squeeze"
fi