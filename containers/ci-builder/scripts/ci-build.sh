#!/bin/bash
# CI build script for automated builds

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Build all containers
build_all() {
    log "Building all containers for CI"
    
    # Build base builder
    docker build -t goldentooth/base-builder:ci containers/base-builder/
    
    # Build Envoy builder
    docker build -t goldentooth/envoy-builder:ci containers/envoy/
    
    log "All containers built successfully"
}

# Test cross-compilation environment
test_environment() {
    log "Testing cross-compilation environment"
    
    docker run --rm goldentooth/base-builder:ci /usr/local/bin/cross-compile-test.sh
    
    log "Environment test completed"
}

# Main execution
main() {
    case "${1:-build}" in
        build)
            build_all
            ;;
        test)
            test_environment
            ;;
        all)
            build_all
            test_environment
            ;;
        *)
            echo "Usage: $0 {build|test|all}"
            exit 1
            ;;
    esac
}

main "$@"