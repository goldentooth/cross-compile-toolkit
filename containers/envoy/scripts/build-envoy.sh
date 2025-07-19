#!/bin/bash
# Envoy ARM64 cross-compilation script for Raspberry Pi compatibility
# Addresses tcmalloc memory alignment issues (GitHub issue #23339)

set -euo pipefail

# Configuration
ENVOY_VERSION="${ENVOY_VERSION:-v1.32.0}"
MEMORY_ALLOCATOR="${MEMORY_ALLOCATOR:-disabled}"
BUILD_CONFIG="${BUILD_CONFIG:-release}"
OUTPUT_DIR="${OUTPUT_DIR:-/artifacts/envoy}"
PARALLEL_JOBS="${PARALLEL_JOBS:-8}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Print build configuration
print_config() {
    log "🔧 Envoy ARM64 Build Configuration"
    echo "   Version: ${ENVOY_VERSION}"
    echo "   Memory Allocator: ${MEMORY_ALLOCATOR}"
    echo "   Build Config: ${BUILD_CONFIG}"
    echo "   Parallel Jobs: ${PARALLEL_JOBS}"
    echo "   Output Directory: ${OUTPUT_DIR}"
    echo "   Architecture: ARM64/AArch64"
    echo "   Target: Raspberry Pi 4B (4GB+)"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log "🔍 Checking build prerequisites..."
    
    # Check cross-compilation toolchain
    if ! command -v aarch64-linux-gnu-gcc >/dev/null 2>&1; then
        error "ARM64 cross-compilation toolchain not found"
        exit 1
    fi
    
    # Check Bazel
    if ! command -v bazel >/dev/null 2>&1; then
        error "Bazel not found"
        exit 1
    fi
    
    # Check available memory (need at least 8GB for Envoy build)
    available_mem=$(awk '/MemAvailable/ {printf "%.0f", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "0")
    if [ "${available_mem}" -lt 8 ]; then
        warn "Available memory (${available_mem}GB) may be insufficient for Envoy build"
        warn "Consider reducing parallel jobs or increasing container memory"
    fi
    
    success "Prerequisites check passed"
}

# Configure Bazel for ARM64 cross-compilation
configure_bazel() {
    log "⚙️  Configuring Bazel for ARM64 cross-compilation..."
    
    # Create Bazel configuration for this build
    cat > .bazelrc.local << EOF
# Import base configuration
import %workspace%/.bazelrc.envoy

# Memory allocator configuration (addresses Raspberry Pi issue)
build:pi --define tcmalloc=${MEMORY_ALLOCATOR}

# ARM64 specific optimizations
build:pi --copt=-march=armv8-a
build:pi --copt=-mtune=cortex-a72  # Raspberry Pi 4 CPU
build:pi --linkopt=-Wl,--gc-sections

# Resource limits
build:pi --local_ram_resources=$(( available_mem * 1024 ))
build:pi --local_cpu_resources=${PARALLEL_JOBS}
build:pi --jobs=${PARALLEL_JOBS}

# Enable optimizations for release builds
build:pi-release --config=pi
build:pi-release --compilation_mode=opt
build:pi-release --strip=always
build:pi-release --linkopt=-s
build:pi-release --copt=-O3
build:pi-release --copt=-DNDEBUG

# Debug configuration
build:pi-debug --config=pi
build:pi-debug --compilation_mode=dbg
build:pi-debug --strip=never
build:pi-debug --copt=-g3
EOF

    success "Bazel configuration created"
}

# Build Envoy with ARM64 cross-compilation
build_envoy() {
    log "🚀 Starting Envoy ARM64 build..."
    
    # Determine build configuration
    local bazel_config="pi"
    if [ "${BUILD_CONFIG}" = "release" ]; then
        bazel_config="pi-release"
    elif [ "${BUILD_CONFIG}" = "debug" ]; then
        bazel_config="pi-debug"
    fi
    
    # Build command
    local build_cmd=(
        bazel build
        --config="${bazel_config}"
        --config=envoy-arm64
        --verbose_failures
        --show_timestamps
        //source/exe:envoy-static
    )
    
    log "Executing: ${build_cmd[*]}"
    
    # Start build with timeout (Envoy builds can take 2+ hours)
    if timeout 7200 "${build_cmd[@]}"; then
        success "Envoy build completed successfully"
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            error "Build timed out after 2 hours"
        else
            error "Build failed with exit code $exit_code"
        fi
        exit $exit_code
    fi
}

# Package build artifacts
package_artifacts() {
    log "📦 Packaging build artifacts..."
    
    # Create output directory
    mkdir -p "${OUTPUT_DIR}"
    
    # Find the built binary
    local envoy_binary
    envoy_binary=$(find bazel-bin -name "envoy-static" -type f | head -1)
    
    if [ -z "${envoy_binary}" ]; then
        error "Envoy binary not found in build output"
        exit 1
    fi
    
    # Copy binary to artifacts
    cp "${envoy_binary}" "${OUTPUT_DIR}/envoy-${ENVOY_VERSION}-arm64"
    
    # Create versioned symlink
    ln -sf "envoy-${ENVOY_VERSION}-arm64" "${OUTPUT_DIR}/envoy-arm64"
    
    # Verify binary architecture
    if file "${OUTPUT_DIR}/envoy-${ENVOY_VERSION}-arm64" | grep -q "ARM aarch64"; then
        success "Binary architecture verified: ARM64"
    else
        error "Binary is not ARM64 architecture"
        exit 1
    fi
    
    # Get binary info
    local binary_size
    binary_size=$(du -h "${OUTPUT_DIR}/envoy-${ENVOY_VERSION}-arm64" | cut -f1)
    
    # Create build info
    cat > "${OUTPUT_DIR}/build-info.txt" << EOF
Envoy ARM64 Build Information
============================
Version: ${ENVOY_VERSION}
Build Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')
Architecture: ARM64/AArch64
Target Platform: Raspberry Pi 4B
Memory Allocator: ${MEMORY_ALLOCATOR}
Build Configuration: ${BUILD_CONFIG}
Binary Size: ${binary_size}
Toolchain: $(aarch64-linux-gnu-gcc --version | head -1)
Bazel Version: $(bazel version | grep 'Build label' | awk '{print $3}')

Compatibility Notes:
- Fixes tcmalloc memory alignment issues on Raspberry Pi
- Compatible with standard Raspberry Pi OS (39-bit virtual addressing)
- Optimized for Cortex-A72 CPU (Raspberry Pi 4)

Usage:
  ./envoy-arm64 --config-path /path/to/envoy.yaml

Build Command:
  ${build_cmd[*]}
EOF
    
    # Create SHA256 checksums
    cd "${OUTPUT_DIR}"
    sha256sum envoy-${ENVOY_VERSION}-arm64 > envoy-${ENVOY_VERSION}-arm64.sha256
    
    success "Artifacts packaged in ${OUTPUT_DIR}"
}

# Create Debian package (optional)
create_deb_package() {
    if [ "${CREATE_DEB:-false}" = "true" ]; then
        log "📦 Creating Debian package..."
        
        local pkg_dir="/tmp/envoy-package"
        local version="${ENVOY_VERSION#v}"  # Remove 'v' prefix
        
        # Create package structure
        mkdir -p "${pkg_dir}/DEBIAN"
        mkdir -p "${pkg_dir}/usr/local/bin"
        mkdir -p "${pkg_dir}/usr/share/doc/envoy-arm64"
        
        # Copy binary
        cp "${OUTPUT_DIR}/envoy-${ENVOY_VERSION}-arm64" "${pkg_dir}/usr/local/bin/envoy"
        
        # Create control file
        cat > "${pkg_dir}/DEBIAN/control" << EOF
Package: envoy-arm64
Version: ${version}
Section: net
Priority: optional
Architecture: arm64
Maintainer: Goldentooth Cluster <admin@goldentooth.net>
Description: Envoy proxy for ARM64/Raspberry Pi
 Cross-compiled Envoy proxy optimized for Raspberry Pi deployment.
 Includes fixes for tcmalloc memory alignment issues.
Homepage: https://github.com/goldentooth/cross-compile-toolkit
EOF
        
        # Copy documentation
        cp "${OUTPUT_DIR}/build-info.txt" "${pkg_dir}/usr/share/doc/envoy-arm64/"
        
        # Build package
        dpkg-deb --build "${pkg_dir}" "${OUTPUT_DIR}/envoy-arm64_${version}_arm64.deb"
        
        success "Debian package created: envoy-arm64_${version}_arm64.deb"
    fi
}

# Main execution
main() {
    print_config
    check_prerequisites
    configure_bazel
    build_envoy
    package_artifacts
    create_deb_package
    
    log "🎉 Envoy ARM64 cross-compilation completed successfully!"
    log "📍 Artifacts available in: ${OUTPUT_DIR}"
}

# Handle signals for graceful shutdown
trap 'error "Build interrupted"; exit 130' INT TERM

# Execute main function
main "$@"