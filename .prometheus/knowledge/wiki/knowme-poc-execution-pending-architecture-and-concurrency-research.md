---
type: Reference
id: knowme-poc-execution-pending-architecture-and-concurrency-research
title: KnowMe PoC execution pending architecture and concurrency research
tags:
- hybrid-mobile-architecture
- knowme-poc
- codegen
- ci-verification
- contentblock-streaming
- surrealdb
- concurrency
links:
- poc-focused-codegen-and-ci-phase-assessment-update
- knowme-poc-assessment-for-codegen-and-ci-verification-phase
- c-103-execute-handoff-for-knowme-poc-live-chat-milestone
- hybrid-codegen-and-ci-verification-assessment-readiness
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T08:31:22.336244+00:00
created_at: 2026-07-16T08:31:22.336244+00:00
updated_at: 2026-07-16T08:31:22.336244+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-16T08:30:36Z`
- **Status:** execution in progress

This execution point continues the PoC-first phase scope from [PoC-focused codegen and CI phase assessment update](/poc-focused-codegen-and-ci-phase-assessment-update.md), following the assessed and handoff states in [KnowMe PoC assessment for codegen and CI verification phase](/knowme-poc-assessment-for-codegen-and-ci-verification-phase.md) and [C-103 execute handoff for KnowMe PoC live chat milestone](/c-103-execute-handoff-for-knowme-poc-live-chat-milestone.md). It supersedes the earlier pipeline-only framing in [Hybrid codegen and CI verification assessment readiness](/hybrid-codegen-and-ci-verification-assessment-readiness.md).

## Current phase goal

The phase deliverable is a working proof-of-concept application, not just codegen or CI verification.

Build a KnowMe-based PoC in `apps/<name>/` using repository scaffolds and skills, based on reference documentation in `docs/reference-app/`:

- Functional specification
- Moodboard
- User journeys

The PoC must prove the skill package end-to-end and showcase the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

The feature subset should be selected using web research on showcase-app best practices and 2026 on-device AI feasibility.

## Supporting verification goals

The original codegen and CI objectives remain required, but as supporting evidence demonstrated through the PoC:

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

## Session state

Two exploration agents are running in the background:

1. **Data/state architecture mapping**
   - PGlite
   - SurrealDB
   - Tokio runtime
   - `ContentBlock` pipeline
   - Startup sequence

2. **Concurrency guidance survey**
   - Existing written guidance in the repository on concurrency patterns

Execution is intentionally paused until both agents report back, rather than polling.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification