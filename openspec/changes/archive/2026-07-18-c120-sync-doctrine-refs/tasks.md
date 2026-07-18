# Tasks — c120-sync-doctrine-refs

Expanded at execute time from plan.md (Round 1, doctrine authority for the phase).

## 1. Reference docs

- [x] 1.1 Write references/sync/doctrine.md — invariants INV-1..7, four-phase boot, write-queue state machine, fail-closed rules, thin-client fallback, secrets-never-sync
- [x] 1.2 Write references/sync/partial-replication.md — user-scoped buckets on SyncTransport, lookup/metatype currency (ETag/304 + change notification), pre-/post-onboarding one-time load semantics
- [x] 1.3 Write references/sync/peer-crdt.md — goal-5 design: Loro profile vault, privacy-class structural exclusion, WebRTC DataChannel device-to-device incl. browsers, Loro-not-Yjs wire, Rust-owned networking boundary
- [x] 1.4 Write references/sync/client-rag.md — per-tier vector matrix (pgvector-in-PGlite web / pglite-oxide desktop / sqlite-vec mobile, 384-dim), chat-thread RAG retrieval loop

## 2. Decisions + index

- [x] 2.1 Write references/sync/decisions.md — ADR-LFS-1..5 ratifying OD-2 (FRF/PES lane per c106 pivot), OD-3 (PES-canonical PEM adapter), OD-4 (envelope default, columnar opt-in), OD-7 (PEM-only), Loro adoption
- [x] 2.2 Update CLAUDE.md reference index with references/sync/*; run openspec validate for the change
