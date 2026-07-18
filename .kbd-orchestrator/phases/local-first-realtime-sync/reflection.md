# REFLECTION: local-first-realtime-sync

Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-07-18
Changes delivered: 6/6 implemented, verified (openspec), archived
Commits: b68be47 (c120) · a18b890 (c121) · 141d959 (c122) · ce0076c (c123) · c3097eb (c124) · dfe1a87 (c125)

## Goal achievement

1. **Assess plan + research → determine and add skills**: **MET** — assessment digested the 1,586-line master plan plus ten briefs; four skills shipped (`sync-doctrine`, `pem-local-first`, `client-rag`, `peer-profile-sync`) with activation hooks, propagation, and harness mirrors, grounded in five new `references/sync/` docs.
2. **Partial replication + lookup currency**: **MET (slice)** — `SyncScope`/`ScopeKind` with fail-closed tenant validation on the frozen seam; scope-aware loopback transport; lookup ledger with real ETag/304 revalidation and version-bump refetch decisions; all propagated into `scaffold-rust-core.sh` byte-identically. Production gateway (PES on FRF) remains upstream work by design.
3. **Chat local-first + client vector DB + client RAG**: **MET (desktop/web), PARTIAL (mobile)** — `RagEngine` with the fixed retrieval pipeline and tested ordering/dedup/budget contract; pgvector via pglite-oxide (Rust) and in web PGlite (`@electric-sql/pglite-pgvector`, empirically verified incl. HNSW — it is NOT bundled in core wasm as the master plan implied); embed-on-write backfill; agent_memory tables. Mobile has doctrine + bridge stubs only.
4. **Client-side agent data**: **MET (slice)** — agent_memory vector tables + vault `agent_facts` map written by agents through `VaultRepository`.
5. **Peer-only CRDT profile sync**: **MET (slice)** — the design the master plan lacked now exists (`references/sync/peer-crdt.md`) and runs: Loro vault persisted in `_vault_state`, structural enqueue refusal of local-class/undeclared tables (tested), version-vector + delta protocol over chunked frames, WebRTC DataChannel lane with dev signaling, two-peer convergence proven in tests. Native webrtc-rs mobile lane deferred (OD-2c).
6. **One-time onboarding loads**: **MET (slice)** — `pre/post_onboarding_load` typestate stages, `_load_ledger` idempotence, degrade-on-failure; tested.
7. **PEM replacing TanStack Query with PGlite**: **MET (standing) / PARTIAL (bridge)** — ADR-LFS-4 ratifies PEM-only with the layering argument; audit enforces it; PGlite adapter wired. The `prometheusSyncTransport` bridge + ListQuery support + queue unification remain the next PEM-side work.

## Artifact Quality Summary

| Metric | Value |
| --- | --- |
| Changes with QA | 6/6 (2 skipped per docs-only rule; 4 via compensating verification) |
| artifact-refiner runs | 0 — `/refine-validate` unavailable in this harness |
| Compensating verification pass rate | 4/4 (clippy -D warnings, 30 Rust + 13 desktop tests, wasm32 gate, byte-identical heredoc replays, audit gates green) |
| Refinement iterations | 0 |

No `.refiner/artifacts/<change-id>/` logs exist for this phase; QA evidence lives in `progress.json → qa` per change. Recurring-violation analysis: none available (no refiner); zero clippy/tsc regressions introduced.

## Technical debt introduced

- The Electric lane (`SyncEngine`, `shapes.rs`, `pglite-sync` docs references) is still in-tree as legacy; its removal was NOT scheduled this phase.
- Web-tier `message_embeddings` diverges from the Rust `messages` embedding columns until the C-104+ entity-view normalization lands (documented in schema comment).
- `RagEngine` is not yet exposed over FFI/Tauri commands to the UIs; retrieval is core-side only.
- Vault pairing lacks the Ed25519 roster/challenge (design exists in peer-crdt.md; slice ships DTLS + manual pairing only).
- Duplicate `impl<S> Startup<S, Migrated>` blocks in startup.rs (legal, slightly untidy).

## Lessons captured

- **pgvector is NOT bundled in PGlite 0.5.4 core wasm** — needs `@electric-sql/pglite-pgvector` (0.0.5) at `PGlite.create`; verified empirically after the master plan implied bundling. Recorded in code comments + versions.toml.
- openspec CLI rejects change names starting with a digit — date-prefixed change IDs must put the date in the *archive* name only.
- jsdom breaks PGlite's tar loader (`Response.arrayBuffer`); pin PGlite-touching vitest files to `@vitest-environment node`.
- Heredoc propagation to scaffolds is reliable when done programmatically with byte-diff replay verification (two agents, zero drift).
- The fail-closed privacy default (undeclared table ⇒ local ⇒ refused) surfaced every undeclared-table call site at compile/test time — the type-system-as-harness philosophy paying off.

## Recommended Next Phase

**pem-sync-bridge-and-mobile-tier**: (a) PEM-side `prometheusSyncTransport` bridging the scope streams into entity reactivity, ListQuery support in transports, and one-queue unification; (b) the mobile tier for real — SQLite `LocalStore`, sqlite-vec vector store behind the same `VectorStore` seam, frb surface for `attachSyncScopes`/`runOneTimeLoads`; (c) expose `RagEngine` via FFI/Tauri commands and wire the chat UI retrieval; (d) vault roster/challenge pairing hardening. Upstream coordination items (PES gateway, FRF SyncService auth, SignalService swap) stay tracked in `progress.json → deferred`.

## Sycophancy check

Self-check S-02/S-03/S-06 applied: every "MET" above is scoped ("slice") where production pieces remain upstream; five debt items and three deferred upstream dependencies are named; no unqualified success claims.
