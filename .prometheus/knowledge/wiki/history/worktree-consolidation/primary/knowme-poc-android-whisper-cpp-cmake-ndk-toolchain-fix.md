<!-- source=primary; branch=main-pre-consolidation; original_sha256=2f33044cf927b94ab11fe2c7870f56df3f3837690b281bd937b7a9224bcdb190 -->
---
type: Reference
id: knowme-poc-android-whisper-cpp-cmake-ndk-toolchain-fix
title: KnowMe PoC Android whisper.cpp CMake NDK toolchain fix
tags:
- hybrid-mobile-architecture
- knowme-poc
- flutter
- android
- cargokit
- cmake
- whisper-rs
- ndk
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-flutter-android-device-launch-in-progress
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T12:57:33.611511+00:00
created_at: 2026-07-16T12:57:33.611511+00:00
updated_at: 2026-07-16T12:57:33.611511+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T12:56:48Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This execution tick continues the PoC-first scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Android device launch attempt captured in [KnowMe PoC Flutter Android device launch in progress](/knowme-poc-flutter-android-device-launch-in-progress.md). It is part of proving the KnowMe PoC across Flutter Android and Tauri desktop surfaces.

## Phase goal

The phase deliverable is a working proof-of-concept app in `apps/<name>/`, not just codegen or CI pipeline verification.

The PoC should demonstrate, where practical:

- Streaming `ContentBlock` chat.
- PEM entity management.
- SurrealDB graph-RAG memory.
- Local-first sync.
- Cross-platform Flutter, Tauri, and web delivery from one Rust core.

Supporting verification objectives remain:

- Run the real codegen pipeline:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
- Resolve or work around the PEM install blocker involving `@prometheus-ags/entity-graph-core@workspace:*` outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop.
  - iOS simulator or Android emulator/device for Flutter.
- Wire CI to run:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC on every push.

## Android build failure

The third Android build failure came from `whisper-rs-sys`, specifically the vendored `whisper.cpp` CMake build used for on-device transcription.

Failure mode:

- The `whisper.cpp` CMake configure/build step could not find the Android NDK toolchain.
- `cargokit` configured plain C/C++ compiler environment variables such as `cc`/`clang`.
- `cargokit` did **not** provide the CMake-specific Android toolchain configuration needed by `cmake-rs` for cross-compiled targets.

## Patch applied

Patched:

```text
apps/knowme-poc/mobile/rust_builder/cargokit/build_tool/lib/src/android_environment.dart
```

The patch exports additional environment variables for Android cross-compilation:

```text
TARGET_CMAKE_TOOLCHAIN_FILE=<android-ndk>/build/cmake/android.toolchain.cmake
TARGET_CMAKE_GENERATOR=Ninja
```

Rationale:

- `TARGET_CMAKE_TOOLCHAIN_FILE` points CMake at the Android NDK toolchain file.
- `TARGET_CMAKE_GENERATOR=Ninja` avoids the unavailable default generator, because `Unix Makefiles` is not installed in this environment.
- `cmake-rs` reads these target-prefixed variables for cross-compiled targets only, making the patch scoped to Android cross-builds rather than host builds.

## Current state

- The Flutter Android build has been retried after the cargokit/CMake environment patch.
- The monitor is waiting for the rebuild to pass the `whisper.cpp` CMake configure/build step.
- If successful, the next steps are APK install and launch on device `SM S936U`.
- If another issue appears, the next report should diagnose the new failure.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification