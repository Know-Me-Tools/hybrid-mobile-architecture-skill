<!-- source=primary; branch=main-pre-consolidation; original_sha256=47ecac80619b20831bf28c9263567ed0109944a5505e87a7b9d8ab5d8aa8e0db -->
---
type: Reference
id: knowme-poc-android-build-restricted-to-arm64-v8a-for-ort
title: KnowMe PoC Android build restricted to arm64-v8a for ort
tags:
- hybrid-mobile-architecture
- knowme-poc
- android
- ort
- arm64-v8a
- flutter
- codegen
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-tauri-dev-build-wait-loop-handoff
- knowme-poc-tauri-launch-wait-loop-pending-interactive-verification
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T14:58:06.907395+00:00
created_at: 2026-07-16T14:58:06.907395+00:00
updated_at: 2026-07-16T14:58:06.907395+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T14:57:03Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This tick continues the PoC-first execution scope in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md), after prior Tauri wait-loop work in [KnowMe PoC Tauri dev build wait-loop handoff](/knowme-poc-tauri-dev-build-wait-loop-handoff.md) and [KnowMe PoC Tauri launch wait-loop pending interactive verification](/knowme-poc-tauri-launch-wait-loop-pending-interactive-verification.md).

## Phase goal

The revised phase deliverable is a working proof-of-concept app in `apps/<name>/`, not only pipeline verification. The PoC is expected to prove repository scaffolds and skills end-to-end using the KnowMe reference documentation in `docs/reference-app/`.

Supported capabilities to showcase where practical:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web from one Rust core

Original codegen and CI goals remain supporting objectives:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` cannot resolve outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator/device for Flutter
- Wire CI to run:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC on every push

## Android build finding

`ort` only ships prebuilt Android binaries for `arm64-v8a` in this environment.

- No emulator ABI is available for `ort`, including `x86_64`.
- The available physical test device is ARM64.
- Emulator ABIs were removed from both:
  - cargokit debug build ABI list
  - app-level Android `abiFilters`
- Android build is now restricted to `arm64-v8a` only.

## Current action

A retry is in progress with all prior blockers avoided and Android restricted to a single architecture:

```text
arm64-v8a
```

## Next step

Wait for the monitor to finish the single-arch Android build, then confirm install and launch on the physical device:

```text
SM S936U
```

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification