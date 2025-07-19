#!/bin/bash
# Test script to verify cross-compilation environment

set -euo pipefail

echo "🔧 Testing ARM64 cross-compilation environment..."

# Test basic compilation
echo "📝 Testing basic C compilation..."
cat > /tmp/test.c << 'EOF'
#include <stdio.h>
#include <unistd.h>

int main() {
    printf("Hello from ARM64!\n");
    printf("Architecture: ");
#ifdef __aarch64__
    printf("ARM64/AArch64\n");
#else
    printf("Not ARM64\n");
#endif
    return 0;
}
EOF

aarch64-linux-gnu-gcc -o /tmp/test_arm64 /tmp/test.c
echo "✅ C compilation successful"

# Verify binary architecture
if file /tmp/test_arm64 | grep -q "ARM aarch64"; then
    echo "✅ Binary is ARM64 architecture"
else
    echo "❌ Binary is not ARM64 architecture"
    exit 1
fi

# Test C++ compilation
echo "📝 Testing C++ compilation..."
cat > /tmp/test.cpp << 'EOF'
#include <iostream>
#include <vector>

int main() {
    std::vector<int> v = {1, 2, 3, 4, 5};
    std::cout << "C++ ARM64 test - vector size: " << v.size() << std::endl;
    return 0;
}
EOF

aarch64-linux-gnu-g++ -o /tmp/test_cpp_arm64 /tmp/test.cpp
echo "✅ C++ compilation successful"

# Test pkg-config
echo "📝 Testing pkg-config setup..."
if PKG_CONFIG_PATH="$PKG_CONFIG_PATH" pkg-config --exists zlib; then
    echo "✅ pkg-config can find ARM64 libraries"
else
    echo "⚠️  pkg-config cannot find ARM64 libraries"
fi

# Test Bazel
echo "📝 Testing Bazel installation..."
if bazel version >/dev/null 2>&1; then
    echo "✅ Bazel is installed and working"
    bazel version | grep "Build label"
else
    echo "❌ Bazel is not working"
    exit 1
fi

# Test memory allocator libraries
echo "📝 Testing memory allocator libraries..."
if ldconfig -p | grep -q "libgoogle-perftools"; then
    echo "✅ gperftools available"
else
    echo "⚠️  gperftools not found"
fi

if ldconfig -p | grep -q "libjemalloc"; then
    echo "✅ jemalloc available"
else
    echo "⚠️  jemalloc not found"
fi

# Cleanup
rm -f /tmp/test.c /tmp/test.cpp /tmp/test_arm64 /tmp/test_cpp_arm64

echo ""
echo "🎉 Cross-compilation environment test completed successfully!"
echo "🚀 Ready to build ARM64 binaries for Raspberry Pi cluster"