<!-- source=compassionate-babbage-7cd4bc; branch=claude/compassionate-babbage-7cd4bc; original_sha256=f5f101038b55776eee3573a7c303dbb8e0b43afc932c674cc100a54bb3ede3d0 -->
---
type: Reference
id: knowme-poc-android-device-run-fixes-and-remaining-scribe-gap
title: KnowMe PoC Android device run fixes and remaining Scribe gap
tags:
- hybrid-mobile-architecture
- knowme-poc
- android
- flutter
- rust-ffi
- cargokit
- cmake
- whisper-rs
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T15:35:14.402640+00:00
created_at: 2026-07-16T15:35:14.402640+00:00
updated_at: 2026-07-16T15:35:14.402640+00:00
revision: 0
---

## Context

- Project: Hybrid Mobile Architecture
- Phase: `phase-codegen-and-ci-verification`
- KBD root: `$REPO_ROOT`
- Captured: `2026-07-16T15:34:28Z`
- Phase source: `manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification`

This continues the PoC-first scope defined in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md): the phase deliverable is a working proof-of-concept app, with codegen and CI verification as supporting objectives.

## Result

The KnowMe PoC app is successfully built and running on a Samsung S936U Android device.

Observed runtime state:

- No `dlopen` crash.
- No unhandled exceptions.
- Logs show normal Flutter rendering activity:
  - frame drawing
  - surface setup
  - input method registration
  - UI rendering
- The Android `libc++_shared.so` bundling fix resolved the final native-library load failure.

## Android build blockers resolved

1. **Gradle 9 removed `project.exec {}`**
   - Patched cargokit's `plugin.gradle` to use injected `ExecOperations`.

2. **`fastembed` default TLS stack was not Android-cross-compilable**
   - Default features pulled in `native-tls` / `openssl-sys`.
   - Switched to `rustls-tls` feature variants.

3. **`whisper-rs-sys` CMake build lacked Android NDK configuration**
   - Added explicit cargokit Android build environment variables:
     - `TARGET_CMAKE_TOOLCHAIN_FILE`
     - `TARGET_CMAKE_GENERATOR=Ninja`
     - `CMAKE_ANDROID_ARCH_ABI`

4. **Scribe / `gen_ui_audio` unresolved Android CMake ABI detection issue**
   - `whisper-rs` still failed despite the NDK toolchain variables.
   - Disabled Scribe on Android specifically:
     - Rust feature-gated the audio path.
     - Hand-patched the generated Flutter Rust Bridge bridge.
   - This is a temporary Android-only workaround.

5. **`gen_ui_db` incorrectly enabled `pglite` on mobile**
   - The `pglite` feature pulled in `wasmer`.
   - `wasmer` failed to cross-compile for x86 Android.
   - Target-gated `pglite` off for iOS and Android.

6. **`ort` Android binary availability was architecture-limited**
   - ONNX Runtime did not provide prebuilt Android binaries except `arm64-v8a`.
   - Restricted the app to `arm64-v8a`, matching the Samsung S936U device.

7. **Generated Gradle plugin module used stale Android SDK level**
   - cargokit-generated Gradle plugin module hardcoded `compileSdk 33`.
   - Newer AndroidX dependencies required a newer SDK.
   - Bumped `compileSdk` to `36`.

8. **Native C++ runtime library was missing from APK bundle**
   - `libgen_ui_ffi.so` required the NDK `libc++_shared.so` at runtime.
   - Added a cargokit build-pipeline copy step to bundle `libc++_shared.so` alongside the generated FFI shared library.

## Remaining gap

- Scribe voice transcription is disabled on Android only.
- A proper fix is still needed for the `whisper-rs-sys` Android/CMake ABI-detection bug.
- Other Android app functionality is running after the native-library bundling fix.

## Phase goal status

The Android-device milestone supports the broader phase objective by proving that the hybrid Rust/Flutter stack can build and run on a real mobile target. The session specifically validates Android runtime viability after resolving Gradle, Rust crate feature, CMake/NDK, ABI, SDK, and native-library packaging blockers.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification