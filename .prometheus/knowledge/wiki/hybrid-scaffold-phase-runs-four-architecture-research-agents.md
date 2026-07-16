---
type: Reference
id: hybrid-scaffold-phase-runs-four-architecture-research-agents
title: Hybrid scaffold phase runs four architecture research agents
tags:
- hybrid-mobile-architecture
- scaffolding
- research-agents
- flutter
- rust-ffi
- tauri
- react-19
- local-first
links:
- hybrid-scaffold-assessment-receives-testing-policy-research
- hybrid-mobile-architecture-scaffold-phase-initialization
sources:
- stdin
- manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
timestamp: 2026-07-15T17:44:48.948492+00:00
created_at: 2026-07-15T17:44:48.948492+00:00
updated_at: 2026-07-15T17:44:48.948492+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T17:40:00Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `analyzing` with 4 research agents running

This record continues the scaffold assessment flow after [Hybrid scaffold assessment receives testing policy research](/hybrid-scaffold-assessment-receives-testing-policy-research.md) and remains within the phase initialized in [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md).

## Phase goals

- Create a new full instance of the hybrid mobile architecture:
  - Flutter mobile application layer
  - Rust FFI integration layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run scaffolding scripts to generate a complete working project from the reference library.
- Verify all generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment meets minimum tool version requirements.

## Active research agents

Four analysis agents are running in parallel:

1. **`prometheus-entity-management`**
   - Package structure
   - React `3.0.0-alpha.0` API
   - v4 sync design
   - Flutter/Riverpod 3 equivalent design sketch
2. **`flint-gate` / `flint-realtime-fabric` / `flint-forge`**
   - Component definitions
   - Integration surfaces
   - Hybrid client connection model
3. **PGlite / `pglite-oxide` / local-first / migrations**
   - Web and native embedded Postgres
   - `pgvector` RAG
   - Startup migration patterns
   - Seed-distribution patterns by platform
4. **SurrealDB 3.2 embedded graph RAG + Riverpod 3.x**
   - Version verification
   - WASM/native backend options
   - Hybrid vector + graph query patterns
   - Riverpod 2-to-3 migration implications

## Gathered context

Both KnowMe IPFS documents have been read:

- Functional specification
- Moodboard and user journeys

The example app target is now defined as a **sovereign personal AI** application with:

- Eight capability tiles
- On-device inference
- SurrealDB-backed memory
- Cedar-governed agents
- OFP-style sync
- WASM plugins
- Common behavior across desktop, mobile, and web

## Repository state

All four Prometheus repositories were pulled and were already current, with two notable local-state details:

- `flint-realtime-fabric`: local `main` was updated without touching its in-progress feature branch.
- `flint-forge`: local branch is 14 commits ahead of origin; local work is not yet pushed and there was nothing to pull.

## Pending deliverables

After the four agents report back, produce:

- `analysis.md`
- `library-candidates.json`
- `decision-log.md`
- Analysis handoff

Then proceed to `/kbd-plan`.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project