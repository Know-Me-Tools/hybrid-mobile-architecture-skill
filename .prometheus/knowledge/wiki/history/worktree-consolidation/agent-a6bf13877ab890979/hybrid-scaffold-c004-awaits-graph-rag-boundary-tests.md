<!-- source=agent-a6bf13877ab890979; branch=worktree-agent-a6bf13877ab890979; original_sha256=1679f73cf0a3984090d59923e4e6245a7642cd8138fa714856d93cd188091b90 -->
---
type: Reference
id: hybrid-scaffold-c004-awaits-graph-rag-boundary-tests
title: Hybrid scaffold c004 awaits graph RAG boundary tests
tags:
- hybrid-mobile-architecture
- scaffolding
- graph-rag-store
- rust-clippy
- surrealdb
- boundary-tests
- msrv
links:
- hybrid-scaffold-c004-gating-on-graph-rag-store-clippy-and-tests
- hybrid-mobile-architecture-scaffold-phase-initialization
sources:
- stdin
- manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
timestamp: 2026-07-15T19:33:35.427726+00:00
created_at: 2026-07-15T19:33:35.427726+00:00
updated_at: 2026-07-15T19:33:35.427726+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD worktree:** `$REPO_ROOT/.kbd-orchestrator/dispatch/worktrees/2026-07-15-c004-graph-rag-store`
- **Captured:** `2026-07-15T19:30:29Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `executing`
- **Current lane/change:** `c004` graph RAG store

This continues the c004 graph RAG store gating flow after [Hybrid scaffold c004 gating on graph RAG store clippy and tests](/hybrid-scaffold-c004-gating-on-graph-rag-store-clippy-and-tests.md), within the phase initialized in [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md).

## Phase goals

- Create a new full instance of the hybrid mobile architecture:
  - Flutter mobile application layer
  - Rust FFI integration layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run scaffolding scripts to generate a complete working project from the reference library.
- Verify all generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment meets minimum tool version requirements.

## Current status

- `c004` graph RAG store implementation is in execution/gating.
- `cargo clippy` for `c004` is **clean**.
- Boundary tests for `gen_ui_db_graph` are running.
- The boundary-test build is recompiling SurrealDB with the `kv-mem` feature.

## Next actions

1. Await the `gen_ui_db_graph` boundary-test build and run.
2. If the 4 boundary tests pass:
   - write the completion log;
   - stop the phase work for this lane.
3. If any boundary test fails:
   - diagnose the failure;
   - respect the `CLAUDE.md` two-attempt cap;
   - after the cap, stop and report rather than continuing indefinitely.

## Known deviation to document

The completion log must document the SurrealDB version/MSRV deviation:

- SurrealDB `3.2` requires **MSRV >= 1.94**.
- This deviates from the expected minimum tool-version baseline for the scaffold phase and must be explicitly recorded in the completion evidence.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project