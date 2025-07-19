# Goldentooth Cross-Compilation Toolkit

A comprehensive containerized build system for cross-compiling ARM64 binaries for the Goldentooth Raspberry Pi cluster. This toolkit addresses memory alignment issues and provides reproducible build environments for complex software like Envoy proxy.

## 🎯 Purpose

- **Cross-compile Envoy** with ARM64 compatibility and tcmalloc fixes
- **Containerized builds** for reproducibility and isolation
- **Multi-architecture support** for various cluster software
- **CI/CD integration** with GitHub Actions
- **Scalable architecture** for future cross-compilation needs

## 🏗️ Architecture

```
cross-compile-toolkit/
├── containers/          # Docker build environments
│   ├── base-builder/   # Common ARM64 cross-compilation base
│   ├── envoy/          # Envoy-specific build container
│   └── ci-builder/     # GitHub Actions runner
├── packer/             # VM images for complex builds
├── ansible/            # Deployment orchestration
├── .github/workflows/  # Automated builds and testing
└── artifacts/          # Build outputs
```

## 🚀 Quick Start

### Build Envoy for ARM64

```bash
# Clone the repository
git clone https://github.com/goldentooth/cross-compile-toolkit.git
cd cross-compile-toolkit

# Build the Envoy container
docker build -t goldentooth/envoy-builder containers/envoy/

# Cross-compile Envoy with Pi-compatible settings
docker run --rm -v $PWD/artifacts:/artifacts goldentooth/envoy-builder

# Deploy to cluster
ansible-playbook ansible/playbooks/deploy-envoy.yml
```

### Available Builders

| Container | Purpose | Status |
|-----------|---------|--------|
| `base-builder` | Common cross-compilation tools | ✅ Ready |
| `envoy-builder` | Envoy proxy with tcmalloc fixes | ✅ Ready |
| `consul-builder` | Consul with ARM64 optimizations | 🚧 Planned |
| `vault-builder` | HashiCorp Vault cross-compilation | 🚧 Planned |

## 🔧 Technical Solutions

### Envoy Memory Alignment Fix

The toolkit addresses [Envoy issue #23339](https://github.com/envoyproxy/envoy/issues/23339) with multiple approaches:

1. **Disabled tcmalloc**: `--define tcmalloc=disabled` for Raspberry Pi compatibility
2. **Alternative allocators**: gperftools and jemalloc options
3. **Kernel compatibility**: Works with standard Raspberry Pi OS (39-bit VA)

### Build Optimization

- **Multi-stage builds** for minimal container size
- **Build caching** for faster incremental builds  
- **Parallel compilation** optimized for CI/CD resources
- **ARM64 emulation** via QEMU for testing

## 📦 Container Images

Pre-built images are available on GitHub Container Registry:

```bash
docker pull ghcr.io/goldentooth/base-builder:latest
docker pull ghcr.io/goldentooth/envoy-builder:latest
```

## 🛠️ Development

### Adding New Build Targets

1. Create container directory: `containers/my-software/`
2. Add Dockerfile with cross-compilation setup
3. Include build script and patches
4. Add GitHub Actions workflow
5. Update documentation

### Local Development

```bash
# Build development environment
docker-compose up dev-environment

# Test cross-compilation
make test-cross-compile

# Build all containers
make build-all
```

## 🤖 CI/CD Integration

Automated builds trigger on:
- **Push to main**: Build and test all containers
- **Pull requests**: Build and test changed containers
- **Weekly schedule**: Rebuild with latest dependencies
- **Manual triggers**: On-demand builds with custom parameters

## 📋 Requirements

### Host System
- Docker Engine 20.10+ with buildx support
- 16GB+ RAM for Envoy builds
- 100GB+ storage for build cache
- Internet connectivity for dependencies

### Target Deployment
- Raspberry Pi 4B with 4GB+ RAM
- Raspberry Pi OS (64-bit) or Ubuntu 22.04 ARM64
- Kubernetes cluster or Docker runtime

## 🔒 Security

- **Minimal containers** with only required dependencies
- **Non-root execution** where possible
- **Signed container images** with cosign
- **Vulnerability scanning** in CI pipeline
- **SBOM generation** for supply chain security

## 📚 Documentation

- [Container Build Guide](docs/container-builds.md)
- [Envoy Configuration](docs/envoy-setup.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Contributing](docs/contributing.md)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add/modify containers or scripts
4. Test cross-compilation locally
5. Submit pull request with tests

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Envoy Proxy](https://www.envoyproxy.io/) community for ARM64 support
- [Bazel](https://bazel.build/) team for cross-compilation improvements
- Raspberry Pi community for kernel compatibility insights

---

**Built with ❤️ for the Goldentooth cluster**