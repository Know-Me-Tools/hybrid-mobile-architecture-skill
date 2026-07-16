---
type: Reference
id: hybrid-scaffold-c004-gating-on-graph-rag-store-clippy-and-tests
title: Hybrid scaffold c004 gating on graph RAG store clippy and tests
tags:
- hybrid-mobile-architecture
- scaffolding
- graph-rag-store
- rust-clippy
- surrealdb
- msrv
- kbd-orchestrator
links:
- hybrid-scaffold-execution-status-with-c-001-merged-and-lanes-running
- hybrid-mobile-architecture-scaffold-phase-initialization
sources:
- stdin
- manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
timestamp: 2026-07-15T19:25:20.549546+00:00
created_at: 2026-07-15T19:25:20.549546+00:00
updated_at: 2026-07-15T19:25:20.549546+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD worktree:** `~/Projects/hybrid-mobile-architecture-src/.kbd-orchestrator/dispatch/worktrees/2026-07-15-c004-graph-rag-store`
- **Captured:** `2026-07-15T19:23:16Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `executing`
- **Current lane/change:** `c004` graph RAG store implementation written; gating in progress

This continues the execution flow after [Hybrid scaffold execution status with C-001 merged and lanes running](/hybrid-scaffold-execution-status-with-c-001-merged-and-lanes-running.md), within the phase initialized in [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md).

## Phase goals

- Create a new full instance of the hybrid mobile architecture:
  - Flutter mobile application layer
  - Rust FFI integration layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run scaffolding scripts to generate a complete working project from the reference library.
- Verify all generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment meets minimum tool version requirements.

## Current gating state

- `c004` code has been written for the graph RAG store lane.
- Gating is blocked on completion of a heavy Rust lint build:

```bash
cargo +1.95 clippy
```

- The compile is expected to be expensive because it includes dependencies such as:
  - `surrealdb`
  - `ort`
- The relevant generated crate is `gen_ui_db_graph`.

## Required next steps

1. Wait for `cargo +1.95 clippy` to complete for `gen_ui_db_graph`.
2. Verify clippy output is clean.
3. Regenerate the crate with the fixed `graph_expand` traversal.
4. Run the 4 boundary tests.
5. Write the completion log.
6. Document the SurrealDB 3.2-driven MSRV deviation for `C-001`/`C-008` sign-off.

## MSRV note

SurrealDB 3.2 requires a minimum Rust version at or above `1.94`, creating a documented deviation that must be called out for `C-001`/`C-008` sign-off. The active gate uses Rust `1.95` via `cargo +1.95 clippy`.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project