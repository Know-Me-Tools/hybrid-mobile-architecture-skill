---
type: Reference
id: hybrid-scaffold-analysis-integrates-flint-platform-report
title: Hybrid scaffold analysis integrates Flint platform report
tags:
- hybrid-mobile-architecture
- scaffolding
- flint-platform
- rust-ffi
- tauri
- react-19
- sse
- wasm
links:
- hybrid-scaffold-assessment-receives-testing-policy-research
- hybrid-mobile-architecture-scaffold-phase-initialization
sources:
- stdin
- manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
timestamp: 2026-07-15T17:45:22.835955+00:00
created_at: 2026-07-15T17:45:22.835955+00:00
updated_at: 2026-07-15T17:45:22.835955+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T17:44:31Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `analyzing`
- **Research progress:** 2 of 4 analysis agents complete

This record continues the scaffold assessment and research flow after [Hybrid scaffold assessment receives testing policy research](/hybrid-scaffold-assessment-receives-testing-policy-research.md), within the phase initialized by [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md).

## Phase goals

- Create a new full instance of the hybrid mobile architecture:
  - Flutter mobile application layer
  - Rust FFI integration layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run scaffolding scripts to generate a complete working project from the reference library.
- Verify all generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment meets minimum tool version requirements.

## Flint platform report findings

The Flint platform analysis is complete and identifies three major architectural planes:

- **Gate: identity plane**
  - Kratos-based identity.
  - JWT authentication.
  - Cedar authorization policy.
  - Human-in-the-loop approvals.
- **Realtime-fabric: event spine**
  - Iggy log.
  - Loro CRDT synchronization.
  - WebRTC realtime transport.
- **Forge: data/edge plane**
  - Postgres 18 with row-level security (RLS).
  - A2UI/MCP registry.
  - Signed-WASM Kiln functions.

## Integration decisions

- Consume `frf-sdk-rust` **inside** `gen_ui_core`.
- Ignore Flint/FRF's broken UniFFI Dart bindings.
- Integrate `gate` and `forge` through the existing SSE client.
- Use `frf-wasm` and Connect-web for the browser surface.
- Treat all Flint/FRF dependencies as Git dependencies for now because nothing is published to package registries yet.

## Pending research

The analysis phase is waiting on remaining agent reports for:

- Entity-management inspection.
- PGlite/local-first research.
- SurrealDB 3.2 and Riverpod 3 research.

## Next actions

After receiving the remaining three agent reports:

1. Write `analysis.md`.
2. Write `library-candidates.json`.
3. Write `decision-log.md`.
4. Prepare handoff.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project