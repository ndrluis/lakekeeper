# Makefile for building iceberg-catalog for ARM64 on M1 Mac
.PHONY: all build-binary extract-binary build-docker clean

# Variables
ARCH := arm64
TARGET := aarch64-unknown-linux-musl
BINARY_NAME := iceberg-catalog
DOCKER_TAG := iceberg-catalog:arm64
BUILD_TAG := iceberg-catalog-build:arm64

all: build-binary extract-binary build-docker

# Build the binary using the existing full.Dockerfile
build-binary:
	@echo "Building binary for $(ARCH)..."
	@docker build \
		--platform linux/arm64 \
		--target builder \
		-t $(BUILD_TAG) \
		--build-arg NO_CHEF=true \
		-f docker/full.Dockerfile .

# Extract the binary from the build container
extract-binary:
	@echo "Extracting binary..."
	@mkdir -p target/release
	@docker create --name temp-container $(BUILD_TAG) /bin/sh
	@docker cp temp-container:/app/target/release/$(BINARY_NAME) target/release/
	@docker rm temp-container
	@echo "Binary extracted to target/release/$(BINARY_NAME)"
	@chmod +x target/release/$(BINARY_NAME)

# Build Docker image for ARM64 using the bin.Dockerfile
build-docker:
	@echo "Building Docker image for ARM64..."
	@docker build \
		--platform linux/arm64 \
		-t $(DOCKER_TAG) \
		-f docker/bin.Dockerfile \
		--build-arg "ARCH=$(ARCH)" \
		--build-arg "EXPIRES=4w" \
		--build-arg "BIN=target/release/$(BINARY_NAME)" \
		.
	@echo "Docker image built successfully: $(DOCKER_TAG)"
	@echo "You can push this image to your registry with:"
	@echo "  docker tag $(DOCKER_TAG) your-registry/$(DOCKER_TAG)"
	@echo "  docker push your-registry/$(DOCKER_TAG)"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf target/release/$(BINARY_NAME)
	@docker rmi $(BUILD_TAG) $(DOCKER_TAG) || true
