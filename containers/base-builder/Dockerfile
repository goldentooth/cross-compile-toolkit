# Goldentooth Base Cross-Compilation Container
# Provides common ARM64 cross-compilation tools and environment

FROM ubuntu:22.04 as base

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    curl \
    wget \
    git \
    unzip \
    zip \
    pkg-config \
    \
    # Python for build scripts
    python3 \
    python3-pip \
    python3-dev \
    \
    # Java for Bazel
    openjdk-11-jdk \
    \
    # Cross-compilation toolchain
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    libc6-dev-arm64-cross \
    linux-libc-dev-arm64-cross \
    binutils-aarch64-linux-gnu \
    \
    # Additional ARM64 libraries
    libc6-dev:arm64 \
    libssl-dev:arm64 \
    zlib1g-dev:arm64 \
    \
    # Alternative memory allocators
    libgoogle-perftools-dev \
    libgoogle-perftools-dev:arm64 \
    libjemalloc-dev \
    libjemalloc-dev:arm64 \
    \
    # LLVM/Clang modern toolchain
    clang-18 \
    llvm-18 \
    lld-18 \
    \
    # Build tools
    cmake \
    ninja-build \
    \
    && rm -rf /var/lib/apt/lists/*

# Add ARM64 architecture support
RUN dpkg --add-architecture arm64

# Set up environment variables for cross-compilation
ENV CROSS_COMPILE=aarch64-linux-gnu-
ENV CC=aarch64-linux-gnu-gcc
ENV CXX=aarch64-linux-gnu-g++
ENV AR=aarch64-linux-gnu-ar
ENV STRIP=aarch64-linux-gnu-strip
ENV SYSROOT=/usr/aarch64-linux-gnu
ENV PKG_CONFIG_PATH=/usr/aarch64-linux-gnu/lib/pkgconfig
ENV PKG_CONFIG_LIBDIR=/usr/aarch64-linux-gnu/lib/pkgconfig

# Install Bazel (latest stable version)
ARG BAZEL_VERSION=7.0.0
RUN wget -O bazel-installer.sh \
    "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh" && \
    chmod +x bazel-installer.sh && \
    ./bazel-installer.sh && \
    rm bazel-installer.sh

# Create build user (non-root for security)
RUN useradd -m -s /bin/bash builder && \
    mkdir -p /workspace /artifacts && \
    chown -R builder:builder /workspace /artifacts

# Create cross-compilation helper scripts
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Create Bazel configuration for ARM64 cross-compilation
RUN mkdir -p /home/builder/.bazel && \
    chown -R builder:builder /home/builder/.bazel

COPY bazelrc /home/builder/.bazelrc
RUN chown builder:builder /home/builder/.bazelrc

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER builder

# Test cross-compilation setup
RUN echo '#include <stdio.h>\nint main(){printf("ARM64 ready\\n");return 0;}' > test.c && \
    aarch64-linux-gnu-gcc -o test test.c && \
    file test | grep -q "ARM aarch64" && \
    rm test test.c

CMD ["/bin/bash"]