# Multi-stage build for distributed-llama cross-compilation
FROM ghcr.io/goldentooth/base-builder:latest AS builder

# Set build arguments
ARG DISTRIBUTED_LLAMA_VERSION=main
ARG TARGET_ARCH=aarch64-linux-gnu

# Install additional dependencies for distributed-llama build
USER root
RUN apt-get update && apt-get install -y \
    python3-dev \
    python3-pip \
    libopenblas-dev:arm64 \
    && rm -rf /var/lib/apt/lists/*

# Switch back to build user
USER builder
WORKDIR /workspace

# Clone distributed-llama repository
RUN git clone --branch ${DISTRIBUTED_LLAMA_VERSION} \
    https://github.com/b4rtaz/distributed-llama.git \
    distributed-llama

WORKDIR /workspace/distributed-llama

# Set up cross-compilation environment
ENV CC=aarch64-linux-gnu-gcc
ENV CXX=aarch64-linux-gnu-g++
ENV AR=aarch64-linux-gnu-ar
ENV STRIP=aarch64-linux-gnu-strip

# Configure for ARM64 build
ENV CFLAGS="-march=armv8-a -mtune=cortex-a72"
ENV CXXFLAGS="-march=armv8-a -mtune=cortex-a72"

# Build distributed-llama binaries
RUN make dllama CC=${CC} CXX=${CXX}
RUN make dllama-api CC=${CC} CXX=${CXX}

# Create artifacts directory and copy binaries
RUN mkdir -p /artifacts/distributed-llama
RUN cp dllama /artifacts/distributed-llama/dllama-arm64
RUN cp dllama-api /artifacts/distributed-llama/dllama-api-arm64

# Strip binaries to reduce size
RUN ${STRIP} /artifacts/distributed-llama/dllama-arm64
RUN ${STRIP} /artifacts/distributed-llama/dllama-api-arm64

# Create build metadata
RUN echo "Build Date: $(date -Iseconds)" > /artifacts/distributed-llama/build-info.txt
RUN echo "Version: ${DISTRIBUTED_LLAMA_VERSION}" >> /artifacts/distributed-llama/build-info.txt
RUN echo "Target: ${TARGET_ARCH}" >> /artifacts/distributed-llama/build-info.txt
RUN echo "Compiler: $(${CXX} --version | head -1)" >> /artifacts/distributed-llama/build-info.txt

# Final stage - minimal runtime for binary validation
FROM arm64v8/ubuntu:22.04 AS validator

# Copy binaries for validation
COPY --from=builder /artifacts/distributed-llama/dllama-arm64 /usr/local/bin/dllama
COPY --from=builder /artifacts/distributed-llama/dllama-api-arm64 /usr/local/bin/dllama-api

# Test binaries work (basic validation)
RUN /usr/local/bin/dllama --help || true
RUN /usr/local/bin/dllama-api --help || true

# Main build stage
FROM builder AS final

# Set entrypoint for automated builds
COPY build-distributed-llama.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/build-distributed-llama.sh

ENTRYPOINT ["/usr/local/bin/build-distributed-llama.sh"]