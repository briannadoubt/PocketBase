# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build all targets
swift build

# Run unit tests only (excludes integration tests)
swift test --filter PocketBaseTests

# Run all tests including integration (requires macOS 26+ and container setup)
swift test

# Run a specific test
swift test --filter PocketBaseTests.testSpecificFunction

# Build and run PocketBaseServer with entitlements (macOS 26+)
make run

# Build PocketBaseServer only
make server

# Clean build artifacts
make clean
```

## Development Environment

Two options for running PocketBase locally:

1. **Docker**: `docker compose up` - starts PocketBase at localhost:8090
2. **Native Containerization (macOS 26+)**: `make run` - uses Apple's Containerization framework

For native containerization, first run `container system start` and ensure the vmlinux kernel symlink exists (created automatically by `make setup`).

## Architecture Overview

### Core Libraries

- **PocketBase** (`Sources/PocketBase/`) - Core client library. Contains networking, auth, records, and macro definitions.
- **PocketBaseUI** (`Sources/PocketBaseUI/`) - SwiftUI components including `@StaticQuery`, `@RealtimeQuery` property wrappers and authentication views.
- **PocketBaseMacros** (`Sources/PocketBaseMacros/`) - Swift macro implementations using SwiftSyntax.

### Macros

The library uses Swift macros extensively. Key macros and their implementations:

| Macro | Purpose | Implementation |
|-------|---------|----------------|
| `@AuthCollection("name")` | Auth collection model with email/username/verified fields | `RecordCollectionMacro.swift` |
| `@BaseCollection("name")` | Base collection model with id/created/updated | `RecordCollectionMacro.swift` |
| `@File` | File field with URL hydration | `File.swift` |
| `@Relation` | Forward relation to another collection | `Relation.swift` |
| `@BackRelation` | Back-relation from another collection | `Relation.swift` |
| `#Filter` | Type-safe filter expression builder | `Filter.swift` |

Macros generate: Codable conformance, memberwise initializers, CodingKeys, and protocol conformances (`Record`, `AuthRecord`).

### Containerization (macOS 26+)

- **PocketBaseServerLib** (`Sources/PocketBaseServerLib/`) - Container management using Apple's Containerization framework
- **PocketBaseServer** (`Sources/PocketBaseServer/`) - CLI executable to run PocketBase in a container

All containerization code requires `@available(macOS 26.0, *)` annotations.

### Key Protocols

- `Record` - Base protocol for all collection records (requires `id`, `collectionId`, `collectionName`, `created`, `updated`)
- `AuthRecord` - Extends Record for auth collections (adds `username`, `email`, `verified`, `emailVisibility`)

### Networking

`RecordCollection<T>` handles all CRUD operations. File uploads auto-detect when to use multipart encoding based on `FileValue.pending` fields.

## Testing

- **PocketBaseTests** - Unit tests (no server required)
- **PocketBaseMacrosTests** - Macro expansion tests using SwiftSyntaxMacrosTestSupport
- **PocketBaseIntegrationTests** - Requires running PocketBase server; skips gracefully if unavailable

Integration tests use `PocketBaseServerLauncher` to manage a shared container instance.
