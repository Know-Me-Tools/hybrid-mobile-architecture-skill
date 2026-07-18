---
type: Reference
id: local-first-sync-assessment-finds-unused-crdt-and-pglite-sync-deps
title: Local-first sync assessment finds unused CRDT and PGlite sync deps
tags:
- local-first
- realtime-sync
- crdt
- pglite
- webrtc
- prometheus-entity-management
- hybrid-mobile-architecture
links:
- local-first-realtime-sync-assessment-ready-at-09-16-56
- local-first-realtime-sync-assessment-ready-at-09-10-25
sources:
- stdin
timestamp: 2026-07-18T09:29:25.627256+00:00
created_at: 2026-07-18T09:29:25.627256+00:00
updated_at: 2026-07-18T09:29:25.627256+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture Skill
- **Phase:** `local-first-realtime-sync`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src/.claude/worktrees/local-first-realtime-sync-965f0c`
- **Captured:** `2026-07-18T09:16:57Z`
- **Status:** `assessment_in_progress`
- **Position:** `local-first-realtime-sync`

This assessment continues the local-first realtime sync phase after prior no-change assessment-ready records, including [Local-first realtime sync assessment ready at 09:16:56](/local-first-realtime-sync-assessment-ready-at-09-16-56.md) and [Local-first realtime sync assessment ready at 09:10:25](/local-first-realtime-sync-assessment-ready-at-09-10-25.md).

## Phase goals

Assess `docs/knowme-local-first-realtime-master-plan.md` and all notes under `docs/research/` to determine how to add skills supporting local-first, realtime, and sync strategies for `TJ-ARCH-MOB-001` apps, then add that behavior to the apps.

Required architecture targets:

- **Partial replication, not full mirroring:** local stores should hold only data the user needs, is authorized for, or is interested in, plus application-wide lookup/metatype data that changes over time and must stay synced.
- **AI chat local-first:** conversation threads stored client-side, with a client-side vector database for vector search and client-side RAG with agents.
- **Client-side agent storage:** local storage and management for agent data.
- **Sensitive personal data local-only:** user profile and sensitive personal data stored client-side only, synced device-to-device across the user's devices/browser instances via WebRTC or other peer connections with CRDT convergence.
- **Inference privacy boundary:** client-side agents may perform momentary inference against safe cloud servers or local LLMs, but sensitive personal data must never be persisted server-side.
- **One-time server data loads:** some data loads before onboarding, then again after onboarding once preferences or personal data are provided.
- **Reference code:** provide working examples for every scenario using Prometheus Entity Management (PEM) with PGlite as the entity-layer replacement for TanStack Query, because TanStack Query is considered the wrong client layer for this data.

## Spot-check findings

- `loro-crdt` is installed but entirely unused.
  - No imports found anywhere.
  - No observed CRDT integration in desktop, mobile, or Rust code.
- `@electric-sql/pglite-sync` is installed but entirely unused.
  - No imports found anywhere.
  - No observed PGlite sync transport usage.
- No WebRTC or peer-to-peer sync code found in desktop, mobile, or Rust surfaces.
- Vector and embedding references appear only in the memory feature.
  - Current implementation is SurrealDB-backed via Rust.
  - No confirmed client-side vector database implementation for AI chat/RAG.
- PEM + PGlite entity wiring exists in the `knowme-poc` area.
- Existing transports ignore list queries; this matches the noted pre-`C-104` limitation in code.

## Current assessment state

The session had completed spot checks and was waiting for:

- Three document/inventory reader agents to return digests.
- `cargo check` results.

Next planned steps:

1. Synthesize `assessment.md` from reader digests and cargo-check output.
2. Update `progress.json`.
3. Hand off to `/kbd-analyze`.

## Engineering interpretation

Do not treat local-first realtime sync, CRDT convergence, WebRTC device-to-device sync, PGlite sync, or client-side vector RAG as implemented from the current repository state. The assessment found key dependencies present but unused, and the phase remains in assessment rather than implementation.

# Citations

1. stdin