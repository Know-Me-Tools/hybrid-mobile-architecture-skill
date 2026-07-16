---
type: Reference
id: knowme-poc-android-cmake-abi-fix-for-whisper-cpp-build
title: KnowMe PoC Android CMake ABI fix for whisper.cpp build
tags:
- hybrid-mobile-architecture
- knowme-poc
- android
- cmake
- flutter
- cargokit
- whisper-cpp
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-flutter-android-device-launch-in-progress
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T13:12:27.648896+00:00
created_at: 2026-07-16T13:12:27.648896+00:00
updated_at: 2026-07-16T13:12:27.648896+00:00
revision: 0
---

## Context

- Project: Hybrid Mobile Architecture
- Phase: `phase-codegen-and-ci-verification`
- KBD root: `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`
- Captured: `2026-07-16T13:11:31Z`
- Position: `phase-codegen-and-ci-verification`
- Status: `executing`

This execution tick continues the PoC-first phase scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Android device launch/build work tracked in [KnowMe PoC Flutter Android device launch in progress](/knowme-poc-flutter-android-device-launch-in-progress.md).

## Phase objective

The phase deliverable is a working KnowMe proof-of-concept app, not only pipeline verification. The PoC must validate the broader hybrid architecture end-to-end:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Shared Rust core across Flutter, Tauri, and web surfaces
- Real codegen and dependency flows:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
- Build/run verification on at least:
  - macOS Tauri desktop
  - iOS simulator or Android emulator/device for Flutter
- CI wiring for:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Android build failure root cause

The Android rebuild failed during `whisper.cpp` CMake configure/build because `cmake-rs` behavior was unintentionally changed by a prior fix:

- `cmake-rs` auto-derives `CMAKE_SYSTEM_PROCESSOR` only when `CMAKE_TOOLCHAIN_FILE` is **not** already set.
- The earlier fix set `CMAKE_TOOLCHAIN_FILE` eagerly.
- With the toolchain file already set, the Android NDK toolchain defaulted to `armeabi-v7a` for every architecture.
- On an `aarch64` build, this produced conflicting architecture flags, including `-march=armv7-a`.

Result: the NDK CMake configuration selected the wrong ABI for the active Cargo/Flutter Android target.

## Fix applied

Updated:

```text
apps/knowme-poc/mobile/rust_builder/cargokit/build_tool/lib/src/android_environment.dart
```

Added `TARGET_ANDROID_ABI`, derived from cargokit's existing `target.android` field, so the Android NDK toolchain file receives the correct ABI for each target.

Expected effect:

- `arm64-v8a`/aarch64 builds no longer fall back to `armeabi-v7a`.
- `whisper.cpp` CMake configure/build should use architecture-compatible flags.
- The Android APK build can proceed to install and launch on the target device.

## Current execution state

- A rebuild is in progress after the ABI propagation fix.
- Monitoring is waiting for `whisper.cpp` CMake configure/build to pass with the corrected ABI.
- Next expected step: APK install and launch on Android device `SM S936U`.
- If a new failure appears, diagnose from the next build output rather than revisiting the previous ABI mismatch unless the logs still show `armeabi-v7a` or `-march=armv7-a` on an aarch64 build.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification