#!/bin/bash
# Find correct Envoy ARM64 platform configuration

set -euo pipefail

echo "Finding Envoy's ARM64 platform configuration..."
echo ""

cd /workspace/envoy

echo "=== Checking what //bazel:linux_aarch64 actually is ==="
bazel query //bazel:linux_aarch64 --output=build 2>&1 || echo "Could not query target"
echo ""

echo "=== Looking for all platform targets in Envoy ==="
bazel query 'kind(platform, //...)' 2>&1 | head -10 || echo "No platforms found"
echo ""

echo "=== Checking bazel/ directory contents ==="
ls -la bazel/ | head -10
echo ""

echo "=== Looking for ARM64/aarch64 references in bazel files ==="
grep -r "aarch64\|arm64" bazel/ | head -10
echo ""

echo "=== Checking Envoy's .bazelrc for platform configurations ==="
if [ -f .bazelrc ]; then
    echo "Found .bazelrc:"
    grep -n "platform\|aarch64\|arm64" .bazelrc | head -10
else
    echo "No .bazelrc found"
fi
echo ""

echo "=== Looking for toolchain definitions ==="
find bazel/ -name "*.bzl" -exec grep -l "toolchain\|platform" {} \; | head -5
echo ""

echo "=== Checking for cross-compilation examples in documentation ==="
find . -name "*.md" -exec grep -l "cross.*compil\|aarch64\|arm64" {} \; 2>/dev/null | head -5
echo ""

echo "=== Trying to build with default platform ==="
echo "Testing simple build without platform specification..."
bazel build //source/common/version:version_lib \
    --define tcmalloc=disabled \
    --action_env=CC=aarch64-linux-gnu-gcc \
    --action_env=CXX=aarch64-linux-gnu-g++ \
    --jobs=2 \
    --verbose_failures \
    --cpu=k8  # Use default CPU instead of aarch64

build_result=$?
if [ $build_result -eq 0 ]; then
    echo "✅ SUCCESS: Default build worked - we can build Envoy components!"
    echo "Now we just need to configure cross-compilation properly."
else
    echo "❌ Default build also failed - deeper issue with build environment"
fi