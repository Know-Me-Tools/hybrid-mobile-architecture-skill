---
type: Reference
id: knowme-poc-build-probe-during-codegen-and-ci-verification
title: KnowMe PoC build probe during codegen and CI verification
tags:
- hybrid-mobile-architecture
- knowme-poc
- codegen
- ci-verification
- flutter
- tauri
- impeller
- build-probe
links:
- knowme-poc-phase-goals-and-c-105-research-wait-state
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-17T01:33:59.125968+00:00
created_at: 2026-07-17T01:33:59.125968+00:00
updated_at: 2026-07-17T01:33:59.125968+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-17T01:33:29Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This continues the PoC-first direction from [KnowMe PoC phase goals and C-105 research wait state](/knowme-poc-phase-goals-and-c-105-research-wait-state.md): the phase output is a working proof-of-concept app, with codegen and CI verification serving as supporting proof points.

## Revised phase objective

As revised on `2026-07-15`, the phase end result is a **working proof-of-concept app**, not just pipeline verification.

### Primary goal

Build a PoC app in `apps/<name>/` using the repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web from one Rust core

Feature subset selection is informed by web research on showcase-app best practices and 2026 on-device AI feasibility.

### Supporting goals proven through the PoC

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
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Current execution state

- The batch has been committed.
- The refined-probe build is running.
- A waiter is expected to report the verdict that separates build failure from rendering/presentation failure.

## Next diagnostic branch

When the probe trail lands:

1. If `frame painted` prints:
   - Relaunch with `--no-enable-impeller`.
   - Rationale: Impeller-on-simulator presentation is suspected; this path has zero rebuild cost.
2. If `frame painted` does **not** print:
   - Treat the stall as layout/paint failure in the new shell.
   - Dump the isolate stack via the VM service.

## Remaining recorded work

- Capture T5 tab-bar screenshot.
- Remove temporary probe instrumentation.
- Complete remaining phase items:
  - `C-111` T1 tappable state
  - `C-111` T2
  - `C-111` T3
  - User Option-B decision
  - `C-106` decision

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
