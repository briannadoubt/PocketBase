# PocketBase Swift Package Makefile

SWIFT = swift
CODESIGN = codesign
ENTITLEMENTS = Sources/PocketBaseServer/PocketBaseServer.entitlements

.PHONY: all build server run clean setup

all: build

# Build all targets
build:
	$(SWIFT) build

# Build and sign PocketBaseServer
server:
	$(SWIFT) build --product PocketBaseServer
	$(CODESIGN) --force --sign - --entitlements $(ENTITLEMENTS) .build/debug/PocketBaseServer

# Build, sign, and run PocketBaseServer
run: server setup
	.build/debug/PocketBaseServer --verbose

# Setup: ensure kernel symlink exists
setup:
	@if [ ! -L vmlinux ]; then \
		ln -sf "$(HOME)/Library/Application Support/com.apple.container/kernels/default.kernel-arm64" vmlinux; \
		echo "Created vmlinux symlink"; \
	fi

# Clean build artifacts
clean:
	$(SWIFT) package clean
	rm -rf .build

# Clean container state
clean-container:
	rm -rf "$(HOME)/Library/Application Support/com.apple.containerization/containers/pocketbase-server"

# Run tests
test:
	$(SWIFT) test
