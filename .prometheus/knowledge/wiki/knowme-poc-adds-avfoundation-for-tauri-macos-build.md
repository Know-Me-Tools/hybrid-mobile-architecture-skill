---
type: Reference
id: knowme-poc-adds-avfoundation-for-tauri-macos-build
title: KnowMe PoC adds AVFoundation for Tauri macOS build
tags:
- hybrid-mobile-architecture
- knowme-poc
- tauri
- macos-linking
- avfoundation
- cpal
- codegen
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-tauri-dev-build-wait-loop-handoff
- poc-focused-codegen-and-ci-phase-assessment-update
- hybrid-codegen-and-ci-verification-assessment-readiness
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T10:43:49.845273+00:00
created_at: 2026-07-16T10:43:49.845273+00:00
updated_at: 2026-07-16T10:43:49.845273+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T10:38:03Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This continues the PoC-first scope summarized in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Tauri build wait-loop state in [KnowMe PoC Tauri dev build wait-loop handoff](/knowme-poc-tauri-dev-build-wait-loop-handoff.md).

## Phase goals

### Primary goal

Build a proof-of-concept app in `apps/<name>/` using repository scaffolds and skills, based on the KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

The feature subset is selected via web research on showcase-app best practices and 2026 on-device AI feasibility. This reflects the PoC-focused assessment update in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), superseding the earlier pipeline-only framing in [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md).

### Supporting goals proven by the PoC

- Run the real codegen pipeline:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI on every push for:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Build/linking update

The third macOS framework-linking gap was fixed for the Tauri dev build:

- `AVFoundation` was still missing after prior additions of:
  - `CoreAudio`
  - `AudioToolbox`
  - `Accelerate`
- The missing symbols came from `cpal` `AVAudioSession*` route-change/media-services usage.
- `AVFoundation` was added to both podspecs.
- `pod install` confirmed the generated xcconfig now carries:
  - `CoreAudio`
  - `AudioToolbox`
  - `Accelerate`
  - `AVFoundation`
  - `-lc++`
- The build was relaunched with a persistent monitor watching for completion or the next missing framework.

## Next actions

1. Await the current build result.
2. If another missing framework surfaces, add it to the podspecs and repeat `pod install` + relaunch.
3. Once the build is clean:
   - Complete T11.
   - Commit C-107/C-110 work.
   - Move to T12 documentation.
   - Mark C-103 done.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
