<!-- source=compassionate-babbage-7cd4bc; branch=claude/compassionate-babbage-7cd4bc; original_sha256=7c8026676e51c9948ea2c97a14594cd2af2a87d85ca1854c9d3918ba90a9f149 -->
---
type: Reference
id: android-whisper-rs-cmake-abi-fix-for-knowme-poc-launch
title: Android whisper-rs CMake ABI fix for KnowMe PoC launch
tags:
- hybrid-mobile-architecture
- knowme-poc
- android
- cmake
- whisper-rs
- flutter
- cross-compile
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-flutter-android-device-launch-in-progress
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T13:54:52.325110+00:00
created_at: 2026-07-16T13:54:52.325110+00:00
updated_at: 2026-07-16T13:54:52.325110+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-16T13:54:01Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This continues the PoC-first execution scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Android device launch work in [KnowMe PoC Flutter Android device launch in progress](/knowme-poc-flutter-android-device-launch-in-progress.md).

## Phase goal

The phase deliverable is a working proof-of-concept app in `apps/<name>/`, not just codegen or CI verification. The PoC is based on KnowMe reference documentation in `docs/reference-app/` and should demonstrate the broadest practical range of supported hybrid-mobile capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web from one Rust core

Supporting objectives remain:

- Run real codegen against the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` being unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator/device for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - boundary test suites against the PoC

## Android cross-compile issue found

The prior Android build attempt set `TARGET_ANDROID_ABI`, but that environment variable was never consumed by the build chain.

Root cause:

- `cmake-rs` does **not** automatically forward arbitrary `TARGET_`-prefixed environment variables as CMake `-D` flags.
- `whisper-rs-sys`'s `build.rs` contains no Android-specific CMake configuration that would read `TARGET_ANDROID_ABI`.
- Therefore the Android ABI was not reaching `whisper.cpp`'s CMake/NDK toolchain configuration.

## Correct fix

Use the CMake-prefixed environment variable that `cmake-rs` forwards verbatim:

```sh
CMAKE_ANDROID_ARCH_ABI=<abi>
```

Rationale:

- `cmake-rs` forwards environment variables beginning with `CMAKE_` as CMake `-D` definitions.
- `CMAKE_ANDROID_ARCH_ABI` is the exact variable inspected by the Android NDK CMake toolchain file.
- This mechanism should propagate the ABI into `whisper.cpp`'s CMake configure step.

The stale build directory was cleared before retrying to avoid cached CMake configuration masking the fix.

## Current execution state

- Retrying the Android build with `CMAKE_ANDROID_ARCH_ABI` instead of `TARGET_ANDROID_ABI`.
- Monitoring for `whisper.cpp` CMake configure to confirm the ABI reaches the NDK toolchain file.
- If configure succeeds, remaining work is:
  1. Finish the Rust/RocksDB cross-compile.
  2. Install the Flutter app.
  3. Launch on the Android device `SM S936U`.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification