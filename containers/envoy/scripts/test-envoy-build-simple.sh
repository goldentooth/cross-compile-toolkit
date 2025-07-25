#!/bin/bash
# Test using Envoy's own cross-compilation configuration

set -euo pipefail

echo "Testing with Envoy's built-in ARM64 configuration..."
echo ""

cd /workspace/envoy

# Check if Envoy has ARM64 platform definitions
echo "=== Checking Envoy's platform configurations ==="
find . -name "*.bzl" -exec grep -l "aarch64\|arm64" {} \; 2>/dev/null | head -5
echo ""

echo "=== Looking for existing ARM64 configurations ==="
find . -name "BUILD*" -exec grep -l "aarch64\|arm64" {} \; 2>/dev/null | head -5
echo ""

# Try building a simple Envoy component instead of the full binary
echo "=== Testing simple Envoy component build ==="

# Create a minimal .bazelrc that uses Envoy's configurations
cat > .bazelrc.test << 'EOF'
# Use Envoy's built-in ARM64 platform
build --platforms=@envoy//bazel:linux_aarch64

# Disable problematic features for cross-compilation  
build --define tcmalloc=disabled
build --define signal_trace=disabled
build --define hot_restart=disabled
build --define wasm=disabled

# Cross-compilation environment
build --action_env=CC=aarch64-linux-gnu-gcc
build --action_env=CXX=aarch64-linux-gnu-g++

# Resource limits
build --jobs=2
build --local_cpu_resources=2
build --verbose_failures
EOF

echo "=== Testing with Envoy's platform configuration ==="
echo "Using configuration:"
cat .bazelrc.test
echo ""

# Try building a simple Envoy library first
echo "Building Envoy version library (simpler than full binary)..."
bazel --bazelrc=.bazelrc.test build //source/common/version:version_lib

build_result=$?

if [ $build_result -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS: Envoy component build worked!"
    echo ""
    echo "Now trying small Envoy executable..."
    bazel --bazelrc=.bazelrc.test build //test/tools/router_check:router_check_tool
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 SUCCESS: Small Envoy executable built!"
        echo ""
        echo "Checking binary:"
        file bazel-bin/test/tools/router_check/router_check_tool
        echo ""
        echo "Now ready to attempt full Envoy build..."
    else
        echo "Small executable failed, but library worked - progress!"
    fi
else
    echo ""
    echo "❌ Component build failed. Checking error details..."
    
    # Check if the platform exists
    echo ""
    echo "=== Checking if @envoy//bazel:linux_aarch64 platform exists ==="
    bazel query @envoy//bazel:linux_aarch64 2>&1 || echo "Platform not found"
    
    echo ""
    echo "=== Available platforms in @envoy//bazel ==="
    bazel query 'kind(platform, @envoy//bazel:*)' 2>&1 || echo "Could not query platforms"
fi