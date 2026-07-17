<!-- source=agent-a6bf13877ab890979; branch=worktree-agent-a6bf13877ab890979; original_sha256=a427f7273472342ccd9a00a3e4ab6d141cfdb3cd24549b43dab77e2b06b5c972 -->
---
type: Reference
id: hybrid-scaffold-analysis-corrects-pglite-oxide-mobile-claims
title: Hybrid scaffold analysis corrects pglite-oxide mobile claims
tags:
- hybrid-mobile-architecture
- pglite-oxide
- local-first
- sqlite
- surrealdb
- tauri
- rust-ffi
- scaffolding
links:
- hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings
- hybrid-mobile-architecture-scaffold-phase-initialization
- hybrid-mobile-scaffold-phase-assessment-readiness
- hybrid-scaffold-assessment-waits-on-remaining-research-agents
- hybrid-scaffold-assessment-receives-testing-policy-research
sources:
- stdin
- manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
timestamp: 2026-07-15T17:55:32.402120+00:00
created_at: 2026-07-15T17:55:32.402120+00:00
updated_at: 2026-07-15T17:55:32.402120+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-15T17:50:46Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `analyzing`
- **Research progress:** 3.5 of 4 agents complete; final SurrealDB 3.2 + Riverpod 3 agent still pending

This record continues the scaffold assessment flow after [Hybrid scaffold analysis integrates PEM and PES sync findings](/hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings.md), within the phase initialized by [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md). It remains part of the full hybrid architecture scaffolding track previously advanced through [Hybrid Mobile scaffold phase assessment readiness](/hybrid-mobile-scaffold-phase-assessment-readiness.md), [Hybrid scaffold assessment waits on remaining research agents](/hybrid-scaffold-assessment-waits-on-remaining-research-agents.md), and [Hybrid scaffold assessment receives testing policy research](/hybrid-scaffold-assessment-receives-testing-policy-research.md).

## Phase goals

- Create a new full instance of the hybrid mobile architecture:
  - Flutter mobile application layer
  - Rust FFI integration layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run scaffolding scripts to generate a complete working project from the reference library.
- Verify generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment meets minimum tool version requirements.

## pglite-oxide documentation correction

The pglite/local-first research report identified incorrect claims in `docs/pglite-oxide-tauri-hybrid.md`:

- The document claims `pglite-oxide` is a "real PostgreSQL binary, not WASM".
- The document claims iOS/Android support.

Verification against crates.io/docs.rs for the published `pglite-oxide` crate version `0.5.1` contradicts both claims:

- `pglite-oxide` runs PGlite's WASI build inside a WASM runtime.
- The crate ships AOT assets for desktop only:
  - Linux
  - macOS arm64
  - Windows
- It does **not** provide validated mobile support for iOS or Android.

## Mobile database implication

Stock PostgreSQL is structurally unsuitable for direct iOS embedding because iOS disallows required runtime behavior such as `fork` and JIT-style execution. The mobile-compatible local persistence options identified for this architecture are:

- SQLite via the Rust core.
- `sqlite-vec` for vector search needs on SQLite.
- Embedded SurrealDB via the Rust core, pending final SurrealDB 3.2 research.

The successor project `Oliphaunt` claims future mobile support, but it is pre-release and should not be treated as a scaffold dependency for the current phase.

## Sync-spine recommendation

Recommended local-first synchronization direction:

- Use Electric shapes for the read path.
- Route writes through the application's own API.
- Consider PowerSync if a purchased bidirectional sync pipeline is preferred.

This direction aligns with PEM v4 planning to build `prometheus-entity-sync` in Rust, as noted in [Hybrid scaffold analysis integrates PEM and PES sync findings](/hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings.md).

## Pending work

After the final SurrealDB 3.2 + Riverpod 3 agent report is received, produce:

- `analysis.md`
- `library-candidates.json`
- `decision-log.md`
- Handoff notes
- A documentation correction item for `docs/pglite-oxide-tauri-hybrid.md`

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project