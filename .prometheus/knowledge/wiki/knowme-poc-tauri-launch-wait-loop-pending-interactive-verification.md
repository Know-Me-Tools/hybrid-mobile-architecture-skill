---
type: Reference
id: knowme-poc-tauri-launch-wait-loop-pending-interactive-verification
title: KnowMe PoC Tauri launch wait-loop pending interactive verification
tags:
- hybrid-mobile-architecture
- knowme-poc
- tauri
- wait-loop
- codegen
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-tauri-dev-build-wait-loop-handoff
- knowme-poc-live-boot-verification-passed-on-fresh-tauri-config-db
- poc-focused-codegen-and-ci-phase-assessment-update
- hybrid-codegen-and-ci-verification-assessment-readiness
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T11:21:02.219638+00:00
created_at: 2026-07-16T11:21:02.219638+00:00
updated_at: 2026-07-16T11:21:02.219638+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T11:20:10Z`
- **Phase source:** `manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification`

This execution tick continues the PoC-first scope captured in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md). It follows the Tauri dev wait-loop state in [KnowMe PoC Tauri dev build wait-loop handoff](/knowme-poc-tauri-dev-build-wait-loop-handoff.md) and is adjacent to the fresh-config live boot result in [KnowMe PoC live boot verification passed on fresh Tauri config DB](/knowme-poc-live-boot-verification-passed-on-fresh-tauri-config-db.md). The phase scope was revised from pipeline-only verification by [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), superseding [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md).

## Current execution state

- The KnowMe PoC app has been launched in the background.
- Expected behavior: a Tauri window should open on-screen once the build/launch finishes.
- Build is expected to complete quickly because artifacts are already compiled.
- Active next step: wait for the wait-loop to confirm the window has opened, then hand control to the user for interactive driving.

## Revised phase objective

The phase deliverable is a **working proof-of-concept application**, not just codegen or CI verification.

### Primary goal

Build a PoC app under `apps/<name>/` using repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package works end-to-end and showcase the broadest practical set of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces backed by one Rust core

The feature subset is selected via web research into showcase-app best practices and 2026 on-device AI feasibility.

## Supporting verification goals

The original codegen/CI goals remain supporting objectives and should be proven through the PoC:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - full `flutter pub get`
  - full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker:
  - `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI on every push to run:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - boundary test suites against the PoC

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
