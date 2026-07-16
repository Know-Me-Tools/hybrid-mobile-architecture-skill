---
type: Reference
id: frf-versus-electricsql-decision-point-for-knowme-poc-sync
title: FRF versus ElectricSQL decision point for KnowMe PoC sync
tags:
- hybrid-mobile-architecture
- knowme-poc
- frf
- electricsql
- cdc
- local-first-sync
- ci-verification
links:
- knowme-poc-codegen-and-ci-verification-phase-goals
- knowme-poc-phase-goals-and-c-105-research-wait-state
sources:
- stdin
- manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification
timestamp: 2026-07-16T18:16:32.128968+00:00
created_at: 2026-07-16T18:16:32.128968+00:00
updated_at: 2026-07-16T18:16:32.128968+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture
- **Phase:** `phase-codegen-and-ci-verification`
- **KBD root:** `~/Projects/hybrid-mobile-architecture-src/.claude/worktrees/pensive-greider-2e206c`
- **Captured:** `2026-07-16T18:14:51Z`
- **Position:** `phase-codegen-and-ci-verification`
- **Status:** `executing`

This session continues the PoC-first phase direction captured in [KnowMe PoC codegen and CI verification phase goals](/knowme-poc-codegen-and-ci-verification-phase-goals.md) and [KnowMe PoC phase goals and C-105 research wait state](/knowme-poc-phase-goals-and-c-105-research-wait-state.md).

## Revised phase goal

The phase end result is a **working proof-of-concept app** in `apps/<name>/`, not merely pipeline verification. The PoC is based on KnowMe reference documentation in `docs/reference-app/` and must prove the skill package end-to-end while showcasing the broadest practical range of supported capabilities:

- Streaming `ContentBlock` chat
- PEM entity management
- SurrealDB graph-RAG memory
- Local-first sync
- Cross-platform Flutter, Tauri, and web surfaces from one Rust core

Supporting verification remains in scope:

- Run real code generation on the PoC:
  - `flutter_rust_bridge_codegen generate`
  - `dart run build_runner build`
  - `flutter pub get`
  - `pnpm install`
- Confirm pre-codegen warnings clear once generated code and sibling packages exist.
- Resolve or work around the PEM install blocker: `@prometheus-ags/entity-graph-core@workspace:*` is not resolvable outside the PEM monorepo.
- Verify the PoC builds/runs on at least one target per surface:
  - macOS Tauri desktop
  - iOS simulator or Android emulator for Flutter
- Wire CI to run:
  - `cargo clippy --workspace`
  - `audit.sh all`
  - boundary test suites against the PoC on every push

## Finding: FRF has no ElectricSQL integration

A fresh FRF tree inspection found **zero ElectricSQL references**:

- Checked repo state: `9ba04ae`
- Checked `origin/main`: `d263ede`
- Search result: `grep -rli 'electric'` returned no files across code, docs, compose, or proto definitions.

The absence is architecturally significant. `frf-postgres-cdc` already opens a PostgreSQL logical replication slot, reads `pgoutput` directly through `tokio-postgres`, and publishes decoded rows to the Iggy spine. ElectricSQL consumes the same PostgreSQL WAL/logical replication mechanism.

Implication: **FRF and ElectricSQL are alternative CDC implementations, not stackable layers by default.** Adding ElectricSQL to FRF would introduce one of two architectures:

1. A second CDC path racing FRF's native CDC for replication slots/WAL consumption.
2. ElectricSQL as an upstream source feeding a spine that already has a native PostgreSQL source.

Therefore, “add ElectricSQL support to FRF” is an architecture decision, not a simple wiring task.

## Decision options surfaced

### Option 1: Keep FRF sovereign and drop Electric from the PoC

Recommended path.

Use FRF directly for the PoC sync path and remove ElectricSQL from the local infrastructure stack.

Relevant existing assets:

- `gen_ui_client/src/flint/frf.rs` already exists as a thin façade over `frf-sdk-rust`.
- The façade is documented as verified against FRF HEAD.
- The dependency is currently stubbed:
  - feature: `frf = []`
  - dependency commented out
- The target FRF revision is pinned at `9ba04ae`, matching the pulled HEAD.

Implementation direction:

- Implement the C-106 `SyncTransport` seam with an FRF-backed transport.
- Map `EntityService::WatchEntity` into `LocalStore` updates.
- Publish through the FRF spine into the `WriteSink` path.
- Remove ElectricSQL from compose/infrastructure for this PoC path.
- Update C-106 tasks and the decision log.

Rationale:

- Avoids redundant CDC dependencies.
- Uses FRF’s native replication path instead of introducing a competing WAL consumer.
- Matches the existing `SyncTransport` seam and pinned FRF revision.
- Requires less code than adding a second ingest mode to FRF.

### Option 2: Add ElectricSQL as an optional FRF ingest source

Treat ElectricSQL as a separate FRF feature behind `frf-ports`, gated off by default.

This requires a dedicated FRF design phase because it changes source topology and CDC ownership. It should not be assumed as part of the current PoC wiring task.

## FRF phase-gate constraint

FRF’s `CLAUDE.md` requires halting at each phase boundary for explicit approval and forbids producing artifacts belonging to a future phase.

Current FRF state:

- Branch: `sovereign-sfu-decode-proof`
- Position: mid-`phase-36`
- Branch is 14 commits ahead of `main`.
- FRF signoff docs show the sovereign SFU gate intentionally held **OFF** across phases 16–35.
- Reason: no receiver has observed a decoded frame; `framesDecoded=0`.

The gate state is an honesty/process discipline, not a trivial bug. Closing FRF’s outstanding feature/task list would require either:

- finishing a WebRTC decode investigation that prior phases have not resolved, or
- flipping a gate that FRF’s own process forbids flipping without evidence.

Neither should be done unilaterally, and neither is required for the Hybrid Mobile Architecture PoC.

Reusable FRF learnings for the PoC:

- CDC/replication pattern
- `SyncTransport`-shaped seam
- phase-gate discipline

## Requested user decision

Execution is blocked pending selection among these paths:

- **A — Assess FRF phase-36 outstanding work**: read-only report of what remains; no gate changes.
- **B — Implement FRF-backed PoC sync**: wire C-106 `SyncTransport` to FRF, drop Electric from infrastructure, update C-106 tasks and decision log.
- **C — Propose Electric-as-second-ingest for FRF**: design a new FRF phase proposal; no code.

Recommendation: **B**.

## PR #4 conflict resolution

PR #4 conflicts are limited to append-only `.prometheus` logs. A `.gitattributes` union-merge fix is staged in the worktree to resolve these conflicts permanently. This fix can be landed independently of the FRF/ElectricSQL decision.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture/phase-codegen-and-ci-verification