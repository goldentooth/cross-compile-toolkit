#!/bin/bash
# Test Bazel ARM64 cross-compilation with proper toolchain

set -euo pipefail

echo "Testing Bazel ARM64 cross-compilation with custom toolchain..."
echo ""

# Create a test workspace
mkdir -p /tmp/bazel_toolchain_test
cd /tmp/bazel_toolchain_test

# Simple C++ program
cat > hello.cc << 'EOF'
#include <iostream>
int main() {
    std::cout << "Hello ARM64 from Bazel!" << std::endl;
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

# WORKSPACE file with toolchain registration
cat > WORKSPACE << 'EOF'
workspace(name = "test")

# Register custom ARM64 toolchain
register_toolchains("//toolchain:aarch64_linux_toolchain")
EOF

# Create toolchain directory
mkdir -p toolchain

# ARM64 toolchain definition
cat > toolchain/BUILD << 'EOF'
load(":cc_toolchain.bzl", "cc_toolchain_config")

package(default_visibility = ["//visibility:public"])

cc_toolchain_config(
    name = "aarch64_linux_config",
    cpu = "aarch64",
    compiler = "gcc",
    toolchain_identifier = "aarch64-linux-gnu",
    host_system_name = "x86_64-unknown-linux-gnu",
    target_system_name = "aarch64-unknown-linux-gnu",
    target_libc = "glibc_2.31",
    abi_version = "gcc",
    abi_libc_version = "glibc_2.31",
    tool_paths = {
        "gcc": "/usr/bin/aarch64-linux-gnu-gcc",
        "ld": "/usr/bin/aarch64-linux-gnu-ld",
        "ar": "/usr/bin/aarch64-linux-gnu-ar",
        "cpp": "/usr/bin/aarch64-linux-gnu-cpp",
        "gcov": "/usr/bin/aarch64-linux-gnu-gcov",
        "nm": "/usr/bin/aarch64-linux-gnu-nm",
        "objdump": "/usr/bin/aarch64-linux-gnu-objdump",
        "strip": "/usr/bin/aarch64-linux-gnu-strip",
    },
    compile_flags = [
        "-U_FORTIFY_SOURCE",
        "-fstack-protector",
        "-Wall",
        "-Wunused-but-set-parameter",
        "-Wno-free-nonheap-object",
        "-fno-omit-frame-pointer",
    ],
    link_flags = [
        "-lstdc++",
        "-lm",
    ],
    cxx_builtin_include_directories = [
        "/usr/aarch64-linux-gnu/include/c++/11",
        "/usr/aarch64-linux-gnu/include/c++/11/aarch64-linux-gnu",
        "/usr/aarch64-linux-gnu/include",
        "/usr/lib/gcc-cross/aarch64-linux-gnu/11/include",
    ],
)

cc_toolchain(
    name = "aarch64_linux_toolchain",
    toolchain_config = ":aarch64_linux_config",
    all_files = ":empty",
    compiler_files = ":empty",
    dwp_files = ":empty",
    linker_files = ":empty",
    objcopy_files = ":empty",
    strip_files = ":empty",
    supports_param_files = 0,
)

toolchain(
    name = "aarch64_linux_toolchain",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:aarch64",
    ],
    toolchain = ":aarch64_linux_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
)

filegroup(name = "empty")
EOF

# Simplified toolchain configuration
cat > toolchain/cc_toolchain.bzl << 'EOF'
load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "cc_toolchain_config")

def _impl(ctx):
    return cc_toolchain_config(
        ctx = ctx,
        toolchain_identifier = ctx.attr.toolchain_identifier,
        host_system_name = ctx.attr.host_system_name,
        target_system_name = ctx.attr.target_system_name,
        target_cpu = ctx.attr.cpu,
        target_libc = ctx.attr.target_libc,
        compiler = ctx.attr.compiler,
        abi_version = ctx.attr.abi_version,
        abi_libc_version = ctx.attr.abi_libc_version,
        tool_paths = [
            tool_path(name = name, path = path)
            for name, path in ctx.attr.tool_paths.items()
        ],
        compile_flags = ctx.attr.compile_flags,
        link_flags = ctx.attr.link_flags,
        cxx_builtin_include_directories = ctx.attr.cxx_builtin_include_directories,
    )

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {
        "cpu": attr.string(mandatory = True),
        "compiler": attr.string(mandatory = True),
        "toolchain_identifier": attr.string(mandatory = True),
        "host_system_name": attr.string(mandatory = True),
        "target_system_name": attr.string(mandatory = True),
        "target_libc": attr.string(mandatory = True),
        "abi_version": attr.string(mandatory = True),
        "abi_libc_version": attr.string(mandatory = True),
        "tool_paths": attr.string_dict(mandatory = True),
        "compile_flags": attr.string_list(),
        "link_flags": attr.string_list(),
        "cxx_builtin_include_directories": attr.string_list(),
    },
    provides = [CcToolchainConfigInfo],
)
EOF

# Bazel configuration
cat > .bazelrc << 'EOF'
# Use custom ARM64 toolchain
build --cpu=aarch64
build --incompatible_enable_cc_toolchain_resolution

# Resource limits  
build --jobs=2
build --local_cpu_resources=2
EOF

echo "=== Testing Bazel ARM64 toolchain setup ==="
echo ""

echo "Building with custom toolchain..."
bazel build //:hello --verbose_failures

if [ $? -eq 0 ]; then
    echo "✓ Bazel ARM64 build successful!"
    echo ""
    echo "Checking binary:"
    file bazel-bin/hello
    echo ""
    echo "ARM64 verification:"
    readelf -h bazel-bin/hello | grep -E "(Class|Machine)" || echo "Could not read ELF header"
else
    echo "✗ Bazel ARM64 build failed"
fi