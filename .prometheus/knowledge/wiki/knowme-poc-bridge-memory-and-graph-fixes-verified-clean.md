---
type: Reference
id: knowme-poc-bridge-memory-and-graph-fixes-verified-clean
title: KnowMe PoC bridge, memory, and graph fixes verified clean
tags:
- hybrid-mobile-architecture
- knowme-poc
- flutter-rust-bridge
- surrealdb
- graph-rag
- tauri
- flutter
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-flutter-android-device-launch-in-progress
- knowme-poc-tauri-launch-wait-loop-pending-interactive-verification
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T13:51:14.053863+00:00
created_at: 2026-07-16T13:51:14.053863+00:00
updated_at: 2026-07-16T13:51:14.053863+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T13:49:26Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This execution tick continues the PoC-first scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md), with prior adjacent work including [KnowMe PoC Flutter Android device launch in progress](/knowme-poc-flutter-android-device-launch-in-progress.md) and Tauri wait-loop verification in [KnowMe PoC Tauri launch wait-loop pending interactive verification](/knowme-poc-tauri-launch-wait-loop-pending-interactive-verification.md).

## Phase goal reminder

The revised phase deliverable is a working proof-of-concept app, not only codegen or CI verification. The PoC must demonstrate the skill package end-to-end, including:

- Streaming `ContentBlock` chat.
- PEM entity management.
- SurrealDB graph-RAG memory.
- Local-first sync.
- Cross-platform Flutter, Tauri, and web from one Rust core.

Supporting objectives remain:

- Run real codegen and dependency installation workflows:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
- Resolve or work around the PEM install blocker for `@prometheus-ags/entity-graph-core@workspace:*` outside the PEM monorepo.
- Verify at least one real target per surface:
  - macOS Tauri desktop.
  - iOS simulator or Android emulator/device for Flutter.
- Wire CI for:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC on every push.

## Implementation progress

### Flutter Rust Bridge root-cause fix

The true cause of the non-functional mobile bridge was identified as a Flutter Rust Bridge limitation with `Result` type aliases.

- Problematic signatures used `CoreResult<T>`.
- FRB did not handle the alias correctly.
- All FFI-exposed signatures were rewritten to literal `Result<T, CoreError>`.

This fixed the core bridge issue for mobile.

### Missing mobile FFI functions added

Mobile lacked several functions needed for database and sync setup. Added FFI functions:

- `run_migrations`
- `load_seeds`
- `attach_sync_shapes`

### Shared memory module wired

A shared `gen_ui_agent::memory` module now supports memory operations used by both mobile and desktop:

- `memory_ingest`
- `memory_search`
- `graph_expand`

### Desktop graph store fixed

Desktop previously had no `GraphStore` instance. It now has its own `GraphStore`, enabling graph-backed memory functionality on the Tauri surface.

### SurrealDB schema bugs fixed

Two real SurrealDB schema issues were found and corrected:

- `FLEXIBLE` requires `SCHEMAFULL`.
- `FLEXIBLE` is invalid with `SCHEMALESS`.

The fix was verified through a passing live Ollama round-trip test.

### Dart bridge provider convergence

A concurrent process independently converged on the same `rust_bridge_provider.dart` wiring, using a cleaner JSON-stream approach for still-opaque enum types.

One remaining error from that work was fixed:

- A stale test referenced old `MemoryHit` field names.
- The test was updated to the current field names.

## Verification status

The following checks are clean:

- `cargo clippy --workspace`
- `flutter analyze`
- `tsc --noEmit`

The session notes also report that `flutter analyze` and `cargo clippy --workspace` were already clean, making the corresponding file verified working.

## Pending work

- Await the `gen_ui_db_graph` test suite result.
  - It is currently running with `embed-native`.
- After the test result:
  - Commit the completed bridge, memory, graph, schema, and provider work.
  - Push the branch.
- Then decide whether to continue into remaining C-104 scope or stop at the current milestone.

Potential remaining C-104 work:

- Seed corpus.
- Memory tile UI.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification