---
type: Reference
id: knowme-poc-phase-awaits-architecture-map-for-db-startup-plan
title: KnowMe PoC phase awaits architecture map for DB startup plan
tags:
- hybrid-mobile-architecture
- knowme-poc
- pglite
- surrealdb
- embedded-db
- codegen
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T08:42:15.822824+00:00
created_at: 2026-07-16T08:42:15.822824+00:00
updated_at: 2026-07-16T08:42:15.822824+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T08:35:22Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This session continues the PoC-first scope summarized in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md): the phase deliverable is a working proof-of-concept app, with codegen and CI verification serving as supporting proof points.

## Phase objective

Build a proof-of-concept application in `apps/<name>/` using this repository's scaffolds and skills, based on the KnowMe reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must demonstrate the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web from one Rust core

Feature subset selection is informed by web research on showcase-app best practices and 2026 on-device AI feasibility.

## Supporting verification goals

The original codegen/CI goals remain in scope and must be proven through the PoC:

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

## Current findings

The reference-docs survey agent completed its pass.

Key finding:

- The repository has **no existing written guidance** for embedded database singleton, lock, or concurrency patterns.

Stale documentation issues to flag alongside the implementation fix:

- MSRV documentation still says Rust `1.95+`, while the required version is `1.96+`.
- `CLAUDE.md` still has a `pglite-oxide` section claiming native-binary/mobile support, even though that claim was already corrected in `docs/pglite-oxide-tauri-hybrid.md`.

## Waiting on architecture mapping

Planning is blocked on the second Explore agent, which is mapping the current architecture. Required outputs:

- PGlite initialization sites
- SurrealDB initialization sites
- Tokio runtime ownership/startup pattern
- `ContentBlock` pipeline locations
- Application startup sequence
- Exact `PgliteServer` startup code location

File-specific plan steps should not be written until the architecture map identifies the actual `PgliteServer` startup implementation.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
