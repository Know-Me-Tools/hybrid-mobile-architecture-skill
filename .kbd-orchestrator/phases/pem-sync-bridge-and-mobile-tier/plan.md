# PLAN: pem-sync-bridge-and-mobile-tier

Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-07-18
OpenSpec available: YES
Changes to implement: 5

Planning inputs: this phase's assessment.md, previous phase's reflection + `references/sync/` doctrine, ADR-LFS-1…5.

**Ruling on the assessment's key decision**: the PEM scope bridge is built **app-side** (a `syncBridge` module in the app/scaffold, using PEM's existing public surface — `registerEntityTransport`, `startLocalFirstGraph`, `ListQuery`, plus PGlite's `live` extension for table reactivity, confirmed exported by pglite 0.5.4). Changing the external `@prometheus-ags` package is out of this repo's control; an upstream PEM PR (`prometheusSyncTransport` proper) is recorded as deferred. ADR-LFS-2 stays intact: the canonical path (local-store-fed transports) is exactly what the app-side bridge implements.

---

## CHANGE LIST (ordered)

1. **c126-pem-scope-bridge**: Desktop/web sync bridge — scope streams into PEM reactivity, ListQuery honored, one queue.
   - Scope: desktop entityRuntime + new shared syncBridge module + tests
   - Depends on: NONE
   - Recommended agent: Claude Code · Est: L · Complexity: High · Model class: frontier · Value: HIGH
   - Details: (a) PGlite `live`-extension change feeds per synced table → PEM graph invalidation (scope rows land in tables → UI updates with zero feature-code sync awareness); (b) `pgliteTransport` honors the full PEM `ListQuery` (filters/sorts/limit/cursor compiled to parameterized SQL — retires the pre-C-104 fetch-everything comment); (c) queue unification: mutations flow local-write + `_operation_queue` enqueue via one store API; PEM pending-action state derived from queue rows (`replayPendingActions` no longer a parallel truth). Boundary tests against a real PGlite.

2. **c127-mobile-local-store-and-frb**: Mobile read/write lane — SQLite LocalStore + the frb sync surface.
   - Scope: rust (gen_ui_db sqlite feature), gen_ui_ffi api, tauri-plugin parity commands, mobile Dart bridge
   - Depends on: NONE
   - Recommended agent: Claude Code · Est: L · Complexity: High · Model class: frontier · Value: HIGH
   - Details: `SqliteLocalStore` implementing the frozen `LocalStore` seam over sqlx-sqlite (table allow-list, one txn per `apply_batch`, truncate for re-materialization); `attach_sync_scopes` + `run_one_time_loads` exposed in `gen_ui_ffi::api` (frb) and as Tauri commands (replacing legacy `attach_sync_shapes` at parity); knowme-poc mobile boot path attaches scoped loopback sync behind the same seam. Un-stubs the c125 Dart signatures via codegen.

3. **c128-sqlite-vec-vector-store**: Mobile vector tier — sqlite-vec behind the same VectorStore seam.
   - Scope: rust (gen_ui_db rag, sqlite feature), versions pin already present
   - Depends on: c127 (shares the sqlite store/feature wiring)
   - Recommended agent: Claude Code · Est: M · Complexity: Medium · Model class: medium · Value: HIGH
   - Details: `SqliteVecStore` implementing `VectorStore` (384-dim discipline, same scope→table mapping, Vault refusal) + `backfill_embeddings` sqlite variant; sqlite-vec loadable extension via the `sqlite-vec` crate; boundary tests on in-memory SQLite (ingest→retrieve round-trip, ordering parity with PgVectorStore).

4. **c129-rag-ipc-and-chat-wiring**: Expose RagEngine to the UIs and wire chat retrieval.
   - Scope: tauri-plugin command + gen_ui_ffi fn + desktop chat feature (store→hook→component)
   - Depends on: NONE (engine landed in c123)
   - Recommended agent: Claude Code · Est: M · Complexity: Medium · Model class: medium · Value: HIGH (first user-visible RAG)
   - Details: `rag_retrieve(query, scope, k, token_budget)` Tauri command + frb fn with serde-typed `RetrievedChunk` results; desktop chat store gains `retrieveContext()` (the ONLY invoke() point), hook composes it, composer surfaces recalled chunks with provenance before send. Layer contract enforced by existing audit checks.

5. **c130-vault-roster-auth**: Pairing hardening — Ed25519 roster, pre-delta challenge, revocation.
   - Scope: desktop/web vault feature (+ @noble/ed25519 or WebCrypto), peer protocol v2 frame
   - Depends on: NONE (protocol landed in c124)
   - Recommended agent: Claude Code · Est: L · Complexity: High · Model class: frontier · Value: HIGH (privacy requirement)
   - Details: device keypair generated at first vault open (private key never in the doc); signed roster map in the doc (pairing adds an entry; revocation removes and propagates via CRDT); handshake: challenge nonce → signature verified against roster before any HELLO/DELTA processing (protocol version bump, unauthenticated frames dropped); tests: rostered peer converges, unrostered peer rejected, revoked peer cut off. Web signs via WebCrypto Ed25519 with @noble/ed25519 fallback (Safari < 17).

## EXECUTION ROUND ORDER

- Round 1 (parallel): c126, c127
- Round 2 (parallel): c128 (after c127), c129
- Round 3: c130

## COMMANDS TO RUN

/opsx:new c126-pem-scope-bridge
/opsx:new c127-mobile-local-store-and-frb
/opsx:new c128-sqlite-vec-vector-store
/opsx:new c129-rag-ipc-and-chat-wiring
/opsx:new c130-vault-roster-auth

## TRADE-OFFS AND EXPLICIT CUTS

- **Upstream PEM `prometheusSyncTransport` is deferred** — the app-side bridge ships the ADR-LFS-2 semantics now; a PEM-repo PR generalizing it is recorded for later. Consequence: scaffolds carry the bridge module until PEM absorbs it.
- **Mobile UI feature wiring is minimal** — c127 proves the lane at the bridge/provider boundary; full Flutter screens consuming synced entities are a later phase.
- **frb codegen dependency**: c127/c129 FFI surfaces require `flutter_rust_bridge_codegen` runs; CI note from memory applies (codegen before clippy). If codegen is unavailable in-session, the Rust/tauri side lands complete and the generated Dart is refreshed by the standing scaffold instruction — recorded per task, not silently skipped.
- **Chat retrieval UI is deliberately small** (recall chips in the composer, not a full retrieval panel) — Rule 2/40.
- **Risk**: PGlite `live` extension behavior under the Tauri webview is assumed equal to browser; if it diverges, the desktop falls back to plugin-event-driven invalidation at the same bridge seam (isolated blast radius).

PLAN COMPLETE
