---
type: Reference
id: knowme-poc-stale-pglite-lock-cleared-before-tauri-relaunch
title: KnowMe PoC stale PGlite lock cleared before Tauri relaunch
tags:
- hybrid-mobile-architecture
- knowme-poc
- tauri
- pglite
- stale-lock
- manual-testing
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-tauri-dev-build-wait-loop-handoff
- poc-focused-codegen-and-ci-phase-assessment-update
- hybrid-codegen-and-ci-verification-assessment-readiness
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T09:57:55.383655+00:00
created_at: 2026-07-16T09:57:55.383655+00:00
updated_at: 2026-07-16T09:57:55.383655+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T09:56:26Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This continues the PoC-first scope captured in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and follows the Tauri build wait-loop handoff in [KnowMe PoC Tauri dev build wait-loop handoff](/knowme-poc-tauri-dev-build-wait-loop-handoff.md). The phase scope was revised from pipeline-only verification to a working proof-of-concept in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), superseding [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md).

## Failure cause and resolution

- The observed Tauri/PGlite startup failure was caused by a stale `knowme-poc` process from an earlier build/test run in the same session.
- That stale process was still holding the PGlite lock.
- The stale `knowme-poc` process was killed.
- A follow-up process check confirmed no leftover `knowme-poc` processes remained.
- `tauri dev` was relaunched from a clean slate.

## Current execution state

- Waiting for the relaunched `tauri dev` build to finish and open the desktop window.
- Once the window is available, hand off manual validation before merge.

## Manual test checklist before merge

Run these checks against the relaunched KnowMe PoC desktop app:

1. **Double-launch guard**
   - Start one instance of the app.
   - Attempt to start a second instance.
   - Confirm the app handles the second launch safely and does not corrupt or deadlock the PGlite store.

2. **Stale-lock recovery**
   - Simulate or verify recovery from a prior stale PGlite lock condition.
   - Confirm a clean relaunch succeeds after orphaned `knowme-poc` processes are removed.

3. **Double-init log check**
   - Inspect startup logs.
   - Confirm initialization does not run twice unexpectedly.
   - Confirm there are no repeated PGlite/database initialization sequences caused by duplicate app bootstraps.

4. **Golden-path chat**
   - Exercise the primary chat path.
   - Confirm streaming `ContentBlock` chat works through the Rust/Tauri surface.
   - Confirm the PoC remains usable after startup recovery.

## Phase goals still being proven

The phase deliverable remains a working KnowMe proof-of-concept application under `apps/<name>/`, based on `docs/reference-app/`, proving the skill package end-to-end. Supporting proof points include:

- Running the real codegen pipeline:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
- Resolving or working around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` being unresolvable outside the PEM monorepo.
- Verifying at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wiring CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification