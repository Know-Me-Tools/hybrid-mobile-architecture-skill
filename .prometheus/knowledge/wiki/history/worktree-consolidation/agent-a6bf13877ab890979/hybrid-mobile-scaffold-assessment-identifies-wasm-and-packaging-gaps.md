<!-- source=agent-a6bf13877ab890979; branch=worktree-agent-a6bf13877ab890979; original_sha256=3aa6c650033b5f5965702f9dab1d22dbb4689af8211fdc33f36c6c145e60562b -->
---
type: Reference
id: hybrid-mobile-scaffold-assessment-identifies-wasm-and-packaging-gaps
title: Hybrid Mobile scaffold assessment identifies WASM and packaging gaps
tags:
- hybrid-mobile-architecture
- scaffolding
- wasm
- rust-ffi
- compile-speed
- tauri
- testing-philosophy
links:
- hybrid-mobile-scaffold-phase-assessment-readiness
- hybrid-mobile-architecture-scaffold-phase-initialization
- hybrid-mobile-scaffold-phase-executor-completion
- hybrid-scaffold-executor-completed-with-unknown-change
sources:
- stdin
timestamp: 2026-07-15T17:16:26.833434+00:00
created_at: 2026-07-15T17:16:26.833434+00:00
updated_at: 2026-07-15T17:16:26.833434+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-15T17:12:41Z`
- **Source:** `manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `assessing` with research agents running

This record continues the scaffold phase tracked in [Hybrid Mobile scaffold phase assessment readiness](/hybrid-mobile-scaffold-phase-assessment-readiness.md) and follows the earlier scaffold initialization in [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md).

## Phase goals

- Create a new complete instance of the hybrid mobile architecture:
  - Flutter mobile layer
  - Rust FFI integration
  - Tauri runtime/shell integration
  - React 19 frontend surface
- Run scaffolding scripts from the reference library to generate a working project.
- Verify generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment meets minimum tool version requirements.

## Inspection findings

Codebase inspection completed before research-agent results were merged. Current gaps against the phase goal:

1. **No WASM strategy**
   - Scaffolded `gen_ui_core` cannot compile to `wasm32`.
   - Blocking dependencies/features include:
     - `tokio` with `features = ["full"]`
     - SurrealDB `kv-rocksdb`
     - Candle Metal/Accelerate support
     - native `reqwest`
   - The crate is monolithic, preventing target-specific salvage without splitting the crate.

2. **No compile-speed engineering**
   - Scaffold emits only `[profile.release]`.
   - Missing development-build optimization patterns:
     - dev profile tuning
     - Cranelift
     - `.cargo/config.toml`
     - fast linker configuration
     - `sccache`
     - check-first workflow

3. **Monolithic crate limits build and workflow scalability**
   - A single crate creates one codegen-unit chain and serializes incremental builds.
   - The same monolith increases merge conflicts across concurrent worktrees.

4. **No publishing surface**
   - Generated architecture is scaffold-inline only.
   - Missing extraction or packaging plan for:
     - Flutter package/plugin
     - NPM package
     - reusable Tauri plugin

5. **Testing guidance conflicts with desired philosophy**
   - Existing testing references push `mockall`/`proptest`-heavy unit testing.
   - This conflicts with the new features-first testing philosophy.
   - `CLAUDE.md` and `AGENTS.md` need explicit override sections.

## Pending research integration

Assessment writing is blocked until research-agent findings are merged for:

- compile-speed configuration
- testing-philosophy evidence
- UI/UX skills landscape

## Next actions

- Merge research-agent outputs into `assessment.md`.
- Update `CLAUDE.md` and `AGENTS.md` with philosophy sections, especially testing guidance.
- Mark `assessment_complete` after the above updates.
- Reconcile this assessment with prior executor completion records whose artifact changes were unknown: [Hybrid Mobile scaffold phase executor completion](/hybrid-mobile-scaffold-phase-executor-completion.md) and [Hybrid scaffold executor completed with unknown change](/hybrid-scaffold-executor-completed-with-unknown-change.md).

# Citations

1. stdin