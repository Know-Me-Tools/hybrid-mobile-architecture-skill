---
type: Reference
id: knowme-poc-android-fixes-pushed-during-codegen-and-ci-phase
title: KnowMe PoC Android fixes pushed during codegen and CI phase
tags:
- hybrid-mobile-architecture
- knowme-poc
- android-build
- codegen
- ci-verification
- flutter
- tauri
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T16:51:54.773875+00:00
created_at: 2026-07-16T16:51:54.773875+00:00
updated_at: 2026-07-16T16:51:54.773875+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T16:28:17Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

## Phase goal

The phase remains scoped as a working proof-of-concept application, not only pipeline verification. This continues the PoC-first direction captured in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md).

Primary objective:

- Build a proof-of-concept app under `apps/<name>/` using repository scaffolds and skills.
- Base the PoC on KnowMe reference documentation in `docs/reference-app/`, including the functional spec, moodboard, and user journeys.
- Prove the skill package end-to-end while showcasing the broadest practical range of supported capabilities:
  - streaming `ContentBlock` chat
  - PEM entity management
  - SurrealDB graph-RAG memory
  - local-first sync
  - cross-platform Flutter, Tauri, and web surfaces from one Rust core
- Select the feature subset using web research on showcase-app best practices and 2026 on-device AI feasibility.

Supporting objectives from the original pipeline-focused scope remain active and should be proven through the PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - full `flutter pub get`
  - full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - boundary test suites against the PoC

## Session result

- Android build fixes were committed and pushed successfully to `main`.
- Git push advanced `main` from `2084bb8` to `9ccdf33`.
- Current state: Android build fixes are in the remote branch and awaiting direction on the next task.

## Pending direction

Potential next steps called out for selection:

- Re-enable Scribe on Android.
- Move to the next phase task.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification