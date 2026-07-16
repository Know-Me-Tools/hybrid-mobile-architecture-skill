---
type: Reference
id: knowme-poc-flutter-ffi-bridge-fixes-before-android-rebuild
title: KnowMe PoC Flutter FFI bridge fixes before Android rebuild
tags:
- hybrid-mobile-architecture
- knowme-poc
- flutter
- android
- flutter-rust-bridge
- ffi
- codegen
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-flutter-android-device-launch-in-progress
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T13:37:46.079771+00:00
created_at: 2026-07-16T13:37:46.079771+00:00
updated_at: 2026-07-16T13:37:46.079771+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T13:36:49Z`
- **Phase status:** `executing`

This execution tick continues the PoC-first phase scope from [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Android launch work tracked in [KnowMe PoC Flutter Android device launch in progress](/knowme-poc-flutter-android-device-launch-in-progress.md).

## Phase objective

The phase deliverable is a working proof-of-concept app in `apps/<name>/`, not merely pipeline verification. The PoC must exercise the repository scaffolds and skills end-to-end using KnowMe reference documentation in `docs/reference-app/`.

The PoC should demonstrate:

- Streaming `ContentBlock` chat.
- PEM entity management.
- SurrealDB graph-RAG memory.
- Local-first sync.
- Cross-platform Flutter, Tauri, and web support from one Rust core.
- Practical 2026 on-device AI feasibility and showcase-app best practices.

Supporting verification goals remain:

- Run `flutter_rust_bridge_codegen generate` against the PoC.
- Run `dart run build_runner build`.
- Complete `flutter pub get` and `pnpm install`.
- Clear pre-codegen warnings once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` being unresolvable outside the PEM monorepo.
- Verify at least one target per surface:
  - macOS Tauri desktop.
  - iOS simulator or Android emulator/device for Flutter.
- Wire CI to run:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC on every push.

## Dart and FFI bridge fixes completed

Dart compile failures were traced to incomplete FFI bridge wiring rather than transient generated-code issues.

### Stream payload types changed to JSON strings

The following stream channels were changed to carry JSON strings across the FFI boundary:

- `chat_events`
- `entity_changes`
- `sync_status`

Rationale: `gen_ui_types` must remain `flutter_rust_bridge`-agnostic because it also targets WASM. Using opaque FRB enums for stream types coupled the shared UI type package to FRB-specific bridge behavior.

### JSON deserialization added

`fromJson` support was added for:

- `ContentBlock`
- `A2uiEvent`
- PEM `SyncStatus`

This supports the JSON-string FFI stream boundary while keeping shared generated UI types portable.

### `FilterOp` enum mapping fixed

The mismatched `FilterOp` variants causing Dart-side compile errors were corrected so bridge/generated enum usage aligns with the expected PEM/filter representation.

### App data directory wired into startup

Real `path_provider`-based data directory resolution was wired into:

- `main.dart`
- `startup_notifier.dart`

This resolves the missing `dataDir` startup wiring required for native app initialization.

## Verification state

- `dart analyze` is clean across all app code after the fixes.
- The Android build is being retried.
- Expected state: both native layers and Dart layers should now be clean.
  - Native layers include Rust, `whisper.cpp`, and CMake integration.
  - Dart layer compile/analyze issues have been resolved.
- Target device for install/launch confirmation: **SM S936U**.

## Next action

Wait for the monitored Android rebuild to complete, then confirm install and launch on the SM S936U. If a new issue surfaces, diagnose from the next build/runtime failure rather than revisiting the already-fixed Dart FFI bridge errors.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification