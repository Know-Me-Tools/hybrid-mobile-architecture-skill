<!-- source=primary; branch=main-pre-consolidation; original_sha256=873dc656a4efedc27479a8f3a6b78b33fbb6a81a141e8de807ce1bb917dc0ec4 -->
---
type: Reference
id: hybrid-scaffold-analysis-completes-with-mobile-sqlite-decision
title: Hybrid scaffold analysis completes with mobile SQLite decision
tags:
- hybrid-mobile-architecture
- scaffolding
- sqlite
- pglite-oxide
- surrealdb
- rust-ffi
- riverpod
- flint
links:
- hybrid-mobile-architecture-scaffold-phase-initialization
- hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings
sources:
- stdin
- manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
- .kbd-orchestrator/phases/scaffold-full-hybrid-project/analysis.md
- .kbd-orchestrator/phases/scaffold-full-hybrid-project/library-candidates.json
- docs/pglite-oxide-tauri-hybrid.md
timestamp: 2026-07-15T18:09:42.508558+00:00
created_at: 2026-07-15T18:09:42.508558+00:00
updated_at: 2026-07-15T18:09:42.508558+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T17:55:12Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `analysis_complete`

This record completes the scaffold analysis flow that began with [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md) and continued through assessment and research updates such as [Hybrid scaffold analysis integrates PEM and PES sync findings](/hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings.md).

## Phase goals

- Create a new full instance of the hybrid mobile architecture:
  - Flutter mobile layer
  - Rust FFI layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run scaffolding scripts from the reference library to generate a complete working project.
- Verify generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment satisfies minimum tool version requirements.

## Analysis outputs

- Full narrative: `.kbd-orchestrator/phases/scaffold-full-hybrid-project/analysis.md`
- Machine contract: `.kbd-orchestrator/phases/scaffold-full-hybrid-project/library-candidates.json`
- Both KnowMe IPFS documents were fetched and define the target product as a sovereign personal AI app with:
  - On-device inference
  - SurrealDB knowledge graphs
  - Cedar-governed agents
  - Peer sync
  - Common behavior across supported platforms

## Database and storage correction

A critical correction was recorded as **C-9**: the repository document `docs/pglite-oxide-tauri-hybrid.md` is wrong on two counts:

1. `pglite-oxide` is PGlite's WASI build running inside a WASM runtime, not a native binary.
2. `pglite-oxide` has no iOS or Android support.

Mobile relational and vector storage is therefore **SQLite + sqlite-vec in the Rust core**. iOS structurally cannot run Postgres in this architecture.

## Adopted per-platform data matrix

| Capability | Web | Desktop | Mobile |
|---|---|---|---|
| Relational | PGlite `0.5.4` | pglite-oxide `0.5.1` | SQLite via `sqlx` |
| Vector RAG | pgvector, HNSW in WASM | pgvector | sqlite-vec |
| Graph RAG | SurrealDB 3.2 `kv-indxdb` | SurrealDB 3.2 `kv-rocksdb` | SurrealDB 3.2 `kv-rocksdb` |
| Sync read | pglite-sync shapes | Rust Electric consumer | Rust Electric consumer |

## Decisions recorded

- **Write-path sync:** implement a DIY write queue via `flint-forge` with PES-compatible trait seams.
- **Example scope:** build a vertical slice covering:
  - Chat
  - Entity CRUD
  - Memory/graph RAG
  - Sync status
- **React entity management:** adopt PEM `3.0.0-alpha.0`.
  - Must remain shadcn-token-compatible.
  - Wire transports to forge Quarry and tenant-scoped Electric.
- **Flutter entity management:** build `prometheus_entity_management`.
  - Canonical store lives in Rust.
  - Riverpod 3 provider families act as the normalization map.
- **Riverpod:** use Riverpod `3.3.2`.
  - Automatic retry is enabled by default.
  - FFI providers need explicit retry opt-outs where retry would be unsafe.
- **Flint integration:** all Flint integration lives inside `gen_ui_core`.
  - Native uses `frf-sdk-rust`.
  - Browser uses `frf-wasm`.
  - Forge endpoint `/mcp/v1/a2ui` registers directly into the MCP client.
- **Flint dependencies:** all Flint dependencies are unpublished and must be pinned as git dependencies to specific SHAs.

## Repository state

- Requested repositories were pulled.
- All repositories were already current except `flint-realtime-fabric`.
- `flint-realtime-fabric` local `main` was fast-forwarded.
- The in-progress feature branch in `flint-realtime-fabric` was not modified.

## New plan inputs

Three changes were added to the plan input set:

- **C-9:** Correct `pglite-oxide` documentation and mobile database assumptions.
- **C-10:** Define startup orchestration per platform: migrations → seeds → shapes.
- **C-11:** Add Flint integration layer.

## Next action

Run `/kbd-plan scaffold-full-hybrid-project` to convert **C-1…C-11** into an executable, worktree-parallel plan.

Planning constraints:

- Perform **C-1 workspace split first**.
- Schedule the `wasm32` validation spike early.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
3. .kbd-orchestrator/phases/scaffold-full-hybrid-project/analysis.md
4. .kbd-orchestrator/phases/scaffold-full-hybrid-project/library-candidates.json
5. docs/pglite-oxide-tauri-hybrid.md