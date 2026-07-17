<!-- source=compassionate-babbage-7cd4bc; branch=claude/compassionate-babbage-7cd4bc; original_sha256=6c5f98d4b62865970ba7133cff9e177ab7c7db7d4372b351be7cf77b62fc4d53 -->
---
type: Reference
id: knowme-poc-android-agp-9-compilesdk-fix-and-gradle-retry
title: KnowMe PoC Android AGP 9 compileSdk fix and Gradle retry
tags:
- hybrid-mobile-architecture
- knowme-poc
- android-gradle
- agp-9
- compile-sdk
- flutter
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T15:09:05.556655+00:00
created_at: 2026-07-16T15:09:05.556655+00:00
updated_at: 2026-07-16T15:09:05.556655+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-16T15:08:21Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This execution tick continues the PoC-first scope in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md). The phase deliverable is a working proof-of-concept application, with codegen and CI verification treated as supporting objectives.

## Phase goals

### Primary deliverable

Build a proof-of-concept app in `apps/<name>/` using this repository's scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and demonstrate the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web surfaces from one Rust core

Feature subset selection is informed by web research on showcase-app best practices and 2026 on-device AI feasibility.

### Supporting verification goals

The original codegen/CI objectives remain in scope and should be proven through the PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker:
  - `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator/device for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Current Android build issue and fix

### Problem

A dynamic `android.compileSdkVersion` reference resolved to `null` under AGP 9's new-DSL-only read mode.

Impact:

- The Android Gradle build could not rely on the previous cross-project lookup for `compileSdkVersion`.
- The issue blocked the current Flutter Android build/install loop.

### Decision

Hardcode `compileSdkVersion 36` directly in the Android Gradle configuration.

Rationale:

- `36` matches Flutter's current default.
- The cross-project lookup is broken under AGP 9's new-DSL-only read mode.
- A direct value avoids the `null` resolution path and allows Gradle assembly to proceed.

## Execution state

- Retrying the Android build after hardcoding `compileSdkVersion 36`.
- Rust build artifacts are fully cached.
- Expected remaining work is a fast Gradle-only pass:
  - `assembleDebug`
  - install
  - launch
- Target device: `SM S936U`.
- Next step: wait on the monitor for Gradle `assembleDebug`, install, and launch completion.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification