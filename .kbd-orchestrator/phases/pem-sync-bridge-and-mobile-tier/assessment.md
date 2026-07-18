ASSESSMENT: pem-sync-bridge-and-mobile-tier
Project: Hybrid Mobile Architecture Skill (TJ-ARCH-MOB-001 / KnowMe builder)
Date: 2026-07-18
Codebase baseline: end of local-first-realtime-sync phase (commit 6386836) — doctrine refs, four skills, scope/lookup/loads slice, RagEngine + pgvector, Loro vault + WebRTC lane, scaffold/audit propagation all landed.
Cross-tool progress: NONE — phase seeded this session; no other tools have written progress.json.

IMPLEMENTATION STATUS

- **PEM sync bridge**: [PARTIAL foundations / bridge MISSING] — PEM 3.x (inspected dist types) ships `ListQuery`, `useLocalFirst`, `usePGliteQuery`, `registerEntityTransport`, `createPGlitePersistenceAdapter`, `startLocalFirstGraph`, plus legacy adapters (`ElectricSQLAdapter`, `SupabaseRealtimeAdapter`). There is **no scope-stream adapter** (no `prometheusSyncTransport`, no PES/FRF-aware path — ADR-LFS-2's canonical lane is unimplemented in the package). App-side, `entityRuntime.ts` transports **ignore the PEM ListQuery** (explicit pre-C-104 comment: fetch-everything). Queue duality is real: PEM `replayPendingActions: true` maintains JS-side pending actions while Rust owns `_operation_queue` — the "one queue, not two" doctrine rule is not yet enforced by code. NOTE: the PEM package is an external dependency (`@prometheus-ags`); bridge work is either PEM-repo work or an app-side adapter module — the split is a plan decision.
- **Mobile SQLite LocalStore**: [MISSING] — `sync/local_store.rs` is `pg`-feature-gated (PgPool); `sync/mod.rs` documents "Mobile's read lane is NOT wired". Foundation exists: `SqliteEntityStore` (relational entity envelopes) and the frozen `LocalStore` seam (`apply_batch`/`truncate_shape`) to implement against.
- **sqlite-vec VectorStore**: [MISSING] — only `PgVectorStore` exists; the `VectorStore` trait (c123) is the seam. No sqlite-vec crate dependency yet; versions.toml pins 0.1.
- **frb sync surface**: [STUB] — generated bridge exists (`frb_generated.dart`), but `attach_sync_scopes` / `run_one_time_loads` exist neither in `gen_ui_ffi::api` nor as Tauri commands (Tauri has legacy `attach_sync_shapes`, `run_migrations`, `load_seeds`, entity_*, memory_*). Scaffold-side Dart stubs (c125) throw UnimplementedError by design.
- **RagEngine exposure**: [MISSING] — `RagEngine`/`PgVectorStore`/`backfill_embeddings` are core-side only (c123); no `rag_retrieve` Tauri command, no FFI fn, no chat-feature wiring. (`memory_search`/`graph_expand` exist but serve the SurrealDB memory lane — distinct from chat RAG.)
- **Vault pairing hardening**: [PARTIAL] — vault, peer protocol, chunked frames, WebRTC + dev signaler, and the structural privacy gate all landed (c124) with tests. Missing: Ed25519 device roster in the doc, pre-delta challenge over the DataChannel, revocation propagation. `ed25519-dalek` is already in Cargo.lock (transitive — usable native-side); web has no ed25519 dependency yet (needs e.g. @noble/ed25519 or WebCrypto Ed25519, Safari≥17).
- **Carry-forward upstream items** (PES gateway, FRF SyncService auth, SignalService swap): [OUT OF SCOPE by goals] — tracked in previous phase's progress.json → deferred.

SPEC GAP SUMMARY

- openspec/specs now contains sync-doctrine, partial-replication, client-rag, peer-profile-vault, local-first-skills, local-first-scaffolding (archived deltas from c120–c125). None of them yet specify: the PEM bridge contract, ListQuery honoring, queue unification, the mobile store/vector implementations, RAG-over-IPC, or roster-based pairing — these are exactly this phase's surface; new deltas required per change.
- ADR-LFS-2 (PEM canonical adapter) is ratified but unimplemented — this phase closes that gap or must amend the ADR.

BUILD HEALTH

- build check: PASS — `cargo check --workspace --exclude gen_ui_ffi` clean; wasm32 gate clean; desktop `tsc --noEmit` clean (all verified this session at phase end).
- tests: PASS — 30 gen_ui_db (+2 it) Rust tests; 13 desktop vitest. gen_ui_ffi still requires frb codegen before full-workspace clippy (standing environmental note).
- known violations: NONE — audit.sh tauri (with the new c125 gates) runs green against apps/knowme-poc/desktop.
- test coverage: PARTIAL by design (3–5 behavior tests per feature slice per CLAUDE.md philosophy; coverage % is not a goal in this repo).

CONSTRAINT CHECK

- AGENTS.md/AGENT_BASE_RULES violations: NONE known.
- constraints.md: N/A (no .kbd-orchestrator/constraints.md present).
- Layering: RagEngine exposure must respect UI→Hook→Store→invoke() (stores are the only invoke() layer); the vault feature currently complies (store-only module).

GOAL PROGRESS

1. PEM sync bridge (transport + ListQuery + one queue): NOT MET — foundations on both sides, bridge absent; PEM-repo vs app-side split is the key plan decision.
2. Mobile tier (SQLite LocalStore + sqlite-vec + frb wiring): NOT MET — seams ready, zero mobile implementations.
3. RagEngine exposure + chat retrieval wiring: NOT MET — engine done, no IPC surface, no UI consumer.
4. Vault pairing hardening (roster/challenge/revocation): PARTIAL — transport + privacy gate shipped; authentication layer absent.
5. Carry-forward upstream items: MET as tracking (correctly excluded from build scope).

Sycophancy self-check: assessed against dist types and command lists actually read this session, not assumptions; the PEM-repo-vs-app-side split and the ADR-LFS-2 amend-or-implement tension are surfaced rather than smoothed over.

ASSESSMENT COMPLETE
