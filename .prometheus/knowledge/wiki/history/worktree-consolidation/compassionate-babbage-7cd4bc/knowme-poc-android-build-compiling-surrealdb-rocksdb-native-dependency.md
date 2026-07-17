<!-- source=compassionate-babbage-7cd4bc; branch=claude/compassionate-babbage-7cd4bc; original_sha256=da4d9ccdd7da067c1b732cbc2aa07e11b47a8bd72bfa7316011aa3a2f9ccd726 -->
---
type: Reference
id: knowme-poc-android-build-compiling-surrealdb-rocksdb-native-dependency
title: KnowMe PoC Android build compiling SurrealDB RocksDB native dependency
tags:
- hybrid-mobile-architecture
- knowme-poc
- flutter
- android
- surrealdb
- rocksdb
- native-build
- codegen
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-flutter-android-device-launch-in-progress
- knowme-poc-tauri-launch-wait-loop-pending-interactive-verification
- knowme-poc-tauri-dev-build-wait-loop-handoff
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T13:54:19.051025+00:00
created_at: 2026-07-16T13:54:19.051025+00:00
updated_at: 2026-07-16T13:54:19.051025+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-16T13:50:53Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This execution tick continues the PoC-first phase scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Android launch attempt tracked in [KnowMe PoC Flutter Android device launch in progress](/knowme-poc-flutter-android-device-launch-in-progress.md). It is adjacent to prior Tauri verification and wait-loop work in [KnowMe PoC Tauri launch wait-loop pending interactive verification](/knowme-poc-tauri-launch-wait-loop-pending-interactive-verification.md) and [KnowMe PoC Tauri dev build wait-loop handoff](/knowme-poc-tauri-dev-build-wait-loop-handoff.md).

## Phase goal

The phase deliverable is a working proof-of-concept app in `apps/<name>/`, not just pipeline verification.

### Primary objective

Build a KnowMe-inspired PoC from the reference documentation in `docs/reference-app/` that proves the skill package end-to-end and showcases the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web delivery from one Rust core
- Feature subset informed by showcase-app best practices and 2026 on-device AI feasibility research

### Supporting objectives proven through the PoC

- Run the real codegen pipeline:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` being unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator/device for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Current build state

- There is **no failure recorded** in this tick.
- The Android build is actively compiling `surrealdb-librocksdb-sys` for `aarch64-linux-android`.
- This dependency builds RocksDB, a large C++ codebase with hundreds of `.cc` files.
- The long runtime is expected: RocksDB is CPU-heavy and currently running many parallel `clang++` processes.
- This appears to be the first Android cross-compile path for RocksDB after the prior `whisper.cpp` fix unblocked the CMake toolchain path.
- The build is not stuck; continue monitoring until it finishes, installs, and launches on the target device.

## Next action

Continue waiting on the build monitor for the RocksDB native compilation to complete, then verify install and launch on `SM S936U`.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification