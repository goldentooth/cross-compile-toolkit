# Goldentooth Envoy Cross-Compilation Container
# Builds ARM64 Envoy binaries compatible with Raspberry Pi

FROM goldentooth/base-builder:latest

# Envoy version and build configuration
ARG ENVOY_VERSION=v1.32.0
ARG MEMORY_ALLOCATOR=disabled

# Environment variables for Envoy build
ENV ENVOY_VERSION=${ENVOY_VERSION}
ENV MEMORY_ALLOCATOR=${MEMORY_ALLOCATOR}

# Switch to root for package installation
USER root

# Ensure cross-compilation environment is preserved from base image
ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV CC=aarch64-linux-gnu-gcc
ENV CXX=aarch64-linux-gnu-g++
ENV AR=aarch64-linux-gnu-ar
ENV STRIP=aarch64-linux-gnu-strip
ENV PATH=/usr/bin:$PATH

# Install additional dependencies for Envoy
RUN apt-get update && apt-get install -y \
    # Additional build tools for Envoy
    autoconf \
    automake \
    libtool \
    \
    # Protocol buffers
    protobuf-compiler \
    libprotobuf-dev \
    \
    # Networking libraries
    libpcre3-dev \
    \
    # Compression libraries  
    libbz2-dev \
    liblzma-dev \
    \
    # Cross-compilation toolchain
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    \
    && rm -rf /var/lib/apt/lists/*

# Create Envoy-specific directories
RUN mkdir -p /workspace/envoy /artifacts/envoy /tmp/bazel-cache && \
    chown -R builder:builder /workspace /artifacts /tmp/bazel-cache

# Copy Envoy build scripts and patches
COPY --chown=builder:builder scripts/ /usr/local/bin/
COPY --chown=builder:builder patches/ /workspace/patches/
RUN chmod +x /usr/local/bin/build-envoy.sh

# Create Envoy-specific Bazel configuration
COPY --chown=builder:builder envoy.bazelrc /home/builder/.bazelrc.envoy
RUN chown builder:builder /home/builder/.bazelrc.envoy

# Switch back to builder user
USER builder

# Set up Envoy workspace
WORKDIR /workspace/envoy

# Clone Envoy repository (done at build time for layer caching)
RUN git clone --depth 1 --branch ${ENVOY_VERSION} https://github.com/envoyproxy/envoy.git . && \
    git submodule update --init --recursive

# Apply patches for Raspberry Pi compatibility
RUN if [ -d /workspace/patches ]; then \
        for patch in /workspace/patches/*.patch; do \
            if [ -f "$patch" ]; then \
                echo "Applying patch: $patch"; \
                git apply "$patch" || echo "Patch $patch failed, continuing..."; \
            fi; \
        done; \
    fi

# Pre-fetch dependencies to improve build times
RUN bazel fetch //source/exe:envoy-static --config=arm64 --config=envoy || true

# Health check to verify environment
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/cross-compile-test.sh

# Default command builds Envoy
CMD ["/usr/local/bin/build-envoy.sh"]

# Labels for container metadata
LABEL maintainer="goldentooth-cluster"
LABEL version="${ENVOY_VERSION}"
LABEL description="Cross-compilation environment for Envoy ARM64 builds"
LABEL org.opencontainers.image.source="https://github.com/goldentooth/cross-compile-toolkit"