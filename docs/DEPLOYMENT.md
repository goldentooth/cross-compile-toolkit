# Deployment Guide

This guide covers deploying the Goldentooth cross-compilation toolkit to your cluster.

## Prerequisites

- Velaryon node (x86_64) with Docker installed
- Ansible access to the cluster
- Internet connectivity for container image pulls

## Quick Deployment

### 1. Deploy to Velaryon

From the main goldentooth project directory:

```bash
# Deploy cross-compilation environment
goldentooth setup_cross_compilation

# Or manually with Ansible
ansible-playbook ansible/playbooks/setup_cross_compilation.yaml
```

### 2. Verify Installation

```bash
# Check status
goldentooth command velaryon 'goldentooth-build status'

# Test environment
goldentooth command velaryon 'goldentooth-build test-env'
```

### 3. Build Envoy for ARM64

```bash
# Build Envoy with Raspberry Pi compatibility
goldentooth command velaryon 'goldentooth-build build-envoy'

# Check artifacts
goldentooth command velaryon 'ls -la /opt/goldentooth/artifacts/envoy/'
```

## Manual Container Operations

### Building Containers Locally

```bash
cd cross-compile-toolkit

# Build all containers
make build

# Build specific container
docker build -t goldentooth/envoy-builder containers/envoy/

# Test cross-compilation
make test
```

### Running Individual Builds

```bash
# Interactive development environment
make dev

# Build Envoy with custom settings
docker run --rm \
  -v /opt/goldentooth/artifacts:/artifacts \
  -e ENVOY_VERSION=v1.32.0 \
  -e MEMORY_ALLOCATOR=disabled \
  -e BUILD_CONFIG=release \
  ghcr.io/goldentooth/envoy-builder:latest
```

## Configuration Options

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENVOY_VERSION` | `v1.32.0` | Envoy version to build |
| `MEMORY_ALLOCATOR` | `disabled` | Memory allocator (disabled/gperftools/jemalloc) |
| `BUILD_CONFIG` | `release` | Build configuration (release/debug) |
| `PARALLEL_JOBS` | `auto` | Number of parallel build jobs |
| `CREATE_DEB` | `true` | Create Debian package |

### Ansible Variables

```yaml
# In group_vars or host_vars
envoy_build:
  version: "v1.30.0"
  memory_allocator: "gperftools"
  parallel_jobs: 6

build_automation:
  auto_pull_images: false
  cleanup_old_artifacts: false
```

## Troubleshooting

### Container Issues

```bash
# Check container logs
docker logs goldentooth-envoy-builder

# Restart containers
cd /opt/goldentooth/workspace/cross-compile-toolkit
docker compose restart

# Rebuild with latest code
git pull origin main
docker compose build --no-cache
```

### Build Failures

```bash
# Check disk space
df -h /opt/goldentooth

# Increase memory limit
docker compose -f docker-compose.yml -f docker-compose.override.yml \
  run --rm -e PARALLEL_JOBS=2 envoy-builder

# Debug build environment
docker run -it --rm ghcr.io/goldentooth/base-builder:latest /bin/bash
```

### Network Issues

```bash
# Test registry connectivity
docker pull ghcr.io/goldentooth/base-builder:latest

# Check GitHub Actions status
# Visit: https://github.com/goldentooth/cross-compile-toolkit/actions
```

## Integration with Existing Services

### Updating Envoy Role

The existing `goldentooth.setup_envoy` role can be updated to use cross-compiled binaries:

```yaml
# In setup_envoy role
- name: "Copy cross-compiled Envoy binary"
  ansible.builtin.copy:
    src: "/opt/goldentooth/artifacts/envoy/envoy-{{ envoy_version }}-arm64"
    dest: "/usr/local/bin/envoy"
    mode: '0755'
    remote_src: yes
  delegate_to: velaryon
```

### Automated Builds

Set up scheduled builds for latest Envoy versions:

```bash
# Add to crontab on Velaryon
0 2 * * 0 /usr/local/bin/goldentooth-build update && /usr/local/bin/goldentooth-build build-envoy
```

## Monitoring and Maintenance

### Health Checks

```bash
# System health
goldentooth-build status

# Container health
docker compose ps

# Artifact inventory
/opt/goldentooth/workspace/artifact-inventory.sh
```

### Updates

```bash
# Update toolkit and containers
goldentooth-build update

# Manual container updates
docker compose pull
docker compose up -d
```

### Cleanup

```bash
# Clean old artifacts
goldentooth-build clean

# Remove all containers and start fresh
docker compose down -v
docker system prune -f
ansible-playbook ansible/playbooks/setup_cross_compilation.yaml
```