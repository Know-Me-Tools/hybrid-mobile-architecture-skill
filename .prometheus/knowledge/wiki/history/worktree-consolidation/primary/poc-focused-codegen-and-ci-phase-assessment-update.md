<!-- source=primary; branch=main-pre-consolidation; original_sha256=8dda173f6c8b26ff937b1618e1515ac48227f2dbcb79a48cf5f327ca31429909 -->
---
type: Reference
id: poc-focused-codegen-and-ci-phase-assessment-update
title: PoC-focused codegen and CI phase assessment update
tags:
- hybrid-mobile-architecture
- proof-of-concept
- codegen
- ci-verification
- flutter-rust-bridge
- pem-install
- tauri
- flutter
links:
- hybrid-codegen-and-ci-verification-assessment-readiness
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-15T22:29:35.682415+00:00
created_at: 2026-07-15T22:29:35.682415+00:00
updated_at: 2026-07-15T22:29:35.682415+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T22:25:34Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `assessing` with showcase-selection research agent running

This update revises the phase scope from pipeline-only verification to building a working proof-of-concept application. It supersedes the earlier assessment-ready state captured in [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md) by making the PoC the primary deliverable and treating codegen/CI tasks as supporting proof points.

## Revised primary goal

Build a proof-of-concept app in `apps/<name>/` using the repository scaffolds and skills, based on the KnowMe reference documentation under `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package works end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter/Tauri/web delivery from one Rust core

Feature subset selection is deferred to web research covering showcase-app best practices and 2026 on-device AI feasibility.

## Supporting goals to prove through the PoC

The original codegen/CI verification goals remain in scope as acceptance criteria for the PoC:

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

## Toolchain assessment

Ready components:

- iOS simulators
- macOS desktop target
- Chrome target
- `pnpm` `11.11`
- `tauri-cli` `2.10.0`

Identified gap:

- `frb_codegen` is installed at `2.11.1`.
- The scaffold pins `flutter_rust_bridge` `2.12`.
- `flutter_rust_bridge` requires codegen and crate versions to align, so `frb_codegen` must be upgraded to `2.12` or the scaffold pin must be adjusted.

## Immediate next steps

After the showcase-selection research agent completes:

1. Write `assessment.md` covering:
   - PoC feature subset
   - Toolchain gaps, including `frb_codegen` `2.11.1` vs `flutter_rust_bridge` `2.12`
   - PEM install blocker options
2. Update `progress.json`.
3. Write handoff.
4. Proceed to `/kbd-plan`.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification