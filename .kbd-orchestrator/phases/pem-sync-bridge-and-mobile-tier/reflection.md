# REFLECTION: pem-sync-bridge-and-mobile-tier

Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-07-18
Changes delivered: 5/5 implemented, verified (openspec), archived
Commits: fee09e5 (c126) · 3abe8a2 (c127) · c578783 (c128) · bb30d69 (c129) · b0a9cba (c130)

## Goal achievement

1. **PEM sync bridge (transport + ListQuery + one queue)**: **MET** — `syncBridge.ts` wires PGlite's `live` extension to PEM's `invalidateType`, so any local table change (UI mutation or future scope-stream write) invalidates the graph without feature code being sync-aware. `pgliteTransport` compiles the REAL PEM `ListQuery` via PEM's own exported `toSQLClauses` (retiring the pre-C-104 fetch-everything behavior), always AND-ing the tenant predicate. Mutations now route through PEM's `createGraphAction` (optimistic + durable run + replay), eliminating the manual dual-write pattern the assessment flagged as "two queues."
2. **Mobile tier (SQLite LocalStore + sqlite-vec + frb wiring)**: **MET, with a corrected design** — investigation found the plan's premise wrong on both halves: mobile's config/memory store is SurrealDB (not SQLite — `SqliteEntityStore` is a separate, entity-envelope-only concern), and mobile already had a production 384-dim HNSW+BM25 vector store (`GraphStore::memory_search`/`memory_ingest`) equivalent to what c123 built pgvector for on desktop. Building SqliteLocalStore/sqlite-vec would have shipped two unused, wrong stores. Delivered instead: `SurrealLocalStore` (c127, the `LocalStore` seam over the existing SurrealDB connection) and `GraphVectorStore`/`GraphRagEmbedder` (c128, adapters over the existing memory table) — both resolving gaps the codebase's own authors had explicitly tracked (C-106 T5) rather than smuggling in a wrong abstraction. `attach_sync_scopes`/`run_one_time_loads` land on both FFI (mobile) and Tauri (desktop) surfaces.
3. **RagEngine exposure + chat retrieval wiring**: **MET (IPC + store), PARTIAL (composer UI)** — `rag_retrieve` ships on both desktop (Tauri, over `PgVectorStore`+`FastEmbedder`) and mobile (frb, over `GraphVectorStore`+`GraphRagEmbedder`), sharing one request/response shape. `chatStore.retrieveContext()` is the sole invoke() point; `useRecall` composes it with an empty-query short-circuit. The actual chip-rendering UI inside Assistant UI's generated `Composer` component was deliberately deferred — editing that generated boilerplate was judged riskier than the IPC work justified within this change's scope.
4. **Vault pairing hardening (roster/challenge/revocation)**: **MET** — Ed25519 device keypairs (WebCrypto primary, `@noble/ed25519` fallback for the app's stated macOS 10.15 minimum), a signed roster stored IN the vault doc (so pairing/revocation converge via the vault's own CRDT), and a mutual challenge-response handshake gating all hello/delta processing. A real async-ordering bug (a `hello` arriving mid-handshake being dropped as "not yet authenticated") was caught by the new tests and fixed by serializing frame processing.
5. **Carry-forward upstream items**: **MET as tracking** — PES gateway, FRF SyncService auth, production SignalService swap remain correctly out of scope, unchanged from the prior phase's deferred list.

## Artifact Quality Summary

| Metric | Value |
| --- | --- |
| Changes with QA | 5/5 (all via compensating verification — no refiner logs this phase either) |
| artifact-refiner runs | 0 — unavailable in this harness (consistent across both phases) |
| Compensating verification pass rate | 5/5 (cargo check/clippy clean on every touched crate; 22 desktop tests green, up from 18 at phase start; 9 gen_ui_db_graph integration tests green, stable across repeated runs) |
| Real defects caught by tests before merge | 2 — a missing disposed-guard in the PGlite live callback (c126), and a frame-processing race in the vault handshake (c130) |

No `.refiner/artifacts/<change-id>/` logs exist for this phase either; QA evidence lives in `progress.json → qa` per change, same pattern as the prior phase.

