---
type: Reference
id: knowme-poc-android-rebuild-after-clearing-stale-cmake-cache
title: KnowMe PoC Android rebuild after clearing stale CMake cache
tags:
- hybrid-mobile-architecture
- knowme-poc
- flutter
- android
- cmake
- ninja
- codegen
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-flutter-android-device-launch-in-progress
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T13:02:16.984722+00:00
created_at: 2026-07-16T13:02:16.984722+00:00
updated_at: 2026-07-16T13:02:16.984722+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T13:01:21Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This execution tick continues the PoC-first scope in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Android device launch attempt in [KnowMe PoC Flutter Android device launch in progress](/knowme-poc-flutter-android-device-launch-in-progress.md).

## Phase objective

The phase deliverable is a working proof-of-concept app in `apps/<name>/`, not only pipeline verification. The PoC is based on the KnowMe reference documentation in `docs/reference-app/` and must demonstrate the repository skill package end-to-end, including:

- Streaming `ContentBlock` chat.
- PEM entity management.
- SurrealDB graph-RAG memory.
- Local-first sync.
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core.

Supporting verification remains in scope:

- Run real code generation on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - full `flutter pub get` / `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one target per surface:
  - macOS Tauri desktop.
  - iOS simulator or Android emulator/device for Flutter.
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - boundary test suites against the PoC.

## Current execution state

- The CMake toolchain fix is considered valid.
- The latest failure was attributed to a stale `CMakeCache.txt` from an earlier configure attempt that defaulted to the `Unix Makefiles` generator before Ninja was configured.
- The stale build output was cleared by removing `build/gen_ui_ffi`.
- A clean rebuild is in progress.

## Next action

Monitor the clean rebuild until it passes the `whisper.cpp` CMake + Ninja configure/build step, then continue to APK install and launch on the Android device `SM S936U`.

If another failure appears, diagnose the new error rather than revisiting the stale-cache issue.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification