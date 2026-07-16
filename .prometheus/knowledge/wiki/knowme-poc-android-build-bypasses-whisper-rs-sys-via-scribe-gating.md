---
type: Reference
id: knowme-poc-android-build-bypasses-whisper-rs-sys-via-scribe-gating
title: KnowMe PoC Android build bypasses whisper-rs-sys via Scribe gating
tags:
- hybrid-mobile-architecture
- knowme-poc
- android
- flutter-rust-bridge
- whisper-rs-sys
- scribe
- codegen
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-flutter-android-device-launch-in-progress
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T14:17:43.364130+00:00
created_at: 2026-07-16T14:17:43.364130+00:00
updated_at: 2026-07-16T14:17:43.364130+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T14:16:34Z`
- **Phase source:** `manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This execution tick continues the PoC-first phase scope defined in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Android launch/build attempt tracked in [KnowMe PoC Flutter Android device launch in progress](/knowme-poc-flutter-android-device-launch-in-progress.md).

## Phase goals

The revised phase deliverable is a **working KnowMe proof-of-concept application**, not only codegen and CI verification.

### Primary goal

Build a PoC app under `apps/<name>/` using the repository scaffolds and skills, based on the KnowMe reference documentation in `docs/reference-app/`:

- Functional spec
- Moodboard
- User journeys

The PoC should prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core
- Feature subset selected via web research on showcase-app best practices and 2026 on-device AI feasibility

### Supporting objectives

The original codegen/CI scope remains, but is now validated through the PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator/device for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Android workaround applied

Android builds were blocked by an unresolved `whisper-rs-sys` CMake/NDK ABI issue pulled in through `gen_ui_audio` / Scribe.

To route around the issue, Scribe/audio generation was disabled specifically for Android:

- `Cargo.toml`: dependency target-gated so Android does not include the Scribe/`gen_ui_audio` dependency path.
- `api.rs`: module access `#[cfg]`-gated to exclude the Scribe module on Android.
- `frb_generated.rs`: hand-patched because `flutter_rust_bridge_codegen` runs on the host and cannot target-scope generated bindings for Android.

Expected result: Android cross-compilation should no longer touch `whisper.cpp` or `whisper-rs-sys`.

## Current execution state

- A retry of the Flutter/Rust Android build is in progress.
- The monitor is waiting for the build to finish, install, and launch on device `SM S936U`.
- Next verification point: confirm the Rust cross-compile skips `whisper-rs-sys` entirely on Android and proceeds to device launch.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification