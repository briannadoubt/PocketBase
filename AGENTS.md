# AGENTS.md

Guidance for Codex when working in this repository.

## Mission

- Keep changes minimal, safe, and aligned with the current architecture.
- Prefer targeted edits over broad refactors unless explicitly requested.
- Validate changes with the smallest meaningful test/build command before finishing.

## Repo Snapshot (Current)

- Package manager: SwiftPM (`swift-tools-version: 6.2`)
- Primary modules:
  - `Sources/PocketBase` (core client)
  - `Sources/PocketBaseAdmin` (admin API)
  - `Sources/PocketBaseUI` (SwiftUI helpers)
  - `Sources/PocketBaseMacros` (macro implementations)
  - `Sources/PocketBaseServerLib` (container runtime integration)
  - `Sources/PocketBaseServer` (CLI executable)
- Test targets:
  - `PocketBaseTests`
  - `PocketBaseAdminTests`
  - `PocketBaseMacrosTests`
  - `PocketBaseIntegrationTests`

## Preferred Workflow for Codex

1. Read only the files needed for the task.
2. Implement focused edits.
3. Run targeted validation first, then broader validation if needed.
4. Summarize what changed, what was run, and any gaps.

## Build and Test Commands

### Fast local checks

```bash
swift build
swift test --filter PocketBaseTests
swift test --filter PocketBaseAdminTests
swift test --filter PocketBaseMacrosTests
```

### Integration tests

```bash
swift test --filter PocketBaseIntegrationTests
```

Notes:
- Integration tests depend on local runtime/container setup and may be skipped in environments without required tooling.

### Makefile helpers

```bash
make build        # swift build
make server       # build + sign PocketBaseServer
make run          # build/sign/run server (depends on setup)
make setup        # ensures vmlinux symlink exists
make clean        # clean build artifacts
make test         # swift test
```

## Local Runtime Options

- Docker: `docker compose up`
- Native containerization path: `make run`

If using native containerization, start container services first:

```bash
container system start
```

## Architecture Notes

### Core protocols

- `Record`: base collection record protocol
- `AuthRecord`: auth-specific extension of `Record`

### Macro surface (high impact)

- `@AuthCollection`, `@BaseCollection`, `@File`, `@Relation`, `@BackRelation`, `#Filter`
- Macro changes can cascade into multiple modules and tests; run macro tests when touching macro behavior.

### Networking and records

- `RecordCollection<T>` is central for CRUD behavior.
- File upload behavior is tied to `FileValue.pending` and multipart handling.

## Change Guardrails

- Do not change public API names/signatures unless requested.
- Preserve platform availability expectations (notably containerization-related code paths).
- Avoid unrelated style-only churn.
- When modifying tests, keep them behavior-focused and consistent with existing patterns.

## Validation Expectations

- For core/client changes: run `PocketBaseTests`.
- For admin changes: run `PocketBaseAdminTests`.
- For macro changes: run `PocketBaseMacrosTests`.
- For container/server/runtime behavior: run integration tests when environment permits.

If validation cannot run, state exactly what was not run and why.

## PR/Commit Readiness Checklist

- Code builds (`swift build`) or explain why not.
- Relevant target tests pass (or clearly documented constraints).
- No accidental edits to unrelated files.
- User-facing behavior/API changes are called out explicitly.