## Technical debt introduced

- Chip-rendering UI for recall context is not wired into the actual composer — `useRecall`/`retrieveContext` are shipped and tested but unused by any screen yet.
- `RetrievalScope::ThisConversation` filtering is not implemented on mobile's `GraphVectorStore` — every scope reads the same `memory` table (documented in the adapter's own comment; mobile has no per-conversation memory partition yet).
- `gen_ui_ffi` itself remains environment-blocked on `flutter_rust_bridge_codegen` timing out in this cold worktree (pre-existing, not newly introduced) — the new `attach_sync_scopes`/`run_one_time_loads`/`rag_retrieve` FFI functions were verified via a temporary, never-committed stub rather than a real codegen run.
- Vault roster has no UI for the user to see/manage paired devices or trigger revocation — the mechanism exists, the surface doesn't.
- `SurrealVectorStore`'s embedding backfill (analogous to desktop's `backfill_embeddings`) doesn't exist for mobile — `memory_ingest` embeds synchronously today, so this is lower urgency than it would otherwise be.

## Lessons captured

- **Two design corrections this phase, both from the same root cause**: trusting the plan's technology choice (SqliteLocalStore, sqlite-vec) without first checking what the codebase's own boot-order comments already say about mobile's actual architecture. Both times, the correct answer was already documented in-repo (`gen_ui_ffi::api::boot`'s C-106 T5 comment; `gen_ui_db_graph`'s SCHEMA_DDL). **Read the target module's existing doc comments before implementing a plan item that touches it — the plan is a hypothesis, not a spec.**
- **`GraphStore`/`gen_ui_runtime` are process-global singletons in this crate** — a plain `#[tokio::test]` breaks both (confirmed twice: once via `spawn_blocking`'s "runtime not initialised" panic, once via the crate's own documented dead-router flake). Tests touching `gen_ui_db_graph`'s memory/graph API MUST use the crate's `tests/it/main.rs` `run_test()` harness, never an in-file `#[cfg(test)]` with `#[tokio::test]`.
- **Async handler ordering is not delivery ordering** — converting a synchronous `onFrame` callback to `async` (to await a signature) silently reintroduces a race: a later-delivered frame can finish its (trivial) synchronous prefix before an earlier frame's await resolves. Any per-connection protocol state machine with async steps needs an explicit processing-order guarantee (a promise chain, here), not just "the callback is async now."
- **pnpm `file:` deps can silently go stale**: editing `guest-js/src/index.ts` didn't reach the desktop app's resolved import until `pnpm install` re-ran, even though the package's `main`/`types`/`exports` point straight at `src/` for local dev. A `.pnpm` store copy from an earlier install can shadow live source edits — when a `file:`-linked package's exports don't seem to update, check the resolved `.pnpm` store path's actual content before assuming the code change is wrong.
- **WebCrypto's `BufferSource` typing rejects `Uint8Array<ArrayBufferLike>`** in this TS/lib setup (same issue hit twice: `webrtcDuplex.ts` in c124, `deviceAuth.ts` here) — any `Uint8Array` handed to `crypto.subtle.*` needs a defensive copy into a plain `ArrayBuffer`-backed view first.

## Recommended Next Phase

**vault-ui-and-conversation-scoped-rag**: (a) wire `useRecall`'s chips into the actual chat composer (the deferred UI work from c129); (b) a minimal device-management screen for the roster (list paired devices, trigger revocation) — the mechanism from c130 has no user-facing surface; (c) conversation-scoped memory partitioning on mobile so `RetrievalScope::ThisConversation` actually filters (currently a no-op scope); (d) mobile embedding backfill parity with desktop's `backfill_embeddings`. Continue tracking PES gateway / FRF auth / SignalService swap as upstream carry-forward, unchanged.

## Sycophancy check

Self-check S-02/S-03/S-06 applied: goal 2 and 3 are explicitly qualified ("with a corrected design", "PARTIAL — composer UI") rather than blanket MET; five debt items and one deferred UI surface are named; the two design corrections are described with their root cause (not implemented plan blindly) rather than glossed over; two real bugs caught by testing are reported as findings, not hidden.
