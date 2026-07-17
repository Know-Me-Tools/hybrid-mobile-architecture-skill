---
type: Reference
id: knowme-poc-android-build-fix-for-i686-onnx-runtime-target
title: KnowMe PoC Android build fix for i686 ONNX Runtime target
tags:
- hybrid-mobile-architecture
- knowme-poc
- flutter
- android
- onnx-runtime
- fastembed
- cargokit
- abi-filters
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-flutter-android-device-launch-in-progress
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T14:48:03.075973+00:00
created_at: 2026-07-16T14:48:03.075973+00:00
updated_at: 2026-07-16T14:48:03.075973+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T14:47:15Z`
- **Status:** `executing`

This execution tick continues the PoC-first phase scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Android device launch work in [KnowMe PoC Flutter Android device launch in progress](/knowme-poc-flutter-android-device-launch-in-progress.md).

## Phase objective

The revised phase goal is a working proof-of-concept app in `apps/<name>/`, not merely codegen or CI verification. The PoC should prove the skill package end-to-end while showcasing:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Supporting verification remains required:

- Run the real codegen pipeline:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is not resolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator/device for Flutter
- Wire CI to run:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC on every push

## Android build issue found

A third real build bug was identified during the Flutter Android launch path:

- `fastembed` uses `ort` / ONNX Runtime for on-device embeddings.
- `ort` has no prebuilt binary for `i686-linux-android`.
- Cargokit's vendored `plugin.gradle` unconditionally cross-compiles the 32-bit x86 Android target for every debug build.
- The current test target is a real ARM64 Android device, not a 32-bit x86 emulator, so `i686-linux-android` is unnecessary for this run.

## Fix applied

- Dropped `android-x86` from the debug target list in the vendored cargokit `plugin.gradle` path.
- Kept `x86_64` support for modern Android emulators.
- Added matching Android `abiFilters` in the app's `build.gradle.kts`.

The intended ABI coverage after the fix is:

- ARM64 physical devices
- x86_64 modern emulators
- No 32-bit x86 Android build target for debug builds

## Current state

The build was retried after the ABI adjustment. The monitor is waiting for the Android build to finish:

- No remaining `whisper.cpp` issue expected.
- No remaining `wasmer` issue expected.
- No remaining `i686` `ort` issue expected.
- Expected next steps:
  1. Complete ARM64/x86_64 cross-compilation.
  2. Install to Android device `SM S936U`.
  3. Launch the Flutter PoC on-device.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification

## Consolidated source variants

### Variant from `compassionate-babbage-7cd4bc`

Original path: `.prometheus/knowledge/wiki/knowme-poc-android-build-fix-for-i686-onnx-runtime-target.md`  
Original SHA-256: `444ed3b8856970cd796a151e02502d32b229f7d5c49bc4fd80ea983891b4421e`

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-16T14:47:15Z`
- **Status:** `executing`

This execution tick continues the PoC-first phase scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Android device launch work in [KnowMe PoC Flutter Android device launch in progress](/knowme-poc-flutter-android-device-launch-in-progress.md).

## Phase objective

The revised phase goal is a working proof-of-concept app in `apps/<name>/`, not merely codegen or CI verification. The PoC should prove the skill package end-to-end while showcasing:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Supporting verification remains required:

- Run the real codegen pipeline:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is not resolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator/device for Flutter
- Wire CI to run:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC on every push

## Android build issue found

A third real build bug was identified during the Flutter Android launch path:

- `fastembed` uses `ort` / ONNX Runtime for on-device embeddings.
- `ort` has no prebuilt binary for `i686-linux-android`.
- Cargokit's vendored `plugin.gradle` unconditionally cross-compiles the 32-bit x86 Android target for every debug build.
- The current test target is a real ARM64 Android device, not a 32-bit x86 emulator, so `i686-linux-android` is unnecessary for this run.

## Fix applied

- Dropped `android-x86` from the debug target list in the vendored cargokit `plugin.gradle` path.
- Kept `x86_64` support for modern Android emulators.
- Added matching Android `abiFilters` in the app's `build.gradle.kts`.

The intended ABI coverage after the fix is:

- ARM64 physical devices
- x86_64 modern emulators
- No 32-bit x86 Android build target for debug builds

## Current state

The build was retried after the ABI adjustment. The monitor is waiting for the Android build to finish:

- No remaining `whisper.cpp` issue expected.
- No remaining `wasmer` issue expected.
- No remaining `i686` `ort` issue expected.
- Expected next steps:
  1. Complete ARM64/x86_64 cross-compilation.
  2. Install to Android device `SM S936U`.
  3. Launch the Flutter PoC on-device.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
