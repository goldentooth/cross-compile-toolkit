#!/bin/bash
# Workspace status script for Bazel builds
# Provides build metadata and version information

set -euo pipefail

# Build timestamp
echo "BUILD_TIMESTAMP $(date -u +%Y%m%d_%H%M%S)"

# Git information if available
if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    echo "BUILD_SCM_REVISION $(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
    echo "BUILD_SCM_STATUS $(git diff-index --quiet HEAD -- && echo 'clean' || echo 'modified')"
    echo "BUILD_SCM_BRANCH $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
else
    echo "BUILD_SCM_REVISION unknown"
    echo "BUILD_SCM_STATUS unknown"
    echo "BUILD_SCM_BRANCH unknown"
fi

# Build environment
echo "BUILD_HOST $(hostname)"
echo "BUILD_USER $(whoami)"
echo "BUILD_ARCH aarch64"
echo "TARGET_PLATFORM linux_arm64"

# Toolchain versions
echo "GCC_VERSION $(aarch64-linux-gnu-gcc --version | head -n1 | awk '{print $NF}')"
echo "CLANG_VERSION $(clang-18 --version | head -n1 | awk '{print $3}')"
echo "BAZEL_VERSION $(bazel version | grep 'Build label' | awk '{print $3}')"