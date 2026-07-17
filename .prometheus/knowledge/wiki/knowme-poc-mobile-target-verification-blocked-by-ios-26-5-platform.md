---
type: Reference
id: knowme-poc-mobile-target-verification-blocked-by-ios-26-5-platform
title: KnowMe PoC mobile target verification blocked by iOS 26.5 platform
tags:
- hybrid-mobile-architecture
- knowme-poc
- ios-simulator
- flutter-rust-bridge
- tauri
- codegen
- ci-verification
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
- knowme-poc-c-102-desktop-web-branding-milestone
sources:
- stdin
timestamp: 2026-07-16T08:13:46.319071+00:00
created_at: 2026-07-16T08:13:46.319071+00:00
updated_at: 2026-07-16T08:13:46.319071+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T08:12:53Z`
- **Source:** `manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification`
- **Status:** T10 complete; T11 in progress; T12 pending

The phase remains under the PoC-first scope established in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md) and assessed in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md). The original codegen and CI goals are supporting proof points for the working KnowMe proof-of-concept rather than the primary deliverable.

## Phase goal

Build a proof-of-concept app in `apps/<name>/` using the repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web from one Rust core

The feature subset is selected using web research on showcase-app best practices and 2026 on-device AI feasibility.

## Supporting verification objectives

The PoC must prove the original phase objectives in passing:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker:
  - `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites

## Target verification status

### T10: macOS Tauri desktop

- **Status:** Complete.
- The first-time 999-crate build succeeded.
- The app launched and ran stably for more than 12 minutes.
- No runtime errors were observed.

This continues the desktop/web progress recorded in [KnowMe PoC C-102 desktop/web branding milestone](/knowme-poc-c-102-desktop-web-branding-milestone.md).

### T11: iOS simulator

- **Status:** In progress.
- Two real mobile wiring defects were found and fixed:
  1. A vestigial `gen_ui_flutter` plugin declaration existed without a matching podspec, blocking `pod install`.
  2. Cargokit native-build wiring was missing entirely.
- The cargokit wiring gap was fixed using:

```sh
flutter_rust_bridge_codegen integrate
```

- The generated/native integration was checked for correct relative paths in both:
  - iOS podspec wiring
  - Android Gradle wiring

Current blocker is machine-level Xcode configuration rather than repository code: Xcode 26.6 does not recognize any installed simulator as a build destination until the matching iOS 26.5 simulator platform is installed.

### iOS platform download monitor

- The iOS 26.5 simulator platform download is running in the background.
- A persistent monitor is watching for completion.
- A 30-minute fallback wakeup is also scheduled.
- T11 will resume automatically when either the platform download completes or the fallback wakeup fires.

### T12: defect documentation

- **Status:** Pending.
- T12 will document all defects found after T11 resolves, including the mobile wiring gaps:
  - Stale `gen_ui_flutter` plugin declaration with no podspec
  - Missing cargokit native-build wiring

## Citations

1. stdin
