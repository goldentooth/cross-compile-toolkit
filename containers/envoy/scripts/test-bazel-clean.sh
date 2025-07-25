#!/bin/bash
# Test Bazel ARM64 cross-compilation without existing config interference

set -euo pipefail

echo "Testing clean Bazel ARM64 cross-compilation..."
echo ""

# Create completely clean test workspace
mkdir -p /tmp/bazel_clean_test
cd /tmp/bazel_clean_test

# Remove any existing Bazel state
rm -rf ~/.cache/bazel/ || true

# Simple C++ program
cat > hello.cc << 'EOF'
#include <iostream>
int main() {
    std::cout << "Hello ARM64 from clean Bazel!" << std::endl;
    return 0;
}
EOF

# BUILD file
cat > BUILD << 'EOF'
cc_binary(
    name = "hello",
    srcs = ["hello.cc"],
    linkstatic = True,
)
EOF

# WORKSPACE file
cat > WORKSPACE << 'EOF'
workspace(name = "clean_test")
EOF

# Clean .bazelrc with minimal ARM64 configuration
cat > .bazelrc << 'EOF'
# Clean ARM64 cross-compilation
build --cpu=aarch64
build --action_env=CC=aarch64-linux-gnu-gcc
build --action_env=CXX=aarch64-linux-gnu-g++
build --linkopt=-static-libgcc
build --linkopt=-static-libstdc++
build --jobs=2
build --local_cpu_resources=2
build --verbose_failures
EOF

echo "=== Clean workspace contents ==="
ls -la
echo ""

echo "=== Clean .bazelrc ==="
cat .bazelrc
echo ""

echo "=== Checking cross-compilation toolchain availability ==="
which aarch64-linux-gnu-gcc
aarch64-linux-gnu-gcc --version | head -1
echo ""

echo "=== Building with clean Bazel configuration ==="
# Use --ignore_all_rc_files to completely ignore global config
bazel --ignore_all_rc_files build //:hello --cpu=aarch64 \
    --action_env=CC=aarch64-linux-gnu-gcc \
    --action_env=CXX=aarch64-linux-gnu-g++ \
    --verbose_failures \
    --jobs=2

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS: Clean Bazel ARM64 build completed!"
    echo ""
    echo "=== Binary verification ==="
    file bazel-bin/hello
    echo ""
    echo "=== ELF details ==="
    readelf -h bazel-bin/hello | grep -E "(Class|Data|Machine|Entry)"
    echo ""
    echo "=== Binary size ==="
    ls -lh bazel-bin/hello
    echo ""
    echo "✅ ARM64 cross-compilation working correctly!"
else
    echo ""
    echo "❌ FAILED: Clean Bazel build failed"
    exit 1
fi