---
type: Reference
id: c-001-freezes-gen-ui-types-seams-for-hybrid-mobile-scaffold
title: C-001 freezes gen_ui_types seams for hybrid mobile scaffold
tags:
- hybrid-mobile-architecture
- scaffolding
- rust-workspace
- wasm
- gen-ui-types
- rust-ffi
- tauri
- react-19
links:
- hybrid-mobile-architecture-scaffold-phase-initialization
- hybrid-mobile-scaffold-phase-assessment-readiness
- hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings
sources:
- stdin
- manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
timestamp: 2026-07-15T19:09:35.712853+00:00
created_at: 2026-07-15T19:09:35.712853+00:00
updated_at: 2026-07-15T19:09:35.712853+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T18:57:37Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `executing`
- **Progress:** `1/12 done`
- **Committed baseline:** `88d2eb4` on `main`

This record advances the scaffold execution that began in [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md) and follows the earlier assessment/readiness flow, including [Hybrid Mobile scaffold phase assessment readiness](/hybrid-mobile-scaffold-phase-assessment-readiness.md) and [Hybrid scaffold analysis integrates PEM and PES sync findings](/hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings.md).

## Phase goals

- Create a complete hybrid mobile architecture instance:
  - Flutter mobile layer
  - Rust FFI layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run reference-library scaffolding scripts to generate a working project.
- Verify generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment satisfies minimum tool version requirements.

## Completed: C-001 layered workspace

C-001 is complete, verified, and committed to `main` at `88d2eb4`.

The scaffold now emits a **12-crate layered Rust workspace**. The `gen_ui_types` crate sits at **L0** and owns the cross-crate trait seams needed by later lanes. These seams are frozen and available for Wave 1 branches.

## Verification results

The check-first gate validated the architecture through compiler/tooling checks rather than assertion:

- `cargo metadata` accepts all 12 workspace crates.
- Native `clippy -D warnings` is clean on the three seam crates.
- `gen_ui_types` and `gen_ui_protocol` compile for `wasm32-unknown-unknown`.

The wasm compile result demonstrates that the core seam/protocol layer can run in web-compatible targets.

## Findings fixed during C-001

Compiler-first validation caught three ecosystem issues that were not knowable from the initial plan:

1. **Rust MSRV changed from 1.80 to 1.93 for the current dependency graph**
   - The pinned Rust 1.80 toolchain can no longer resolve current dependencies.
   - Cause: `chacha20 >=0.10` requires Cargo support for the `edition2024` feature.
   - Follow-up assigned to **C-008**: update `CLAUDE.md` / `AGENTS.md` required tool version tables, which still state Rust `1.80+`.

2. **`uuid` on wasm requires JS entropy support**
   - wasm builds need `uuid` configured with `features = ["js"]` plus `getrandom` JS support.
   - Fixed with a wasm-gated dependency configuration.

3. **Old scaffold used incompatible `panic = "abort"`**
   - The previous scaffold setting was frb-breaking.
   - Corrected to `panic = "unwind"`.

## Active background lanes

- **C-008**: documentation corrections, running under Kimi K2.6 in an isolated worktree.
- **C-009**: project skills / scaffold script edits, running under Claude Sonnet 5 in an isolated worktree.

Neither C-008 nor C-009 had posted a done-marker at capture time.

## Next execution step

Wave 1 code lanes are unblocked because C-001 seams are committed and frozen. Planned fan-out from `88d2eb4`:

- **C-002**: wasm spike
- **C-003**: relational layer
- **C-004**: graph-RAG layer
- **C-005**: sync layer
- **C-006**: Flint integration
- **C-007**: leaves

Each lane should run in its assigned harness/worktree and pass QA gates as it completes. C-008/C-009 outputs should be collected and reviewed with the first batch when done.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project

## Consolidated source variants

### Variant from `agent-a6bf13877ab890979`

Original path: `.prometheus/knowledge/wiki/c-001-freezes-gen-ui-types-seams-for-hybrid-mobile-scaffold.md`  
Original SHA-256: `7c086929123850ab8192767edf9c937f4c9dd1e79a51cc75bcec715c0f6d4149`

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD root:** `$REPO_ROOT`
- **Captured:** `2026-07-15T18:57:37Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `executing`
- **Progress:** `1/12 done`
- **Committed baseline:** `88d2eb4` on `main`

This record advances the scaffold execution that began in [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md) and follows the earlier assessment/readiness flow, including [Hybrid Mobile scaffold phase assessment readiness](/hybrid-mobile-scaffold-phase-assessment-readiness.md) and [Hybrid scaffold analysis integrates PEM and PES sync findings](/hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings.md).

## Phase goals

- Create a complete hybrid mobile architecture instance:
  - Flutter mobile layer
  - Rust FFI layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run reference-library scaffolding scripts to generate a working project.
- Verify generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment satisfies minimum tool version requirements.

## Completed: C-001 layered workspace

C-001 is complete, verified, and committed to `main` at `88d2eb4`.

The scaffold now emits a **12-crate layered Rust workspace**. The `gen_ui_types` crate sits at **L0** and owns the cross-crate trait seams needed by later lanes. These seams are frozen and available for Wave 1 branches.

## Verification results

The check-first gate validated the architecture through compiler/tooling checks rather than assertion:

- `cargo metadata` accepts all 12 workspace crates.
- Native `clippy -D warnings` is clean on the three seam crates.
- `gen_ui_types` and `gen_ui_protocol` compile for `wasm32-unknown-unknown`.

The wasm compile result demonstrates that the core seam/protocol layer can run in web-compatible targets.

## Findings fixed during C-001

Compiler-first validation caught three ecosystem issues that were not knowable from the initial plan:

1. **Rust MSRV changed from 1.80 to 1.93 for the current dependency graph**
   - The pinned Rust 1.80 toolchain can no longer resolve current dependencies.
   - Cause: `chacha20 >=0.10` requires Cargo support for the `edition2024` feature.
   - Follow-up assigned to **C-008**: update `CLAUDE.md` / `AGENTS.md` required tool version tables, which still state Rust `1.80+`.

2. **`uuid` on wasm requires JS entropy support**
   - wasm builds need `uuid` configured with `features = ["js"]` plus `getrandom` JS support.
   - Fixed with a wasm-gated dependency configuration.

3. **Old scaffold used incompatible `panic = "abort"`**
   - The previous scaffold setting was frb-breaking.
   - Corrected to `panic = "unwind"`.

## Active background lanes

- **C-008**: documentation corrections, running under Kimi K2.6 in an isolated worktree.
- **C-009**: project skills / scaffold script edits, running under Claude Sonnet 5 in an isolated worktree.

Neither C-008 nor C-009 had posted a done-marker at capture time.

## Next execution step

Wave 1 code lanes are unblocked because C-001 seams are committed and frozen. Planned fan-out from `88d2eb4`:

- **C-002**: wasm spike
- **C-003**: relational layer
- **C-004**: graph-RAG layer
- **C-005**: sync layer
- **C-006**: Flint integration
- **C-007**: leaves

Each lane should run in its assigned harness/worktree and pass QA gates as it completes. C-008/C-009 outputs should be collected and reviewed with the first batch when done.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
