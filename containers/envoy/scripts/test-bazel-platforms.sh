#!/bin/bash
# Test Bazel ARM64 cross-compilation using platforms

set -euo pipefail

echo "Testing Bazel ARM64 cross-compilation with platforms..."
echo ""

# Create test workspace
mkdir -p /tmp/bazel_platforms_test
cd /tmp/bazel_platforms_test

# Simple C++ program
cat > hello.cc << 'EOF'
#include <iostream>
int main() {
    std::cout << "Hello ARM64!" << std::endl;
    return 0;
}
EOF

# BUILD file
cat > BUILD << 'EOF'
cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
)
EOF

# WORKSPACE file
cat > WORKSPACE << 'EOF'
workspace(name = "test_platforms")
EOF

# Platform configuration - create platform directory
mkdir -p platforms

cat > platforms/BUILD << 'EOF'
platform(
    name = "linux_aarch64",
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:aarch64",
    ],
)
EOF

# .bazelrc with platform and toolchain configuration
cat > .bazelrc << 'EOF'
# ARM64 cross-compilation using platforms
build:arm64 --platforms=//platforms:linux_aarch64

# Set toolchain environment for cross-compilation
build:arm64 --action_env=CC=aarch64-linux-gnu-gcc
build:arm64 --action_env=CXX=aarch64-linux-gnu-g++
build:arm64 --action_env=AR=aarch64-linux-gnu-ar
build:arm64 --action_env=STRIP=aarch64-linux-gnu-strip

# Linker flags to avoid issues
build:arm64 --linkopt=-static-libgcc
build:arm64 --copt=-static-libgcc

# Use the new toolchain resolution
build:arm64 --incompatible_enable_cc_toolchain_resolution

# Compiler flags
build:arm64 --copt=-march=armv8-a
build:arm64 --copt=-mtune=generic

# Resource limits
build:arm64 --jobs=2
build:arm64 --local_cpu_resources=2
EOF

echo "=== Directory structure ==="
find . -type f | sort
echo ""

echo "=== Platform configuration ==="
cat platforms/BUILD
echo ""

echo "=== Bazel configuration ==="
cat .bazelrc
echo ""

echo "=== Building with platforms approach ==="
bazel build //:hello --config=arm64 --verbose_failures

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ SUCCESS: Bazel ARM64 build with platforms!"
    echo ""
    echo "Binary verification:"
    file bazel-bin/hello
    echo ""
    echo "ELF header info:"
    readelf -h bazel-bin/hello | head -10
    echo ""
    echo "Size and permissions:"
    ls -la bazel-bin/hello
else
    echo ""
    echo "✗ FAILED: Bazel ARM64 build failed"
    echo ""
    echo "Checking for build logs..."
    find . -name "*.log" -type f 2>/dev/null | head -3 | while read logfile; do
        echo "=== $logfile ==="
        tail -20 "$logfile"
        echo ""
    done
fi