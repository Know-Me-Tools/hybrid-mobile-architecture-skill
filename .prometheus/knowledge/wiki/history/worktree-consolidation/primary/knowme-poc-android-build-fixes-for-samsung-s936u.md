<!-- source=primary; branch=main-pre-consolidation; original_sha256=f3279f372d9c439807acbcc9e468057956a3023e7177f2ae5f460379f0d33c2d -->
---
type: Reference
id: knowme-poc-android-build-fixes-for-samsung-s936u
title: KnowMe PoC Android build fixes for Samsung S936U
tags:
- hybrid-mobile-architecture
- knowme-poc
- android
- cargokit
- flutter-rust-bridge
- onnx-runtime
- whisper-rs
- gradle
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T15:35:43.846141+00:00
created_at: 2026-07-16T15:35:43.846141+00:00
updated_at: 2026-07-16T15:35:43.846141+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T15:34:54Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This execution continues the PoC-first scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md): the phase deliverable is a working proof-of-concept application, with codegen and CI verification as supporting proof points.

## Result

The KnowMe PoC app is now built and running on a Samsung S936U Android device.

## Android build blockers resolved

1. **Gradle 9 removed `project.exec {}`**
   - Patched cargokit's `plugin.gradle` to use injected `ExecOperations` instead.

2. **`fastembed` pulled in OpenSSL through default features**
   - Default features brought in `native-tls` / `openssl-sys`, which cannot cross-compile cleanly for Android.
   - Switched to `rustls-tls` feature variants.

3. **`whisper-rs-sys` CMake build lacked Android toolchain metadata**
   - The build needed explicit NDK toolchain and ABI environment variables.
   - Neither `cmake-rs` nor `whisper-rs-sys` supplied these automatically.
   - Added the required values to cargokit's Android build environment.

4. **Scribe / `gen_ui_audio` still failed on Android**
   - The `whisper-rs` path still hits an unresolved Android CMake ABI-detection bug.
   - Workaround: disabled Scribe voice transcription on Android only.

5. **`gen_ui_db` enabled `pglite` on mobile incorrectly**
   - The `pglite` feature pulled in `wasmer`, which fails to cross-compile for x86 Android.
   - Target-gated `pglite` off for iOS and Android.

6. **`ort` Android binary availability is limited**
   - ONNX Runtime (`ort`) does not provide prebuilt Android binaries for all ABIs.
   - Available prebuilt support is limited to `arm64-v8a`.
   - Restricted the Android app build to `arm64-v8a`, matching the Samsung S936U test device.

7. **Cargokit Gradle plugin used old SDK level**
   - The cargokit-generated Gradle plugin module hardcoded `compileSdk 33`.
   - Newer AndroidX dependencies require a newer SDK.
   - Bumped `compileSdk` to `36`.

8. **Missing C++ runtime shared library**
   - `libgen_ui_ffi.so` required the NDK runtime library `libc++_shared.so` at runtime.
   - Added a copy step to cargokit's build pipeline so `libc++_shared.so` is bundled alongside `libgen_ui_ffi.so`.

## Remaining known issue

- **Scribe voice transcription is disabled on Android only.**
- Root cause: unresolved `whisper-rs-sys` Android/CMake ABI-detection bug.
- Other Android PoC functionality is not described as blocked by this issue.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification