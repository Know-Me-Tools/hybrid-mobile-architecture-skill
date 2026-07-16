---
type: Reference
id: knowme-poc-tauri-relaunch-after-stale-vite-port-cleanup
title: KnowMe PoC Tauri relaunch after stale Vite port cleanup
tags:
- hybrid-mobile-architecture
- knowme-poc
- tauri
- vite
- wait-loop
- codegen
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-tauri-dev-build-wait-loop-handoff
- poc-focused-codegen-and-ci-phase-assessment-update
- hybrid-codegen-and-ci-verification-assessment-readiness
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T10:09:37.530429+00:00
created_at: 2026-07-16T10:09:37.530429+00:00
updated_at: 2026-07-16T10:09:37.530429+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T10:08:23Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This session continues the PoC-first execution scope summarized in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the active Tauri launch wait-loop from [KnowMe PoC Tauri dev build wait-loop handoff](/knowme-poc-tauri-dev-build-wait-loop-handoff.md). The phase scope was revised in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), superseding the earlier pipeline-only framing in [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md).

## Phase goal

The phase deliverable is a working proof-of-concept application, not only codegen or CI verification.

### Primary objective

Build a PoC app under `apps/<name>/` using repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must demonstrate the skill package end-to-end and showcase the broadest practical supported capability set:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Feature scope is selected using web research on showcase-app best practices and 2026 on-device AI feasibility.

### Supporting objectives

The original codegen and CI goals remain proof points demonstrated by the PoC:

- Run real codegen against the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - full `flutter pub get`
  - `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - boundary test suites against the PoC

## Current execution state

- Cleared a second leftover process: a stale Vite dev server was still holding port `1420` after an earlier kill.
- Relaunched the Tauri development build after freeing the port.
- Waiting for the build to finish and for the desktop window to open.
- Next check: wait for the background wait-loop to report whether this launch succeeds cleanly with:
  - the `bundled` runtime-asset fix
  - a fresh `config-db`

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification