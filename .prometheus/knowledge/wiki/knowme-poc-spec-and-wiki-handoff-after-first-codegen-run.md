---
type: Reference
id: knowme-poc-spec-and-wiki-handoff-after-first-codegen-run
title: KnowMe PoC spec and wiki handoff after first codegen run
tags:
- hybrid-mobile-architecture
- knowme-poc
- codegen
- ci-verification
- tauri
- flutter-rust-bridge
- pem-install
- knowledge-base
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
- hybrid-codegen-and-ci-verification-assessment-readiness
- knowme-poc-c-102-desktop-web-branding-milestone
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T02:02:22.676773+00:00
created_at: 2026-07-16T02:02:22.676773+00:00
updated_at: 2026-07-16T02:02:22.676773+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T01:42:02Z`
- **Status:** `execute_ready`
- **Commit:** [`a74dd6f`](https://github.com/Know-Me-Tools/hybrid-mobile-architecture-skill/commit/a74dd6f)

The phase remains under the revised PoC-first scope introduced in [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md) and formalized in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md). The original pipeline verification goals from [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md) are now supporting proof points.

## Current phase goal

Build a working proof-of-concept app in `apps/<name>/` using the repository scaffolds and skills, based on KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical capability set:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Feature subset selection is informed by web research on showcase-app best practices and 2026 on-device AI feasibility.

## Supporting verification objectives

The PoC should prove the original codegen/CI objectives in passing:

- Run the real codegen pipeline on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - Full `flutter pub get`
  - Full `pnpm install`
- Confirm pre-codegen warnings clear after generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is unresolvable outside the PEM monorepo.
- Verify the PoC builds and runs on at least one real target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run on every push:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - Boundary test suites

## Completed handoff items

### 1. Architecture and implementation plan

`docs/reference-app/knowme-poc-architecture-and-implementation-plan.md` is ready for review.

It covers:

- Functional spec:
  - MoSCoW set
  - Demo narrative
  - Explicit WON'Ts with reasons
- Architecture:
  - 13-crate Rust core
  - `ContentBlock` contract
  - Intent-level FFI surface
  - Sync design
  - KnowMe brand tokens
  - Desktop shell as it actually exists after implementation
- C-101 through C-110 plan with live status
- §5, **Adjustments from execution**, recording corrections forced by the first codegen run:
  - Approximately 25 scaffold defects
  - `isTauri()` gating rule
  - Tauri v2 capabilities lessons
  - Stub-command requirements
  - Dev-icon requirements
  - PEM fallback state

The desktop/web branding milestone context is captured separately in [KnowMe PoC C-102 desktop/web branding milestone](/knowme-poc-c-102-desktop-web-branding-milestone.md).

### 2. Wiki logs

Session knowledge was compiled with `pk ingest` into both:

- Project wiki: `.prometheus/knowledge/wiki/knowme-poc-first-codegen-run-and-tauri-desktop-fixes.md`
- Private wiki: `~/.prometheus/knowledge`

The compiled knowledge includes:

- 15 durable lessons
- Brand tokens
- Desktop shell decisions
- Process notes

Raw source was preserved under `knowledge/raw/` in both locations so compiled page provenance survives.

### 3. `.prometheus` tracking

`.prometheus` tracking was verified:

- `git check-ignore` returns nothing for `.prometheus`
- Wiki files are present in the Git index
- The knowledge base should travel with the repository across workstations

## Known follow-up

`pk lint` currently reports 94 consolidation warnings in the project wiki. These are mostly duplicate auto-generated “phase completed” stubs from earlier sessions. Cleanup is recommended later but is not blocking the PoC work.

## Next work

Proceed into Wave 1:

- **C-103:** live chat end-to-end:
  - Anthropic SSE → `ContentBlock` stream
  - First iOS simulator run
- **C-110:** CI lane can run in parallel whenever desired.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification