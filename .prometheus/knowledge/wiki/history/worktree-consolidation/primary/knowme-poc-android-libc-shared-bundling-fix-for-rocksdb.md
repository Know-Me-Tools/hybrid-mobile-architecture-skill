<!-- source=primary; branch=main-pre-consolidation; original_sha256=2ff4ba91ad237c7eb10cc30fc2f5c13458c14106bfd81e1c9f5403c8bb19c5ea -->
---
type: Reference
id: knowme-poc-android-libc-shared-bundling-fix-for-rocksdb
title: KnowMe PoC Android libc++ shared bundling fix for RocksDB
tags:
- hybrid-mobile-architecture
- knowme-poc
- android
- rust-ffi
- rocksdb
- cxx-runtime
- flutter
- codegen
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T15:24:14.259787+00:00
created_at: 2026-07-16T15:24:14.259787+00:00
updated_at: 2026-07-16T15:24:14.259787+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T15:23:26Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This execution tick continues the PoC-first scope in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md), where the phase deliverable is a working KnowMe proof-of-concept app rather than pipeline verification alone.

## Phase goal recap

### Primary deliverable

Build a proof-of-concept app in `apps/<name>/` using repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`.

The PoC must prove the skill package end-to-end and showcase supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web UI from one Rust core
- Feature subset informed by showcase-app best practices and 2026 on-device AI feasibility

### Supporting verification goals

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - full `flutter pub get`
  - full `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator/device for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - boundary test suites against the PoC

## Android native linking decision

The previous static-linking attempt was reverted.

### Problem

RocksDB's `build.rs` has a bug where it emits the C++ standard library link directive literally as:

```text
dylib=$CXXSTDLIB
```

When attempting to use `c++_static`, this produced a broken Android link with nonsensical mixed-runtime behavior and missing symbols.

### Decision

Patch cargokit's `build_gradle.dart` so the Android build bundles the NDK's real shared C++ runtime into `jniLibs` alongside the Rust FFI library:

```text
jniLibs/
  libc++_shared.so
  libgen_ui_ffi.so
```

### Rationale

Bundling `libc++_shared.so` is the standard approach for Android Rust projects that include C++-heavy native dependencies such as RocksDB. It avoids the broken static-link path and ensures the app ships the runtime expected by native libraries.

## Current state

- Static C++ runtime linking has been abandoned.
- `build_gradle.dart` has been patched to copy the NDK `libc++_shared.so` into Android `jniLibs` with `libgen_ui_ffi.so`.
- Rebuild is in progress.
- Rust artifacts are cached; only the `jniLibs` bundling step is expected to be new.
- Next verification target: install and launch the app on Samsung SM-S936U and confirm it no longer crashes at startup.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification