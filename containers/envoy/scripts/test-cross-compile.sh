#!/bin/bash
# Test ARM64 cross-compilation environment with simple programs

set -euo pipefail

echo "Testing ARM64 cross-compilation environment..."
echo ""

# Test 1: Simple C program
echo "=== Test 1: Simple C program ==="
cat > test_program.c << 'EOF'
#include <stdio.h>
int main() {
    printf("Hello from ARM64!\n");
    return 0;
}
EOF

echo "Compiling with aarch64-linux-gnu-gcc..."
aarch64-linux-gnu-gcc -o test_program_arm64 test_program.c
echo "✓ C compilation successful"

echo "Checking binary architecture..."
file test_program_arm64
echo ""

# Test 2: Simple Go program  
echo "=== Test 2: Simple Go program ==="
cat > test_program.go << 'EOF'
package main
import "fmt"
func main() {
    fmt.Println("Hello from Go ARM64!")
}
EOF

echo "Setting Go cross-compilation environment..."
export GOOS=linux
export GOARCH=arm64
export CGO_ENABLED=1
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++

echo "Compiling Go program..."
go build -o test_program_go_arm64 test_program.go
echo "✓ Go compilation successful"

echo "Checking Go binary architecture..."
file test_program_go_arm64
echo ""

# Test 3: Simple Bazel BUILD file
echo "=== Test 3: Simple Bazel program ==="
mkdir -p simple_test
cd simple_test

cat > BUILD << 'EOF'
cc_binary(
    name = "hello_arm64",
    srcs = ["hello.cc"],
)
EOF

cat > hello.cc << 'EOF'
#include <iostream>
int main() {
    std::cout << "Hello from Bazel ARM64!" << std::endl;
    return 0;
}
EOF

cat > .bazelrc << 'EOF'
# ARM64 cross-compilation
build --platforms=@platforms//os:linux
build --cpu=aarch64
build --action_env=CC=aarch64-linux-gnu-gcc
build --action_env=CXX=aarch64-linux-gnu-g++
build --action_env=AR=aarch64-linux-gnu-ar
build --action_env=STRIP=aarch64-linux-gnu-strip

# Go settings for ARM64
build --action_env=GOOS=linux
build --action_env=GOARCH=arm64
build --action_env=CGO_ENABLED=1
EOF

echo "Building with Bazel..."
bazel build //:hello_arm64 --verbose_failures
echo "✓ Bazel compilation successful"

echo "Checking Bazel binary architecture..."
file bazel-bin/hello_arm64
echo ""

echo "=== Cross-compilation test summary ==="
echo "✓ C cross-compilation: WORKING"
echo "✓ Go cross-compilation: WORKING" 
echo "✓ Bazel cross-compilation: WORKING"
echo ""
echo "Environment is ready for Envoy ARM64 build!"