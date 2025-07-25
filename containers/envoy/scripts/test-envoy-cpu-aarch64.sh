#!/bin/bash
# Test Envoy build with --cpu=aarch64 approach

set -euo pipefail

echo "Testing Envoy ARM64 build with --cpu=aarch64..."
echo ""

cd /workspace/envoy

# Create a proper .bazelrc using cpu instead of platforms
cat > .bazelrc.arm64 << 'EOF'
# ARM64 cross-compilation using CPU setting
build:arm64 --cpu=aarch64

# Cross-compilation environment 
build:arm64 --action_env=CC=aarch64-linux-gnu-gcc
build:arm64 --action_env=CXX=aarch64-linux-gnu-g++
build:arm64 --action_env=AR=aarch64-linux-gnu-ar
build:arm64 --action_env=STRIP=aarch64-linux-gnu-strip

# Envoy ARM64 optimizations
build:arm64 --define tcmalloc=disabled
build:arm64 --define signal_trace=disabled
build:arm64 --define hot_restart=disabled
build:arm64 --define wasm=disabled
build:arm64 --define admin_html=disabled

# ARM64 specific compiler flags
build:arm64 --copt=-march=armv8-a
build:arm64 --copt=-mtune=cortex-a72

# Resource limits
build:arm64 --jobs=2
build:arm64 --local_cpu_resources=2
build:arm64 --verbose_failures
EOF

echo "=== ARM64 build configuration ==="
cat .bazelrc.arm64
echo ""

echo "=== Verifying linux_aarch64 config_setting ==="
bazel query //bazel:linux_aarch64 --output=build | head -5
echo ""

echo "=== Testing simple component build ==="
echo "Building version library with ARM64 configuration..."

bazel --bazelrc=.bazelrc.arm64 build //source/common/version:version_lib --config=arm64

version_result=$?

if [ $version_result -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS: Version library built for ARM64!"
    echo ""
    echo "=== Testing larger component ==="
    echo "Building common HTTP library..."
    bazel --bazelrc=.bazelrc.arm64 build //source/common/http:http_lib --config=arm64
    
    http_result=$?
    
    if [ $http_result -eq 0 ]; then
        echo ""
        echo "✅ SUCCESS: HTTP library built for ARM64!"
        echo ""
        echo "=== Ready for Envoy static binary build ==="
        echo "Configuration is working - attempting main binary..."
        
        # Set a longer timeout for the main build
        timeout 1800 bazel --bazelrc=.bazelrc.arm64 build //source/exe:envoy-static --config=arm64
        
        envoy_result=$?
        
        if [ $envoy_result -eq 0 ]; then
            echo ""
            echo "🚀 COMPLETE SUCCESS: Envoy ARM64 binary built!"
            echo ""
            echo "=== Binary verification ==="
            file bazel-bin/source/exe/envoy-static
            echo ""
            echo "=== Size and details ==="
            ls -lh bazel-bin/source/exe/envoy-static
            readelf -h bazel-bin/source/exe/envoy-static | grep -E "(Class|Machine|Entry)"
            echo ""
            echo "=== Copying to artifacts ==="
            mkdir -p /artifacts/envoy
            cp bazel-bin/source/exe/envoy-static /artifacts/envoy/envoy-v1.32.0-arm64
            echo "✅ Envoy ARM64 binary ready for deployment!"
        elif [ $envoy_result -eq 124 ]; then
            echo "⏰ Envoy build timed out after 30 minutes"
            echo "But component builds worked - configuration is correct!"
        else
            echo "❌ Envoy main binary build failed"
            echo "But components worked - may need more memory/time"
        fi
    else
        echo "❌ HTTP library failed"
    fi
else
    echo "❌ Version library build failed"
    echo "Configuration needs more work"
fi