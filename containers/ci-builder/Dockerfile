# Minimal CI builder for GitHub Actions
FROM goldentooth/base-builder:latest

# Install additional CI tools
USER root

RUN apt-get update && apt-get install -y \
    # Git for source control
    git \
    # Compression tools for artifacts
    tar \
    gzip \
    # JSON processing
    jq \
    # Additional testing tools
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create CI-specific scripts
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Switch back to builder user
USER builder

# Set minimal environment for CI
ENV CI=true
ENV DEBIAN_FRONTEND=noninteractive

# Working directory for CI builds
WORKDIR /workspace

CMD ["/bin/bash"]