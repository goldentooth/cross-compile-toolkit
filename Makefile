# Goldentooth Cross-Compilation Toolkit Makefile

.PHONY: help build test clean dev envoy-build envoy-test deploy

# Default target
help:
	@echo "Goldentooth Cross-Compilation Toolkit"
	@echo ""
	@echo "Available targets:"
	@echo "  help         - Show this help message"
	@echo "  build        - Build all containers"
	@echo "  test         - Test cross-compilation environment"
	@echo "  clean        - Clean up containers and artifacts"
	@echo "  dev          - Start development environment"
	@echo "  envoy-build  - Build Envoy ARM64 binary"
	@echo "  envoy-test   - Test Envoy binary on ARM64 emulation"
	@echo "  deploy       - Deploy artifacts to cluster"
	@echo ""
	@echo "Environment variables:"
	@echo "  ENVOY_VERSION      - Envoy version to build (default: v1.32.0)"
	@echo "  MEMORY_ALLOCATOR   - Memory allocator (default: disabled)"
	@echo "  BUILD_CONFIG       - Build configuration (default: release)"

# Configuration
ENVOY_VERSION ?= v1.32.0
MEMORY_ALLOCATOR ?= disabled
BUILD_CONFIG ?= release
PARALLEL_JOBS ?= 4

# Build all containers
build:
	@echo "🔨 Building cross-compilation containers..."
	docker compose build base-builder
	docker compose build envoy-builder

# Test cross-compilation environment
test:
	@echo "🧪 Testing cross-compilation environment..."
	docker compose run --rm base-builder /usr/local/bin/cross-compile-test.sh

# Clean up
clean:
	@echo "🧹 Cleaning up containers and artifacts..."
	docker compose down -v
	docker system prune -f
	rm -rf artifacts/*

# Start development environment
dev:
	@echo "🚀 Starting development environment..."
	docker compose --profile dev up -d dev-environment
	@echo "💡 Connect with: docker compose exec dev-environment /bin/bash"

# Build Envoy ARM64
envoy-build:
	@echo "🏗️  Building Envoy $(ENVOY_VERSION) for ARM64..."
	@echo "   Memory allocator: $(MEMORY_ALLOCATOR)"
	@echo "   Build config: $(BUILD_CONFIG)"
	docker compose --profile build run --rm \
		-e ENVOY_VERSION=$(ENVOY_VERSION) \
		-e MEMORY_ALLOCATOR=$(MEMORY_ALLOCATOR) \
		-e BUILD_CONFIG=$(BUILD_CONFIG) \
		-e PARALLEL_JOBS=$(PARALLEL_JOBS) \
		envoy-builder

# Test Envoy binary with ARM64 emulation
envoy-test:
	@echo "🔍 Testing Envoy binary on ARM64 emulation..."
	docker run --platform linux/arm64 --rm \
		-v $(PWD)/artifacts/envoy:/usr/local/bin \
		arm64v8/ubuntu:22.04 \
		/usr/local/bin/envoy-$(ENVOY_VERSION)-arm64 --version

# Quick build for development
quick-build:
	@echo "⚡ Quick build for development..."
	docker build -t goldentooth/base-builder:dev containers/base-builder/
	docker build -t goldentooth/envoy-builder:dev containers/envoy/

# Deploy artifacts (placeholder for Ansible integration)
deploy:
	@echo "📦 Deploying artifacts to cluster..."
	@if [ -f ../ansible/playbooks/deploy-cross-compiled.yml ]; then \
		cd .. && ansible-playbook ansible/playbooks/deploy-cross-compiled.yml; \
	else \
		echo "❌ Deployment playbook not found"; \
		echo "💡 Run this from the goldentooth main project directory"; \
	fi

# Show build status
status:
	@echo "📊 Build Status:"
	@echo "Containers:"
	@docker images | grep goldentooth || echo "  No goldentooth images found"
	@echo ""
	@echo "Artifacts:"
	@find artifacts/ -type f -exec ls -lh {} \; 2>/dev/null || echo "  No artifacts found"

# Development helpers
shell-base:
	@docker compose run --rm base-builder /bin/bash

shell-envoy:
	@docker compose run --rm envoy-builder /bin/bash

# CI targets
ci-build:
	@echo "🤖 CI Build"
	./containers/ci-builder/scripts/ci-build.sh build

ci-test:
	@echo "🤖 CI Test"
	./containers/ci-builder/scripts/ci-build.sh test