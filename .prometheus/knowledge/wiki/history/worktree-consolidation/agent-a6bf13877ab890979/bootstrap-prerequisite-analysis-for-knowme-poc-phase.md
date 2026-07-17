<!-- source=agent-a6bf13877ab890979; branch=worktree-agent-a6bf13877ab890979; original_sha256=d7aefac0b8603284a1cb4ca4f1ef94737d8624d8bba44a6d959f945e6bc7e0d1 -->
---
type: Reference
id: bootstrap-prerequisite-analysis-for-knowme-poc-phase
title: Bootstrap prerequisite analysis for KnowMe PoC phase
tags:
- hybrid-mobile-architecture
- knowme-poc
- bootstrap
- codegen
- ci-verification
- flutter-rust-bridge
- pem-install
- environment-checks
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-15T22:49:56.383600+00:00
created_at: 2026-07-15T22:49:56.383600+00:00
updated_at: 2026-07-15T22:49:56.383600+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-15T22:35:47Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `analyzing` with bootstrap-prerequisites research running

This phase has been revised so the primary deliverable is a working proof-of-concept app, not only codegen and CI validation. This continues the direction established in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md) and the completed assessment recorded in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md).

## Primary goal

Build a proof-of-concept app under `apps/<name>/` using the repository scaffolds and skills, based on the KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical set of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web from one Rust core

The feature subset is to be selected using web research into showcase-app best practices and 2026 feasibility for on-device AI.

## Supporting goals proven through the PoC

The original codegen/CI scope remains required as proof points:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker:
  - `@prometheus-ags/entity-graph-core@workspace:*` is currently unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites against the PoC

## Bootstrap-prerequisites research

A research agent is currently gathering data for bootstrap design. It is verifying:

- Actual `prometheus-skill-system` repository requirements
- OpenSpec canonical distribution and latest version
- Flutter beta-channel mechanics
- Node, Bun, pnpm, and TypeScript 6 install matrix
- Delta against the current `scripts/check-env.sh`

Current `scripts/check-env.sh` coverage is narrower and checks:

- Rust
- Flutter
- Node 22+
- pnpm
- Flutter Rust Bridge (`frb`)
- Android NDK
- Tauri
- Xcode

Known missing checks or policies under investigation:

- Bun
- TypeScript version check
- OpenSpec
- `prometheus-skill-system`
- Flutter beta-channel enforcement

## Planned analysis artifacts

After research completes, write:

- `analysis.md`
- `library-candidates.json`
- Decision-log entries
- Analyze handoff

The analysis should cover:

- Four bootstrap pillars
- Verify-vs-install behavior per pillar
- How bootstrap becomes the skill startup installation process
- Whether to extend `scripts/check-env.sh --install` or create a new `bootstrap.sh`

## Next step

Proceed to `/kbd-plan` after the analysis artifacts are written. Planning must cover bootstrap changes and PoC implementation changes together.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification