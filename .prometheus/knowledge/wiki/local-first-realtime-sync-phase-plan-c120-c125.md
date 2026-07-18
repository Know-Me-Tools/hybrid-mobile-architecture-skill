---
type: Reference
id: local-first-realtime-sync-phase-plan-c120-c125
title: Local-first realtime sync phase plan c120-c125
tags:
- local-first
- realtime-sync
- prometheus-entity-management
- pglite
- crdt
- client-rag
- webrtc
- hybrid-mobile-architecture
links:
- local-first-sync-assessment-finds-unused-crdt-and-pglite-sync-deps
sources:
- stdin
- manual:Hybrid Mobile Architecture Skill/local-first-realtime-sync
- .kbd-orchestrator/phases/local-first-realtime-sync/plan.md
- /Users/gqadonis/Projects/hybrid-mobile-architecture-src/.claude/worktrees/local-first-realtime-sync-965f0c
timestamp: 2026-07-18T11:15:24.475052+00:00
created_at: 2026-07-18T11:15:24.475052+00:00
updated_at: 2026-07-18T11:15:24.475052+00:00
revision: 0
---

## Context

- **Project:** Hybrid Mobile Architecture Skill
- **Phase:** `local-first-realtime-sync`
- **KBD root:** `/Users/gqadonis/Projects/hybrid-mobile-architecture-src/.claude/worktrees/local-first-realtime-sync-965f0c`
- **Captured:** `2026-07-18T09:37:48Z`
- **Status:** `execute_ready`
- **Changes completed:** `0/6`
- **Plan commit:** `50a75f2`
- **Plan path:** `.kbd-orchestrator/phases/local-first-realtime-sync/plan.md`

This session completed `kbd-plan` for the local-first realtime sync phase. It follows the earlier assessment that identified unused CRDT and PGlite sync dependencies in [Local-first sync assessment finds unused CRDT and PGlite sync deps](/local-first-sync-assessment-finds-unused-crdt-and-pglite-sync-deps.md).

## Phase goals

The phase is intended to assess `docs/knowme-local-first-realtime-master-plan.md` and all notes under `docs/research/`, then add skills and app behavior for local-first, realtime, and sync strategies in `TJ-ARCH-MOB-001` apps.

Required behavior:

- **Partial replication, not full mirroring:** local stores contain only data the user needs, is authorized for, or is interested in, plus application-wide lookup/metatype data that changes over time and must stay current.
- **AI chat local-first:** conversation threads are stored client-side.
- **Client-side vector search/RAG:** apps provide a client-side vector database for vector search, RAG, and agents.
- **Client-side agent data:** agent data is stored and managed locally.
- **Peer-only sensitive profile sync:** user profile and sensitive personal data are stored client-side only and synced device-to-device across the user's devices and browser instances using WebRTC or equivalent peer connections with CRDT convergence.
- **No server persistence for sensitive profile data:** client-side agents may perform momentary inference against safe cloud servers or local LLMs, but sensitive profile data is never persisted server-side.
- **One-time server data loads:** some data loads once before onboarding, then again after onboarding once preferences or personal data are available.
- **Prometheus Entity Management as entity layer:** reference code should use Prometheus Entity Management (PEM) instead of TanStack Query for entity-layer data, working cleanly with PGlite.

## OpenSpec change plan

The plan defines six OpenSpec change proposals, staged in three rounds.

### Round 1: design authority

#### `c120-sync-doctrine-refs`

- **Role:** frontier/design-authority change.
- **Size:** M.
- **Purpose:** create the reference doctrine that all later changes cite.
- **Reference docs to add:**
  - `references/sync/doctrine.md`
  - `references/sync/partial-replication.md`
  - `references/sync/peer-crdt.md`
  - `references/sync/client-rag.md`
- **ADRs to ratify:**
  - Existing FRF/PES lane from the prior `c106` decision where Electric was rejected.
  - PES-canonical PEM adapter.
  - Envelope-default sync format.
  - PEM-only entity approach.
  - Loro as the CRDT foundation.
- **Important gap filled:** `peer-crdt.md` authors the peer-only profile sync design that the master plan did not fully compose.

### Round 2: parallel implementation slices

All Round 2 changes depend only on `c120-sync-doctrine-refs`.

#### `c121-local-first-skills`

Adds the skill package product surface:

- `sync-doctrine`
- `pem-local-first`
- `client-rag`
- `peer-profile-sync`

Expected scope:

- Skill activation hooks.
- Propagation behavior.
- Skill packaging for local-first, sync, client RAG, and peer profile sync guidance.

#### `c122-partial-replication-slice`

Implements the partial-replication reference slice behind the frozen `SyncTransport` seam.

Key design points:

- User-scoped bucket descriptors.
- Development loopback transport.
- Lookup-bundle **currency** for changing metatype/application lookup data.
- Explicit pre-onboarding and post-onboarding load stages.
- Local load ledger to track one-time staged loads.

#### `c123-client-rag-slice`

Implements the client-side RAG reference slice.

Key design points:

- `pgvector` in PGlite for web.
- `pglite-oxide` for desktop.
- 384-dimensional chat-thread embeddings.
- Agent data represented as PEM entities.
- Typed retrieval loop for client-side search/RAG.

#### `c124-peer-profile-vault`

Implements the sensitive profile vault slice.

Key design points:

- Loro vault for CRDT convergence.
- Vault is structurally excluded from all server sync.
- Fail-closed behavior: privacy-class data must not enter server sync queues.
- Device-to-device sync over WebRTC DataChannels.
- Browser instances are included as peer devices.
- Resolves the previously installed but unused `loro-crdt` dependency by assigning it to the peer profile vault design.

### Round 3: scaffold propagation and audits

#### `c125-scaffold-audit-propagation`

Folds the proven slice patterns into scaffold generation and audit gates.

Expected scope:

- Propagate sync, RAG, partial-replication, and peer-vault patterns into scaffold scripts.
- Add privacy audit gates:
  - Privacy-class entities must never appear in the sync queue.
  - Dead sync dependencies must be detected.
  - Vector capability/presence must be validated.
- Pin the `[sync]` block in `versions.toml`.

## Explicit cuts and deferrals

The plan intentionally excludes several upstream or out-of-scope areas:

- **PSyncV2 gateway:** upstream repository work, estimated at ~10+ engineer-weeks.
- **FRF SyncService auth:** upstream repository work, estimated at ~10+ engineer-weeks.
- **Spine-to-Postgres writer:** upstream repository work, estimated at ~10+ engineer-weeks.
- **Full mobile sync client:** deferred because the Dart-client decision is blocked upstream; mobile receives doctrine and stubs only.
- **WASM/FCP/settings planes:** out of scope for the seven stated goals.

Rationale: reference slices run behind frozen seams so the PES client can drop in later without rework.

## Quality notes

- Sycophancy audit scored `0.0` on both the plan and explicit cuts.
- Current waypoint: dispatch `c120-sync-doctrine-refs` first, then run `c121`-`c124` in parallel, then complete `c125-scaffold-audit-propagation`.

# Citations

1. stdin
2. manual:Hybrid Mobile Architecture Skill/local-first-realtime-sync
3. .kbd-orchestrator/phases/local-first-realtime-sync/plan.md
4. /Users/gqadonis/Projects/hybrid-mobile-architecture-src/.claude/worktrees/local-first-realtime-sync-965f0c