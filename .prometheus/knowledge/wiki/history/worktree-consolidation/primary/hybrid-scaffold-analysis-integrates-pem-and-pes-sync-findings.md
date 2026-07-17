<!-- source=primary; branch=main-pre-consolidation; original_sha256=d372a34837ccfe1a842b7634a295c01b1755aed4bf32d601260f1ac6b7882f24 -->
---
type: Reference
id: hybrid-scaffold-analysis-integrates-pem-and-pes-sync-findings
title: Hybrid scaffold analysis integrates PEM and PES sync findings
tags:
- hybrid-mobile-architecture
- scaffolding
- entity-management
- prometheus-entity-sync
- rust-ffi
- tauri
- riverpod
- local-first
links:
- hybrid-scaffold-analysis-integrates-flint-platform-report
- hybrid-mobile-architecture-scaffold-phase-initialization
- hybrid-mobile-scaffold-phase-assessment-readiness
- hybrid-scaffold-assessment-waits-on-remaining-research-agents
- hybrid-scaffold-assessment-receives-testing-policy-research
sources:
- stdin
- manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project
timestamp: 2026-07-15T17:51:02.459839+00:00
created_at: 2026-07-15T17:51:02.459839+00:00
updated_at: 2026-07-15T17:51:02.459839+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `scaffold-full-hybrid-project`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src`
- **Captured:** `2026-07-15T17:45:08Z`
- **Position:** `scaffold-full-hybrid-project`
- **Status:** `analyzing`
- **Research progress:** 3 of 4 analysis agents complete

This record continues the scaffold assessment and research flow after [Hybrid scaffold analysis integrates Flint platform report](/hybrid-scaffold-analysis-integrates-flint-platform-report.md), within the phase initialized by [Hybrid Mobile Architecture Scaffold Phase Initialization](/hybrid-mobile-architecture-scaffold-phase-initialization.md). It updates the status from the earlier assessment records, including [Hybrid Mobile scaffold phase assessment readiness](/hybrid-mobile-scaffold-phase-assessment-readiness.md), [Hybrid scaffold assessment waits on remaining research agents](/hybrid-scaffold-assessment-waits-on-remaining-research-agents.md), and [Hybrid scaffold assessment receives testing policy research](/hybrid-scaffold-assessment-receives-testing-policy-research.md).

## Phase goals

- Create a new full instance of the hybrid mobile architecture:
  - Flutter mobile application layer
  - Rust FFI integration layer
  - Tauri shell/runtime integration
  - React 19 frontend surface
- Run scaffolding scripts to generate a complete working project from the reference library.
- Verify all generated artifacts conform to `TJ-ARCH-MOB-001`.
- Confirm the environment meets minimum tool version requirements.

## Entity-management research finding

The entity-management report identified **PEM** as a significant alignment candidate for the scaffolded architecture:

- PEM is a full normalized entity-graph monorepo.
- Current version noted: `3.0.0-alpha.0`.
- Existing adapters already include:
  - PGlite
  - ElectricSQL
  - Tauri
- PEM includes a Flutter/Riverpod mapping sketch:
  - Rust is treated as the canonical store.
  - Provider families act as the normalization map.

## Sync architecture implication

The report found that **v4 `prometheus-entity-sync` (PES)** already specifies a Rust-native bidirectional sync engine:

- Reuses FRF's CDC crate.
- Treats Dart/SQLite as a first-class client target.
- Treats `pglite-oxide` clients as first-class targets.

This aligns the example application's sync story with already-planned ecosystem work rather than requiring a bespoke sync design during scaffolding.

## Remaining research

Two analysis agents remain open:

- PGlite/local-first platform matrix.
- SurrealDB 3.2 + Riverpod 3.

## Next actions

- Collect the final agent report.
- Write `analysis.md`.
- Write `library-candidates.json`.
- Write `decision-log.md`.
- Prepare handoff.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/scaffold-full-hybrid-project