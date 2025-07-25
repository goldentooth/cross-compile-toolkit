#!/bin/bash
# Test simple Bazel ARM64 cross-compilation

set -euo pipefail

echo "Testing Bazel ARM64 cross-compilation..."
echo ""

# Create a simple test workspace
mkdir -p /tmp/bazel_test
cd /tmp/bazel_test

# Simple C++ program
cat > hello.cc << 'EOF'
#include <iostream>
#include <string>

int main() {
    std::string message = "Hello from ARM64!";
    std::cout << message << std::endl;
    return 0;
}
EOF

# Simple BUILD file
cat > BUILD << 'EOF'
cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    linkopts = ["-static-libgcc", "-static-libstdc++"],
)
EOF

# WORKSPACE file
cat > WORKSPACE << 'EOF'
workspace(name = "test")
EOF

# Bazel configuration for ARM64
cat > .bazelrc << 'EOF'
# ARM64 cross-compilation configuration
build --cpu=aarch64
build --action_env=CC=aarch64-linux-gnu-gcc
build --action_env=CXX=aarch64-linux-gnu-g++
build --action_env=AR=aarch64-linux-gnu-ar
build --action_env=STRIP=aarch64-linux-gnu-strip

# Linker configuration to avoid gold linker issues
build --linkopt=-fuse-ld=bfd
build --action_env=BAZEL_LINKLIBS=
build --action_env=BAZEL_LINKOPTS=

# Disable problematic features
build --copt=-Wno-error
build --host_copt=-Wno-error

# Resource limits
build --jobs=2
build --local_cpu_resources=2
EOF

echo "Bazel configuration:"
cat .bazelrc
echo ""

echo "Building with Bazel..."
bazel build //:hello --verbose_failures --sandbox_debug

if [ $? -eq 0 ]; then
    echo "✓ Bazel build successful!"
    echo ""
    echo "Checking binary architecture..."
    file bazel-bin/hello
    echo ""
    echo "Binary info:"
    ls -la bazel-bin/hello
    readelf -h bazel-bin/hello | grep Machine || echo "Could not read ELF header"
else
    echo "✗ Bazel build failed"
    echo ""
    echo "Checking Bazel logs..."
    find . -name "*.log" -exec echo "=== {} ===" \; -exec cat {} \; 2>/dev/null || true
fi